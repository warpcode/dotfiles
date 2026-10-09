#!/usr/bin/env python3
"""search_tools.py - Search conversation transcripts across sessions for tool and script usage.

Audits tool invocations and bundled script executions across recorded AI conversations:
  - Google Antigravity / Gemini CLI (~/.gemini/antigravity/brain/*/transcript.jsonl)
  - OpenCode (~/.local/share/opencode/opencode.db)
  - VS Code Copilot Chat (~/.config/Code/User/workspaceStorage/*/*.jsonl)

Usage:
  # Search by tool name across last 200 sessions:
  search_tools.py --tool run_command

  # Search for a specific script or pattern:
  search_tools.py --script submit_review.sh --sessions 100

  # Audit all bundled scripts in a skill directory:
  search_tools.py --scripts-dir .github/skills/github-cli/scripts --sessions 200

  # Output structured JSON for consumption by audit tools:
  search_tools.py --scripts "audit_repo_alerts.py,pr_audit_bundle.sh" --json

Options:
  --tool <name>          Filter by tool name (regex or substring match, e.g. run_command, view_file)
  --command <pattern>    Filter by regex / substring match in command line or tool arguments
  --script <name>        Convenience filter matching script name in command line
  --scripts <names>      Comma-separated list of script basenames to audit (every name is tracked, even with 0 calls)
  --scripts-dir <dir>    Directory containing scripts to audit (automatically extracts all script basenames)
  --sessions <N>         Number of most recent sessions to scan (default: 200)
  --all                  Scan all available sessions (ignores --sessions ceiling)
  --workspace <path>     Filter to sessions matching a workspace / repository directory
  --platform <name>      Filter to a specific platform (antigravity, opencode, copilot)
  --json                 Output results as structured JSON
  --details              Include per-session match details in Markdown output
  -h, --help             Show this help message and exit
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sqlite3
import sys
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple

# Search roots across platforms
ANTIGRAVITY_BRAIN_PATHS = [
    Path.home() / ".gemini/antigravity/brain",
    Path.home() / ".gemini/antigravity-cli/brain",
]
OPENCODE_DB_PATH = Path.home() / ".local/share/opencode/opencode.db"
VSCODE_STORAGE_PATHS = [
    Path.home() / ".config/Code/User/workspaceStorage",
    Path.home() / ".config/Code - Insiders/User/workspaceStorage",
    Path.home() / "Library/Application Support/Code/User/workspaceStorage",
]


class SessionRef:
    def __init__(self, session_id: str, platform: str, location: Path | str, mtime: float, workspace: str = ""):
        self.session_id = session_id
        self.platform = platform
        self.location = location
        self.mtime = mtime
        self.workspace = workspace


def discover_sessions(
    limit: Optional[int] = 200,
    workspace_filter: Optional[str] = None,
    platform_filter: Optional[str] = None,
) -> List[SessionRef]:
    """Discover candidate conversation sessions across supported platforms sorted newest to oldest."""
    candidates: List[SessionRef] = []

    # 1. Antigravity Brain transcripts
    if not platform_filter or platform_filter == "antigravity":
        for brain_path in ANTIGRAVITY_BRAIN_PATHS:
            if not brain_path.exists():
                continue
            for log_file in brain_path.glob("*/.system_generated/logs/transcript.jsonl"):
                if not log_file.is_file():
                    continue
                try:
                    st = log_file.stat()
                    # Parent of .system_generated is the session UUID directory
                    sid = log_file.parent.parent.parent.name
                    candidates.append(SessionRef(sid, "antigravity", log_file, st.st_mtime))
                except OSError:
                    continue

    # 2. OpenCode SQLite sessions
    if (not platform_filter or platform_filter == "opencode") and OPENCODE_DB_PATH.exists():
        try:
            conn = sqlite3.connect(f"file:{OPENCODE_DB_PATH}?mode=ro", uri=True)
            cur = conn.cursor()
            rows = cur.execute(
                "SELECT id, directory, time_updated FROM session ORDER BY time_updated DESC"
            ).fetchall()
            for sid, sdir, tupdated in rows:
                if not sid:
                    continue
                mtime = (tupdated / 1000.0) if tupdated and tupdated > 1e11 else float(tupdated or 0)
                candidates.append(SessionRef(sid, "opencode", str(OPENCODE_DB_PATH), mtime, workspace=sdir or ""))
        except Exception:
            pass

    # 3. VS Code Copilot Chat storage
    if not platform_filter or platform_filter == "copilot":
        for base in VSCODE_STORAGE_PATHS:
            if not base.exists():
                continue
            for jsonl in base.rglob("*.jsonl"):
                if not jsonl.is_file():
                    continue
                try:
                    st = jsonl.stat()
                    sid = jsonl.stem
                    candidates.append(SessionRef(sid, "copilot", jsonl, st.st_mtime))
                except OSError:
                    continue

    # Filter by workspace if requested
    if workspace_filter:
        clean_ws = workspace_filter.strip().lower()
        filtered = []
        for s in candidates:
            if s.workspace and clean_ws in s.workspace.lower():
                filtered.append(s)
            elif clean_ws in str(s.location).lower():
                filtered.append(s)
        candidates = filtered

    # Sort newest first
    candidates.sort(key=lambda s: s.mtime, reverse=True)
    if limit is not None and limit > 0:
        candidates = candidates[:limit]

    return candidates


def extract_tool_calls_from_jsonl(file_path: Path) -> List[Dict[str, Any]]:
    """Fast-extract tool calls and timestamps from an Antigravity or JSONL transcript."""
    tool_calls = []
    try:
        with open(file_path, "r", encoding="utf-8", errors="replace") as f:
            for line in f:
                if "tool_calls" not in line and "ToolName" not in line:
                    continue
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                except json.JSONDecodeError:
                    continue

                ts = obj.get("created_at") or ""
                status = obj.get("status") or "DONE"
                tcs = obj.get("tool_calls") or []
                if isinstance(tcs, list):
                    for tc in tcs:
                        if not isinstance(tc, dict):
                            continue
                        name = tc.get("name") or tc.get("ToolName") or tc.get("toolAction") or ""
                        args = tc.get("args") or tc.get("Arguments") or {}
                        # Resolve call_mcp_tool inner tool name
                        if name == "call_mcp_tool" and isinstance(args, dict):
                            inner_name = args.get("ToolName")
                            if inner_name:
                                name = f"mcp:{inner_name}"
                        tool_calls.append({
                            "name": name,
                            "args": args,
                            "timestamp": ts,
                            "status": status,
                        })
    except Exception:
        pass
    return tool_calls


def extract_tool_calls_from_opencode(db_path: str, session_id: str) -> List[Dict[str, Any]]:
    """Extract tool calls from an OpenCode session SQLite entry."""
    tool_calls = []
    try:
        conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
        cur = conn.cursor()
        rows = cur.execute(
            "SELECT time_created, role, content FROM message WHERE session_id = ? ORDER BY time_created ASC",
            (session_id,)
        ).fetchall()
        for tcreated, role, content in rows:
            if not content:
                continue
            ts = ""
            if tcreated:
                sec = (tcreated / 1000.0) if tcreated > 1e11 else float(tcreated)
                ts = datetime.utcfromtimestamp(sec).isoformat() + "Z"
            try:
                data = json.loads(content)
                parts = data if isinstance(data, list) else data.get("parts", [])
                for p in parts:
                    if isinstance(p, dict) and p.get("type") in ("tool_use", "tool_call"):
                        tool_calls.append({
                            "name": p.get("name", ""),
                            "args": p.get("input") or p.get("arguments") or {},
                            "timestamp": ts,
                            "status": "DONE",
                        })
            except Exception:
                pass
    except Exception:
        pass
    return tool_calls


def match_tool_call(
    tc: Dict[str, Any],
    tool_re: Optional[re.Pattern] = None,
    command_re: Optional[re.Pattern] = None,
    script_targets: Optional[Set[str]] = None,
    script_patterns: Optional[Dict[str, re.Pattern]] = None,
) -> Tuple[bool, Optional[str]]:
    """Check if a tool call matches query filters. Returns (matched, matched_target_key)."""
    name = tc.get("name", "")
    args = tc.get("args") or {}

    # Tool name filter
    if tool_re and not tool_re.search(name):
        return False, None

    # String representation of command line / arguments
    cmd_str = ""
    if isinstance(args, dict):
        cmd_str = (
            args.get("CommandLine")
            or args.get("command")
            or args.get("cmd")
            or args.get("TargetFile")
            or args.get("AbsolutePath")
            or json.dumps(args)
        )
    elif isinstance(args, str):
        cmd_str = args

    # Command pattern filter
    if command_re:
        if not command_re.search(cmd_str):
            return False, None

    # Script targets list filter (prefer pre-compiled script_patterns map for ~20x performance boost)
    if script_patterns is not None:
        matched_script = None
        for s, pattern in script_patterns.items():
            # Fast string containment check before regex search
            if s in cmd_str and pattern.search(cmd_str):
                matched_script = s
                break
        if not matched_script:
            return False, None
        return True, matched_script
    elif script_targets is not None:
        matched_script = None
        for s in script_targets:
            # Fast string containment check before compiling dynamic regex
            if s in cmd_str and re.search(rf"(?:^|[\s/\"']){re.escape(s)}(?:[\s\"']|$)", cmd_str):
                matched_script = s
                break
        if not matched_script:
            return False, None
        return True, matched_script

    target_key = name if not command_re else cmd_str[:60].strip()
    return True, target_key


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Search conversation transcripts across sessions for tool and script usage.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--tool", help="Filter by tool name (regex or substring match)")
    parser.add_argument("--command", "--pattern", dest="command", help="Filter by regex in command line / tool args")
    parser.add_argument("--script", help="Convenience filter matching a single script name")
    parser.add_argument("--scripts", help="Comma-separated list of script basenames to audit")
    parser.add_argument("--scripts-dir", type=Path, help="Directory containing bundled scripts to audit")
    parser.add_argument("--sessions", "--limit", dest="sessions", type=int, default=200,
                        help="Number of most recent sessions to scan (default: 200)")
    parser.add_argument("--all", action="store_true", help="Scan all available sessions (ignores --sessions limit)")
    parser.add_argument("--workspace", help="Filter sessions by workspace / repository path")
    parser.add_argument("--platform", choices=["antigravity", "opencode", "copilot"], help="Filter by platform")
    parser.add_argument("--json", action="store_true", help="Output results in structured JSON")
    parser.add_argument("--details", action="store_true", help="Include per-session details in output")

    args = parser.parse_args()

    # Resolve target script names
    target_scripts: Optional[Set[str]] = None
    if args.script:
        target_scripts = {Path(args.script).name}
    elif args.scripts:
        target_scripts = {s.strip() for s in args.scripts.split(",") if s.strip()}
    elif args.scripts_dir:
        scripts_dir = args.scripts_dir.resolve()
        if not scripts_dir.is_dir():
            print(f"Error: --scripts-dir '{scripts_dir}' is not a directory.", file=sys.stderr)
            return 1
        found_scripts = {
            p.name for p in scripts_dir.iterdir()
            if p.is_file() and not p.name.startswith(".") and not p.name.startswith("test_") and p.suffix in (".py", ".sh", ".zsh", ".bash", ".awk")
        }
        target_scripts = found_scripts

    tool_re = re.compile(args.tool, re.I) if args.tool else None
    command_re = re.compile(args.command, re.I) if args.command else None

    # Pre-compile script target regex patterns once for all sessions
    script_patterns: Optional[Dict[str, re.Pattern]] = None
    if target_scripts:
        script_patterns = {
            s: re.compile(rf"(?:^|[\s/\"']){re.escape(s)}(?:[\s\"']|$)")
            for s in target_scripts
        }

    # Discover sessions
    scan_limit = None if args.all else args.sessions
    sessions = discover_sessions(limit=scan_limit, workspace_filter=args.workspace, platform_filter=args.platform)

    # Initialize stats per target
    # target -> {invocations, sessions: set(), first_seen, last_seen, samples: list(), errors}
    stats: Dict[str, Dict[str, Any]] = defaultdict(lambda: {
        "invocations": 0,
        "sessions": set(),
        "first_seen": None,
        "last_seen": None,
        "samples": [],
        "errors": 0,
    })

    # Pre-seed explicit script targets with 0 counts so unused scripts are surfaced
    if target_scripts:
        for s in target_scripts:
            _ = stats[s]

    matched_sessions: Set[str] = set()
    total_invocations = 0

    for sref in sessions:
        if sref.platform == "antigravity" or sref.platform == "copilot":
            tcs = extract_tool_calls_from_jsonl(Path(sref.location))
        elif sref.platform == "opencode":
            tcs = extract_tool_calls_from_opencode(str(sref.location), sref.session_id)
        else:
            tcs = []

        session_had_match = False
        for tc in tcs:
            matched, target_key = match_tool_call(
                tc,
                tool_re=tool_re,
                command_re=command_re,
                script_targets=target_scripts,
                script_patterns=script_patterns,
            )
            if not matched or not target_key:
                continue

            session_had_match = True
            total_invocations += 1
            st = stats[target_key]
            st["invocations"] += 1
            st["sessions"].add(sref.session_id)
            if tc.get("status") == "ERROR":
                st["errors"] += 1

            ts = tc.get("timestamp")
            if ts:
                if not st["first_seen"] or ts < st["first_seen"]:
                    st["first_seen"] = ts
                if not st["last_seen"] or ts > st["last_seen"]:
                    st["last_seen"] = ts

            # Collect sample command
            cmd = ""
            args_dict = tc.get("args") or {}
            if isinstance(args_dict, dict):
                cmd = args_dict.get("CommandLine") or args_dict.get("command") or args_dict.get("cmd") or ""
            if cmd and cmd not in st["samples"] and len(st["samples"]) < 3:
                st["samples"].append(cmd.strip()[:100])

        if session_had_match:
            matched_sessions.add(sref.session_id)

    # Output formatting
    if args.json:
        results_payload: Dict[str, Any] = {}
        for target, data in stats.items():
            sess_count = len(data["sessions"])
            inv_count = data["invocations"]
            status = "ACTIVE" if inv_count >= 5 else ("LOW_USAGE" if inv_count > 0 else "NEVER_USED")
            results_payload[target] = {
                "invocations": inv_count,
                "sessions": sess_count,
                "status": status,
                "first_seen": data["first_seen"],
                "last_seen": data["last_seen"],
                "errors": data["errors"],
                "samples": data["samples"],
            }

        payload = {
            "scanned_sessions": len(sessions),
            "matched_sessions": len(matched_sessions),
            "total_invocations": total_invocations,
            "results": results_payload,
        }
        print(json.dumps(payload, indent=2))
        return 0

    # Markdown / Terminal output
    query_desc = []
    if args.tool: query_desc.append(f"tool='{args.tool}'")
    if args.command: query_desc.append(f"command='{args.command}'")
    if target_scripts: query_desc.append(f"{len(target_scripts)} script target(s)")
    query_str = " & ".join(query_desc) if query_desc else "all tools"

    print(f"# Tool Usage Audit: {query_str}")
    print(f"- **Scanned Sessions:** {len(sessions)} | **Matched Sessions:** {len(matched_sessions)} | **Total Invocations:** {total_invocations}\n")

    if not stats:
        print("No matching tool calls found across the scanned sessions.")
        return 0

    print("| Target / Script | Invocations | Sessions | Status | Last Seen | Sample Command |")
    print("|---|---:|---:|---|---|---|")

    # Sort: active first, then by invocations desc, then name
    sorted_targets = sorted(
        stats.items(),
        key=lambda item: (item[1]["invocations"] > 0, item[1]["invocations"], len(item[1]["sessions"])),
        reverse=True,
    )

    for target, data in sorted_targets:
        inv = data["invocations"]
        sess_cnt = len(data["sessions"])
        if inv >= 5:
            status = "✅ ACTIVE"
        elif inv > 0:
            status = "⚠️ LOW USAGE"
        else:
            status = "❌ NEVER USED"

        last_seen = (data["last_seen"] or "-")[:19]
        sample = data["samples"][0].replace("|", "\\|") if data["samples"] else "-"
        print(f"| `{target}` | {inv} | {sess_cnt} | {status} | {last_seen} | `{sample[:45]}` |")

    return 0


if __name__ == "__main__":
    sys.exit(main())
