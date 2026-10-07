#!/usr/bin/env python3
"""review_conversation.py - Universal multi-platform conversation audit, schema, and statistics.

Unified, deterministic CLI for AI conversation transcripts across:
  - VS Code Copilot Chat (.jsonl in workspaceStorage)
  - Google Antigravity / Gemini CLI (brain/<uuid>/.../transcript.jsonl)
  - OpenCode (direct SQLite store ~/.local/share/opencode/opencode.db or exported JSONL)
  - Claude Code (.json / .jsonl)
  - Plain Markdown / Text

Modes:
  review_conversation.py <target> [--record]            Full audit & offload dossier (<100 lines)
  review_conversation.py <target> --sizes               Byte size distribution & context hogs
  review_conversation.py <target> --schema              Event types, depth-3 keys, field mapping
  review_conversation.py <target> --segment <SPEC>      Event-by-event slice (final, turn:N, S:E)
  review_conversation.py <target> --user-turns          All user turns timeline with timestamps
  review_conversation.py --latest [--platform P]        Auto-resolve most recent session

Target can be:
  - Absolute or relative file path
  - VS Code Copilot UUID (e.g. 722c61f0-2b2b-4402-95ac-5b1f83cfc17d)
  - Antigravity UUID (e.g. 71ea7488-aae7-476f-9f2d-01456299518a)
  - OpenCode session ID (e.g. ses_ef46f0567ffeCmcrzvG0BYu1C9)

Exit codes: 0 success, 1 input error.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import sqlite3
import sys
import tempfile
from collections import Counter
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

SHELL_TOOLS = {"run_in_terminal", "bash", "Bash", "shell", "execute_command", "bash_tool", "terminal"}
INLINE_PYTHON_PATTERN = re.compile(r"\bpython(?:3)?\s+(?:-c|<<)")
USER_CORRECTION_PATTERN = re.compile(
    r"\b(?:wrong|missed|instead|follow the template|not what|correct(?:ion|ed)?|"
    r"should have|must|wait|please ensure|did you check|not just|not master|not main)\b",
    re.IGNORECASE,
)

OPENCODE_DB_PATH = Path.home() / ".local/share/opencode/opencode.db"
ANTIGRAVITY_BRAIN_PATHS = [
    Path.home() / ".gemini/antigravity/brain",
    Path.home() / ".gemini/antigravity-cli/brain",
]
VSCODE_STORAGE_PATH = Path.home() / "Library/Application Support/Code/User/workspaceStorage"
CLAUDE_PROJECTS_PATH = Path.home() / ".claude/projects"


# ---------------------------------------------------------------------------
# Universal Target Resolution
# ---------------------------------------------------------------------------

class ResolvedTarget:
    def __init__(self, kind: str, location: Path | str, session_id: str, platform: str):
        self.kind = kind          # "file" or "opencode_db"
        self.location = location  # Path or SQLite connection string
        self.session_id = session_id
        self.platform = platform  # "copilot", "antigravity", "opencode", "claude", "generic"


def resolve_target(target: Optional[str], latest: bool = False, platform_filter: Optional[str] = None) -> ResolvedTarget:
    """Resolve a target identifier, file path, or --latest flag across platforms."""
    # 1. Handle --latest
    if latest:
        return resolve_latest(platform_filter)

    if not target:
        print("Error: Provide a transcript path, session ID/UUID, or --latest.", file=sys.stderr)
        sys.exit(1)

    clean = target.strip()

    # 2. Check OpenCode session ID (starts with "ses_")
    if clean.startswith("ses_") and OPENCODE_DB_PATH.exists():
        return ResolvedTarget("opencode_db", str(OPENCODE_DB_PATH), clean, "opencode")

    # 3. Direct file path check
    direct = Path(clean).expanduser().resolve()
    if direct.is_file():
        plat = detect_platform_from_file(direct)
        return ResolvedTarget("file", direct, direct.stem, plat)

    # 4. Check Antigravity UUID across brain search paths
    for brain_path in ANTIGRAVITY_BRAIN_PATHS:
        if brain_path.exists():
            ag_transcript = brain_path / clean / ".system_generated/logs/transcript.jsonl"
            if ag_transcript.is_file():
                return ResolvedTarget("file", ag_transcript, clean, "antigravity")
            # Try search for partial UUID in brain
            for brain_dir in brain_path.glob(f"*{clean}*"):
                cand = brain_dir / ".system_generated/logs/transcript.jsonl"
                if cand.is_file():
                    return ResolvedTarget("file", cand, brain_dir.name, "antigravity")

    # 5. Check VS Code Copilot in workspaceStorage
    if VSCODE_STORAGE_PATH.exists():
        for cand in VSCODE_STORAGE_PATH.glob(f"*/GitHub.copilot-chat/transcripts/*{clean}*.jsonl"):
            if cand.is_file():
                return ResolvedTarget("file", cand, cand.stem, "copilot")

    # 6. Check Claude Code in ~/.claude/projects
    if CLAUDE_PROJECTS_PATH.exists():
        for cand in CLAUDE_PROJECTS_PATH.rglob(f"*{clean}*.jsonl"):
            if cand.is_file():
                return ResolvedTarget("file", cand, cand.stem, "claude")

    # 7. Fallback search across workspace and current dir
    for cand in Path.cwd().rglob(f"*{clean}*"):
        if cand.is_file() and cand.suffix in (".jsonl", ".json", ".md", ".txt"):
            return ResolvedTarget("file", cand, cand.stem, detect_platform_from_file(cand))

    print(f"Error: Target '{target}' not found directly or in standard storage locations.", file=sys.stderr)
    sys.exit(1)


def resolve_latest(platform_filter: Optional[str] = None) -> ResolvedTarget:
    """Find the most recently modified transcript across platforms."""
    candidates = []

    # Antigravity
    if not platform_filter or platform_filter == "antigravity":
        for brain_path in ANTIGRAVITY_BRAIN_PATHS:
            if brain_path.exists():
                for p in brain_path.glob("*/.system_generated/logs/transcript.jsonl"):
                    if p.is_file():
                        candidates.append((p.stat().st_mtime, "file", p, p.parent.parent.parent.name, "antigravity"))

    # VS Code Copilot
    if (not platform_filter or platform_filter == "copilot") and VSCODE_STORAGE_PATH.exists():
        for p in VSCODE_STORAGE_PATH.glob("*/GitHub.copilot-chat/transcripts/*.jsonl"):
            if p.is_file():
                candidates.append((p.stat().st_mtime, "file", p, p.stem, "copilot"))

    # OpenCode
    if (not platform_filter or platform_filter == "opencode") and OPENCODE_DB_PATH.exists():
        try:
            conn = sqlite3.connect(f"file:{OPENCODE_DB_PATH}?mode=ro", uri=True)
            row = conn.execute("SELECT id, time_created FROM session ORDER BY time_created DESC LIMIT 1").fetchone()
            if row:
                mtime = row[1] / 1000.0 if row[1] > 1e11 else float(row[1])
                candidates.append((mtime, "opencode_db", str(OPENCODE_DB_PATH), row[0], "opencode"))
        except Exception:
            pass

    if not candidates:
        print("Error: No transcripts found in standard locations.", file=sys.stderr)
        sys.exit(1)

    candidates.sort(key=lambda x: x[0], reverse=True)
    best = candidates[0]
    return ResolvedTarget(best[1], best[2], best[3], best[4])


def detect_platform_from_file(path: Path) -> str:
    s = str(path)
    if "antigravity" in s or "brain" in s:
        return "antigravity"
    if "GitHub.copilot-chat" in s:
        return "copilot"
    if "claude" in s:
        return "claude"
    try:
        with path.open("r", encoding="utf-8", errors="replace") as f:
            for _ in range(5):
                line = f.readline().strip()
                if not line:
                    continue
                if "step_index" in line or '"source"' in line:
                    return "antigravity"
                if "tool.execution_" in line or "copilot-agent" in line or '"user.message"' in line:
                    return "copilot"
    except Exception:
        pass
    return "generic"


# ---------------------------------------------------------------------------
# Tool Normalization & Arg Summaries
# ---------------------------------------------------------------------------

def normalize_tool_key(tool_name: str, args: Any) -> str:
    """Normalize tool names so shell commands become sh:<cmd> or sh:git <sub>."""
    if tool_name not in SHELL_TOOLS:
        return tool_name
    cmd = ""
    if isinstance(args, dict):
        cmd = args.get("command", "") or args.get("CommandLine", "")
    elif isinstance(args, str):
        try:
            parsed = json.loads(args)
            if isinstance(parsed, dict):
                cmd = parsed.get("command", "") or parsed.get("CommandLine", "")
            else:
                cmd = args
        except Exception:
            cmd = args
    cmd = str(cmd).strip()
    if not cmd:
        return "sh:?"
    try:
        words = [w for w in shlex.split(cmd) if "=" not in w.split("/")[0]]
    except ValueError:
        words = cmd.split()
    if not words:
        return "sh:?"
    head = Path(words[0]).name
    if head in {"git", "gh", "docker", "kubectl", "az", "npm", "composer", "cargo", "mvn"} and len(words) > 1:
        return f"sh:{head} {words[1]}"
    if head.startswith("python") and len(words) > 1 and words[1].endswith(".py"):
        return f"sh:{Path(words[1]).name}"
    return f"sh:{head}"


def summarize_args(tool_name: str, args: Any, max_len: int = 70) -> str:
    """Produce a compact representative argument summary for context."""
    if isinstance(args, str):
        try:
            args = json.loads(args)
        except Exception:
            pass
    if isinstance(args, dict):
        for k in ("command", "CommandLine"):
            if k in args:
                return str(args[k])[:max_len]
        for k in ("filePath", "path", "TargetFile", "AbsolutePath"):
            if k in args:
                return Path(args[k]).name
        for k in ("query", "Pattern"):
            if k in args:
                return f"query:{str(args[k])[:max_len]}"
        val = json.dumps(args, separators=(",", ":"))
        return val[:max_len]
    return str(args)[:max_len]


def shell_pipe_count(command: str) -> int:
    quote, escaped, count = None, False, 0
    for idx, char in enumerate(command):
        if escaped:
            escaped = False
            continue
        if char == "\\":
            escaped = True
            continue
        if quote:
            if char == quote:
                quote = None
            continue
        if char in ("'", '"'):
            quote = char
            continue
        if char == "|":
            prev = command[idx - 1] if idx > 0 else ""
            nxt = command[idx + 1] if idx + 1 < len(command) else ""
            if prev != "|" and nxt != "|":
                count += 1
    return count


# ---------------------------------------------------------------------------
# Normalized Session Representation
# ---------------------------------------------------------------------------

class IngestedSession:
    def __init__(self, target: ResolvedTarget):
        self.target = target
        self.session_id = target.session_id
        self.platform = target.platform
        self.raw_records_count = 0
        self.total_bytes = 0
        self.start_time: Optional[str] = None

        # Normalized records: (event_idx, byte_size, raw_type, tool_name, summary, record_obj)
        self.records: List[Tuple[int, int, str, str, str, Dict[str, Any]]] = []

        # High-level models
        self.user_turns: List[Dict[str, Any]] = []
        self.assistant_turns: List[Dict[str, Any]] = []
        self.tool_calls: List[Dict[str, Any]] = []
        self.failed_calls: List[Dict[str, Any]] = []
        self.command_smells: Dict[str, Any] = {
            "terminal_executions": 0,
            "inline_python": 0,
            "deep_pipelines": 0,
            "repeated_commands": 0,
            "duplicate_file_reads": 0,
        }
        self.total_result_bytes = 0


# ---------------------------------------------------------------------------
# Platform Ingestion Engines
# ---------------------------------------------------------------------------

def ingest_session(target: ResolvedTarget) -> IngestedSession:
    sess = IngestedSession(target)
    if target.kind == "opencode_db":
        _ingest_opencode_db(sess)
    else:
        path = Path(target.location)
        if target.platform == "antigravity":
            _ingest_antigravity_jsonl(path, sess)
        elif target.platform == "copilot":
            _ingest_copilot_jsonl(path, sess)
        else:
            _ingest_generic_file(path, sess)
    return sess


def _ingest_copilot_jsonl(path: Path, sess: IngestedSession) -> None:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    sess.raw_records_count = len(lines)
    sess.total_bytes = sum(len(ln.encode("utf-8")) for ln in lines)

    tool_completions = {}
    tool_starts = {}

    for idx, ln in enumerate(lines, 1):
        if not ln.strip():
            continue
        try:
            rec = json.loads(ln)
        except Exception:
            continue
        rtype = rec.get("type", "")
        rdata = rec.get("data", {})
        if rtype == "tool.execution_complete" and rdata.get("toolCallId"):
            tool_completions[rdata["toolCallId"]] = (idx, rdata)
        elif rtype == "tool.execution_start" and rdata.get("toolCallId"):
            tool_starts[rdata["toolCallId"]] = (idx, rdata)

    segment = 0
    terminal_cmds = []
    file_reads = []
    chain_broken = True

    for idx, ln in enumerate(lines, 1):
        blen = len(ln.encode("utf-8"))
        if not ln.strip():
            continue
        try:
            rec = json.loads(ln)
        except Exception:
            continue
        rtype = rec.get("type", "unknown")
        rdata = rec.get("data", {})
        ts = rec.get("timestamp")
        tname = rdata.get("toolName", "-") if rtype.startswith("tool.") else "-"
        summary = ""

        if rtype == "session.start":
            sess.start_time = rdata.get("startTime", ts)

        elif rtype == "user.message":
            segment += 1
            chain_broken = True
            content = rdata.get("content", "").strip()
            summary = content[:80]
            corr = USER_CORRECTION_PATTERN.search(content)
            sess.user_turns.append({
                "turn_num": len(sess.user_turns) + 1,
                "event_idx": idx,
                "timestamp": ts,
                "content": content,
                "is_correction": bool(corr),
                "correction_keyword": corr.group(0) if corr else None,
            })

        elif rtype == "assistant.message":
            content = rdata.get("content", "").strip()
            summary = content[:80]
            if content:
                chain_broken = True
            sess.assistant_turns.append({
                "turn_num": len(sess.assistant_turns) + 1,
                "event_idx": idx,
                "timestamp": ts,
                "content": content,
            })

        elif rtype == "tool.execution_start":
            cid = rdata.get("toolCallId")
            raw_args = rdata.get("arguments", {})
            if isinstance(raw_args, str):
                try:
                    raw_args = json.loads(raw_args)
                except Exception:
                    pass
            tkey = normalize_tool_key(tname, raw_args)
            asum = summarize_args(tname, raw_args)
            summary = asum

            _, comp_data = tool_completions.get(cid, (None, {}))
            success = comp_data.get("success")
            failed = (success is False)
            error_msg = comp_data.get("error") if failed else None

            if tname in SHELL_TOOLS:
                cmd = raw_args.get("command", "") if isinstance(raw_args, dict) else str(raw_args)
                sess.command_smells["terminal_executions"] += 1
                terminal_cmds.append(cmd)
                if INLINE_PYTHON_PATTERN.search(cmd):
                    sess.command_smells["inline_python"] += 1
                if shell_pipe_count(cmd) > 2:
                    sess.command_smells["deep_pipelines"] += 1

            if tname in ("read_file", "view_file") and isinstance(raw_args, dict):
                fpath = raw_args.get("filePath") or raw_args.get("AbsolutePath") or ""
                if fpath:
                    file_reads.append(fpath)

            call_info = {
                "call_id": cid,
                "event_idx": idx,
                "tool_name": tname,
                "tool_key": tkey,
                "args": raw_args,
                "args_summary": asum,
                "failed": failed,
                "error": error_msg,
                "segment": segment,
                "chain_start": chain_broken,
                "result_bytes": 0,
            }
            chain_broken = False
            sess.tool_calls.append(call_info)
            if failed:
                sess.failed_calls.append(call_info)

        sess.records.append((idx, blen, rtype, tname, summary, rec))

    sess.command_smells["repeated_commands"] = sum(c - 1 for c in Counter(terminal_cmds).values() if c > 1)
    sess.command_smells["duplicate_file_reads"] = sum(c - 1 for c in Counter(file_reads).values() if c > 1)


def _ingest_antigravity_jsonl(path: Path, sess: IngestedSession) -> None:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    sess.raw_records_count = len(lines)
    sess.total_bytes = sum(len(ln.encode("utf-8")) for ln in lines)

    segment = 0
    chain_broken = True
    terminal_cmds = []
    file_reads = []

    for idx, ln in enumerate(lines, 1):
        blen = len(ln.encode("utf-8"))
        if not ln.strip():
            continue
        try:
            rec = json.loads(ln)
        except Exception:
            continue

        stype = rec.get("type", "unknown")
        source = rec.get("source", "unknown")
        content = str(rec.get("content") or "")
        ts = rec.get("created_at")
        tcalls = rec.get("tool_calls") or []
        tname = "-"
        summary = ""

        # User turn
        if stype in ("USER_INPUT", "USER_EXPLICIT") or (idx == 1 and stype == "SYSTEM_MESSAGE"):
            segment += 1
            chain_broken = True
            summary = content[:80]
            corr = USER_CORRECTION_PATTERN.search(content)
            sess.user_turns.append({
                "turn_num": len(sess.user_turns) + 1,
                "event_idx": idx,
                "timestamp": ts,
                "content": content,
                "is_correction": bool(corr),
                "correction_keyword": corr.group(0) if corr else None,
            })

        elif stype == "GENERIC":
            res_len = len(content.encode("utf-8"))
            sess.total_result_bytes += res_len
            summary = f"Result payload ({res_len:,} B)"
            if sess.tool_calls:
                sess.tool_calls[-1]["result_bytes"] = res_len
                if "exited with code 1" in content or "Tool execution failed" in content:
                    sess.tool_calls[-1]["failed"] = True
                    if sess.tool_calls[-1] not in sess.failed_calls:
                        sess.failed_calls.append(sess.tool_calls[-1])

        elif stype in ("PLANNER_RESPONSE", "MODEL") or (source == "MODEL" and stype != "GENERIC"):
            summary = (content or rec.get("thinking", ""))[:80]
            if content and not tcalls:
                chain_broken = True
            sess.assistant_turns.append({
                "turn_num": len(sess.assistant_turns) + 1,
                "event_idx": idx,
                "timestamp": ts,
                "content": content,
            })

            for tc in tcalls:
                tname = tc.get("name") or tc.get("ToolName") or tc.get("toolAction", "tool_call")
                args = tc.get("args") or tc.get("Arguments") or {}
                tkey = normalize_tool_key(tname, args)
                asum = summarize_args(tname, args)
                status = rec.get("status", "")
                failed = (status == "ERROR" or "error" in str(status).lower())

                if tname in SHELL_TOOLS:
                    cmd = args.get("CommandLine", "") or args.get("command", "")
                    sess.command_smells["terminal_executions"] += 1
                    terminal_cmds.append(cmd)
                    if INLINE_PYTHON_PATTERN.search(cmd):
                        sess.command_smells["inline_python"] += 1
                    if shell_pipe_count(cmd) > 2:
                        sess.command_smells["deep_pipelines"] += 1

                if tname in ("read_file", "view_file") and isinstance(args, dict):
                    fp = args.get("AbsolutePath") or args.get("filePath") or ""
                    if fp:
                        file_reads.append(fp)

                call_info = {
                    "call_id": tc.get("id"),
                    "event_idx": idx,
                    "tool_name": tname,
                    "tool_key": tkey,
                    "args": args,
                    "args_summary": asum,
                    "failed": failed,
                    "error": str(content)[:200] if failed else None,
                    "segment": segment,
                    "chain_start": chain_broken,
                    "result_bytes": 0,
                }
                chain_broken = False
                sess.tool_calls.append(call_info)
                if failed:
                    sess.failed_calls.append(call_info)

        sess.records.append((idx, blen, stype, tname, summary, rec))

    sess.command_smells["repeated_commands"] = sum(c - 1 for c in Counter(terminal_cmds).values() if c > 1)
    sess.command_smells["duplicate_file_reads"] = sum(c - 1 for c in Counter(file_reads).values() if c > 1)


def _ingest_opencode_db(sess: IngestedSession) -> None:
    db_path = Path(sess.target.location)
    conn = sqlite3.connect(f"file:{db_path}?mode=ro", uri=True)
    rows = conn.execute(
        "SELECT p.id, p.data, m.data FROM part p LEFT JOIN message m ON m.id = p.message_id "
        "WHERE p.session_id = ? ORDER BY p.id",
        (sess.session_id,),
    ).fetchall()

    sess.raw_records_count = len(rows)
    segment = 0
    chain_broken = True
    terminal_cmds = []

    for idx, (pid, pdata, mdata) in enumerate(rows, 1):
        blen = len(pdata.encode("utf-8"))
        sess.total_bytes += blen
        part = json.loads(pdata)
        msg = json.loads(mdata) if mdata else {}
        role = msg.get("role", "assistant")
        ptype = part.get("type", "unknown")
        tname = "-"
        summary = ""

        if ptype == "text":
            text = part.get("text", "").strip()
            summary = text[:80]
            if role == "user":
                segment += 1
                chain_broken = True
                corr = USER_CORRECTION_PATTERN.search(text)
                sess.user_turns.append({
                    "turn_num": len(sess.user_turns) + 1,
                    "event_idx": idx,
                    "timestamp": msg.get("time_created"),
                    "content": text,
                    "is_correction": bool(corr),
                    "correction_keyword": corr.group(0) if corr else None,
                })
            else:
                if text:
                    chain_broken = True
                sess.assistant_turns.append({
                    "turn_num": len(sess.assistant_turns) + 1,
                    "event_idx": idx,
                    "timestamp": msg.get("time_created"),
                    "content": text,
                })

        elif ptype == "tool":
            tname = part.get("tool", "unknown_tool")
            state = part.get("state") or {}
            args = state.get("input") or {}
            tkey = normalize_tool_key(tname, args)
            asum = summarize_args(tname, args)
            summary = asum
            status = state.get("status")
            failed = (status == "error")
            output_str = str(state.get("output", ""))
            res_len = len(output_str.encode("utf-8"))
            sess.total_result_bytes += res_len

            if tname in SHELL_TOOLS:
                cmd = args.get("command", "") if isinstance(args, dict) else str(args)
                sess.command_smells["terminal_executions"] += 1
                terminal_cmds.append(cmd)
                if INLINE_PYTHON_PATTERN.search(cmd):
                    sess.command_smells["inline_python"] += 1
                if shell_pipe_count(cmd) > 2:
                    sess.command_smells["deep_pipelines"] += 1

            call_info = {
                "call_id": part.get("callID"),
                "event_idx": idx,
                "tool_name": tname,
                "tool_key": tkey,
                "args": args,
                "args_summary": asum,
                "failed": failed,
                "error": str(state.get("error"))[:200] if failed else None,
                "segment": segment,
                "chain_start": chain_broken,
                "result_bytes": res_len,
            }
            chain_broken = False
            sess.tool_calls.append(call_info)
            if failed:
                sess.failed_calls.append(call_info)

        sess.records.append((idx, blen, ptype, tname, summary, part))

    sess.command_smells["repeated_commands"] = sum(c - 1 for c in Counter(terminal_cmds).values() if c > 1)


def _ingest_generic_file(path: Path, sess: IngestedSession) -> None:
    # Fallback line-by-line JSON or markdown
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    sess.raw_records_count = len(lines)
    sess.total_bytes = sum(len(ln.encode("utf-8")) for ln in lines)
    for idx, ln in enumerate(lines, 1):
        blen = len(ln.encode("utf-8"))
        sess.records.append((idx, blen, "generic", "-", ln[:80], {}))


# ---------------------------------------------------------------------------
# Offload Engine
# ---------------------------------------------------------------------------

def classify_script_candidate(seq: Tuple[str, ...], sample_args: List[str]) -> Tuple[str, str]:
    is_all_shell = all(k.startswith("sh:") for k in seq)
    has_git = any("git" in k for k in seq)
    has_reads = any(k in ("read_file", "view_file") for k in seq)
    has_grep = any("grep" in k for k in seq)

    parts = []
    for k in seq:
        clean = k.replace("sh:", "").replace(" ", "-").split("_")[0]
        if clean not in parts:
            parts.append(clean)
    sname = "_".join(parts)[:35] + ".py"

    if is_all_shell or (has_git and not has_reads):
        return "Script", sname
    if has_grep and has_reads:
        return "Script + flags", sname
    return "Script + flags", sname


def run_offload_analysis(sess: IngestedSession, max_n: int = 4, min_repeat: int = 2, top: int = 8) -> Dict[str, Any]:
    steps = sess.tool_calls
    total = len(steps)

    chains = []
    current_chain = []
    for idx, call in enumerate(steps):
        if call.get("chain_start", False) and current_chain:
            chains.append(current_chain)
            current_chain = []
        current_chain.append(idx)
    if current_chain:
        chains.append(current_chain)
    chains = [c for c in chains if len(c) >= 2]

    retries = []
    for i in range(1, total):
        prev = steps[i - 1]
        curr = steps[i]
        if prev["failed"] and curr["tool_key"] == prev["tool_key"]:
            retries.append(i)

    found_seqs = {}
    sample_contexts = {}
    for n in range(max_n, 1, -1):
        grams = Counter()
        where = {}
        args_map = {}
        for i in range(total - n + 1):
            window = steps[i:i + n]
            if len({c["segment"] for c in window}) != 1:
                continue
            key = tuple(c["tool_key"] for c in window)
            if len(set(key)) == 1:
                continue
            grams[key] += 1
            where.setdefault(key, []).append(i)
            args_map.setdefault(key, [c["args_summary"] for c in window])

        for key, count in grams.items():
            if count < min_repeat:
                continue
            subsumed = any(count <= c and _contains(longer, key) for longer, (c, _) in found_seqs.items())
            if not subsumed:
                found_seqs[key] = (count, where[key])
                sample_contexts[key] = args_map[key]

    covered = set(retries)
    for c in chains:
        covered.update(c)
    for key, (_, starts) in found_seqs.items():
        for s in starts:
            covered.update(range(s, s + len(key)))

    in_chain = {i for c in chains for i in c}
    saved_chains = sum(len(c) - 1 for c in chains)
    saved_retries = sum(1 for i in retries if i not in in_chain)
    saved = min(max(total - 1, 0), saved_chains + saved_retries)

    raw_candidates = []
    for key, (count, _) in found_seqs.items():
        calls_saved = (len(key) - 1) * count
        samples = sample_contexts.get(key, [])
        sclass, sname = classify_script_candidate(key, samples)
        raw_candidates.append({
            "sequence": list(key),
            "sequence_display": " → ".join(f"`{k}`" for k in key),
            "occurrences": count,
            "calls_saved": calls_saved,
            "suggested_script": sname,
            "suggested_class": sclass,
            "sample_args": " → ".join(samples),
        })

    raw_candidates.sort(key=lambda x: -x["calls_saved"])
    top_candidates = raw_candidates[:top]

    return {
        "tool_calls": total,
        "mechanical_chains": len(chains),
        "calls_in_chains": sum(len(c) for c in chains),
        "repeated_sequences": len(found_seqs),
        "retry_loops": len(retries),
        "offloadable_share": round(len(covered) / total, 2) if total else 0.0,
        "projected_calls_after_scripting": total - saved,
        "candidates": top_candidates,
    }


def _contains(longer: Tuple[str, ...], shorter: Tuple[str, ...]) -> bool:
    n = len(shorter)
    return any(longer[i:i + n] == shorter for i in range(len(longer) - n + 1))


# ---------------------------------------------------------------------------
# Specialized Analysis Modes: Schema, Sizes, Segments
# ---------------------------------------------------------------------------

def extract_nested_keys(obj: Any, prefix: str = "", max_depth: int = 3, depth: int = 1) -> Dict[str, str]:
    keys = {}
    if depth > max_depth or not isinstance(obj, dict):
        return keys
    for k, v in obj.items():
        full_k = f"{prefix}.{k}" if prefix else k
        if isinstance(v, dict) and depth < max_depth:
            keys.update(extract_nested_keys(v, full_k, max_depth, depth + 1))
        elif isinstance(v, list) and v and isinstance(v[0], dict) and depth < max_depth:
            keys.update(extract_nested_keys(v[0], f"{full_k}[]", max_depth, depth + 1))
        else:
            sample_val = str(v)
            if len(sample_val) > 40:
                sample_val = sample_val[:37] + "..."
            keys[full_k] = sample_val
    return keys


def run_schema_analysis(sess: IngestedSession) -> str:
    """Generate comprehensive schema introspection & key field mappings."""
    types_count = Counter()
    types_keys = {}

    for _, _, rtype, _, _, rec in sess.records:
        types_count[rtype] += 1
        if rtype not in types_keys and rec:
            types_keys[rtype] = extract_nested_keys(rec)

    out = []
    out.append(f"# Conversation Schema & Structure: `{sess.session_id}`")
    out.append("")
    out.append(f"- **Platform:** `{sess.platform}` | **Total Records:** {sess.raw_records_count:,} | **Total Bytes:** {sess.total_bytes:,} B")
    out.append("")

    out.append("## Field Identification")
    out.append("")
    if sess.platform == "copilot":
        out.append("- **User message text:** `data.content` (on `user.message`)")
        out.append("- **Assistant text:** `data.content` (on `assistant.message`)")
        out.append("- **Tool name:** `data.toolName` (on `tool.execution_start`)")
        out.append("- **Tool arguments:** `data.arguments` (on `tool.execution_start`)")
        out.append("- **Tool result / payload:** Stored in `chat-session-resources/` out-of-band")
        out.append("- **Error / failure status:** `data.success` (boolean on `tool.execution_complete`)")
        out.append("- **Timestamps:** `timestamp`, `data.startTime`")
        out.append("- **Tool call ID:** `data.toolCallId`")
    elif sess.platform == "antigravity":
        out.append("- **User message text:** `content` (on `USER_INPUT` / `SYSTEM_MESSAGE`)")
        out.append("- **Assistant text / thinking:** `content`, `thinking` (on `PLANNER_RESPONSE`)")
        out.append("- **Tool name:** `tool_calls[].name` (on `PLANNER_RESPONSE`)")
        out.append("- **Tool arguments:** `tool_calls[].args` (on `PLANNER_RESPONSE`)")
        out.append("- **Tool result / payload:** `content` (on `GENERIC` response step)")
        out.append("- **Error / failure status:** `status` (`DONE`, `ERROR`)")
        out.append("- **Timestamps:** `created_at`")
        out.append("- **Turn ID / step index:** `step_index`")
    elif sess.platform == "opencode":
        out.append("- **User message text:** `part.text` (where parent `message.role == user`)")
        out.append("- **Assistant text:** `part.text` (where parent `message.role == assistant`)")
        out.append("- **Tool name:** `part.tool` (on `part.type == tool`)")
        out.append("- **Tool arguments:** `part.state.input`")
        out.append("- **Tool result / payload:** `part.state.output`")
        out.append("- **Error / failure status:** `part.state.status` (`completed`, `error`)")
        out.append("- **Tool call ID:** `part.callID`")

    out.append("")
    out.append("## Event Types & Nested Schema (Depth <= 3)")
    out.append("")
    out.append("| Event Type | Count | Sample Nested Keys |")
    out.append("| --- | ---: | --- |")
    for t, c in types_count.most_common():
        klist = list(types_keys.get(t, {}).keys())[:6]
        kstr = ", ".join(f"`{k}`" for k in klist) or "(primitive)"
        out.append(f"| `{t}` | {c} | {kstr} |")
    out.append("")
    return "\n".join(out)


def run_size_analysis(sess: IngestedSession, top_n: int = 10) -> str:
    """Analyze serialized byte sizes, event distribution, and context hogs."""
    bytes_by_type = Counter()
    bytes_by_tool = Counter()
    calls_by_tool = Counter()

    for idx, blen, rtype, tname, _, _ in sess.records:
        bytes_by_type[rtype] += blen
        if tname != "-":
            bytes_by_tool[tname] += blen
            calls_by_tool[tname] += 1

    out = []
    out.append(f"# Conversation Size & Context Hog Profile: `{sess.session_id}`")
    out.append("")
    out.append(f"- **Total Serialized Bytes:** {sess.total_bytes:,} B ({sess.total_bytes / (1024*1024):.2f} MB)")
    out.append(f"- **Total Result Payload Bytes Returned:** {sess.total_result_bytes:,} B")
    out.append("")

    out.append("## 1. Bytes by Event Type")
    out.append("")
    out.append("| Event Type | Count | Total Bytes | % of Total |")
    out.append("| --- | ---: | ---: | ---: |")
    for t, b in bytes_by_type.most_common():
        pct = (b / sess.total_bytes * 100) if sess.total_bytes else 0
        c = sum(1 for _, _, rtype, _, _, _ in sess.records if rtype == t)
        out.append(f"| `{t}` | {c:,} | {b:,} B | {pct:.1f}% |")
    out.append("")

    out.append("## 2. Bytes by Tool Name (Top 10)")
    out.append("")
    if bytes_by_tool:
        out.append("| Tool | Calls | Total Bytes | Avg Bytes |")
        out.append("| --- | ---: | ---: | ---: |")
        for t, b in bytes_by_tool.most_common(10):
            calls = calls_by_tool[t]
            avg = b // calls if calls else 0
            out.append(f"| `{t}` | {calls} | {b:,} B | {avg:,} B |")
        out.append("")
    else:
        out.append("- No discrete tool byte metrics available.\n")

    out.append(f"## 3. Top {top_n} Largest Single Events (Context Hogs)")
    out.append("")
    sorted_events = sorted(sess.records, key=lambda x: -x[1])[:top_n]
    out.append("| Event # | Type | Tool | Bytes | Summary / Excerpt |")
    out.append("| ---: | --- | --- | ---: | --- |")
    for idx, blen, rtype, tname, summary, _ in sorted_events:
        clean_sum = summary.replace("\n", " ")[:60]
        out.append(f"| #{idx} | `{rtype}` | `{tname}` | {blen:,} B | {clean_sum} |")
    out.append("")
    return "\n".join(out)


def run_segment_analysis(sess: IngestedSession, spec: str) -> str:
    """Extract a slice of events as a bounded, high-signal table."""
    start_idx, end_idx = 1, sess.raw_records_count

    if spec == "final":
        if sess.user_turns:
            start_idx = sess.user_turns[-1]["event_idx"]
        else:
            start_idx = max(1, sess.raw_records_count - 50)
    elif spec.startswith("turn:"):
        tnum = int(spec.split(":")[1])
        matching = [u for u in sess.user_turns if u["turn_num"] == tnum]
        if matching:
            start_idx = matching[0]["event_idx"]
            nxt = [u for u in sess.user_turns if u["turn_num"] == tnum + 1]
            end_idx = nxt[0]["event_idx"] - 1 if nxt else sess.raw_records_count
    elif ":" in spec:
        parts = spec.split(":")
        start_idx = int(parts[0])
        end_idx = int(parts[1])

    slice_records = [r for r in sess.records if start_idx <= r[0] <= end_idx]

    out = []
    out.append(f"# Segment Slice: Event #{start_idx} to #{end_idx} ({len(slice_records)} events)")
    out.append("")
    out.append("| Event # | Type | Tool | Bytes | Status | Arguments / Excerpt |")
    out.append("| ---: | --- | --- | ---: | --- | --- |")
    for idx, blen, rtype, tname, summary, _ in slice_records[:60]:
        tcall = next((c for c in sess.tool_calls if c["event_idx"] == idx), None)
        status = "failed" if (tcall and tcall["failed"]) else ("ok" if tcall else "-")
        clean_sum = summary.replace("\n", " ")[:60]
        out.append(f"| #{idx} | `{rtype}` | `{tname}` | {blen:,} B | {status} | {clean_sum} |")

    if len(slice_records) > 60:
        out.append(f"\n- ... and {len(slice_records) - 60} more events in slice.")
    out.append("")
    return "\n".join(out)


# ---------------------------------------------------------------------------
# History Tracking & Baseline Comparison
# ---------------------------------------------------------------------------

def default_history_file() -> Path:
    temp_dir = Path(tempfile.gettempdir()) / "ai-conversation-review"
    temp_dir.mkdir(parents=True, exist_ok=True)
    return temp_dir / "review-history.jsonl"


def load_history(path: Path) -> List[Dict[str, Any]]:
    entries = []
    if not path.is_file():
        return entries
    with path.open("r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    entries.append(json.loads(line))
                except Exception:
                    pass
    return entries


def record_history_entry(path: Path, entry: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, separators=(",", ":")) + "\n")


def compare_history(current: Dict[str, Any], previous: Optional[Dict[str, Any]]) -> Dict[str, str]:
    if not previous:
        return {"note": "No previous history entry available for baseline comparison."}
    p_calls = previous.get("tool_calls", 0)
    c_calls = current.get("tool_calls", 0)
    p_offload = int(previous.get("offloadable_share", 0.0) * 100)
    c_offload = int(current.get("offloadable_share", 0.0) * 100)
    p_fails = previous.get("failed_calls", 0)
    c_fails = current.get("failed_calls", 0)

    delta = c_calls - p_calls
    return {
        "calls_comparison": f"{c_calls} ({'+' if delta >= 0 else ''}{delta} vs baseline {p_calls})",
        "offload_comparison": f"{c_offload}% (prev: {p_offload}%)",
        "fails_comparison": f"{c_fails} (prev: {p_fails})",
    }


# ---------------------------------------------------------------------------
# Markdown Dossier Rendering (Default Mode)
# ---------------------------------------------------------------------------

def render_audit_dossier(sess: IngestedSession, offload: Dict[str, Any],
                         history_delta: Dict[str, str], max_user_turns: int = 30) -> str:
    out = []
    out.append(f"# AI Conversation Audit: `{sess.session_id}`")
    out.append("")
    out.append(f"- **Platform:** `{sess.platform}` | **Records:** {sess.raw_records_count:,} ({sess.total_bytes / 1024:.1f} KB)")
    out.append(f"- **User Turns:** {len(sess.user_turns)} | **Assistant Turns:** {len(sess.assistant_turns)}")
    out.append("")

    out.append("## 1. Metrics & History Baseline")
    out.append("")
    out.append("| Metric | Current | Baseline Comparison |")
    out.append("| --- | ---: | --- |")
    calls_cmp = history_delta.get("calls_comparison", "No baseline")
    offload_cmp = history_delta.get("offload_comparison", "No baseline")
    fails_cmp = history_delta.get("fails_comparison", "No baseline")

    out.append(f"| **Tool calls** | {offload['tool_calls']} | {calls_cmp} |")
    out.append(f"| **Failed tool calls** | {len(sess.failed_calls)} | {fails_cmp} |")
    out.append(f"| **Mechanical chains** | {offload['mechanical_chains']} ({offload['calls_in_chains']} calls) | Consecutive calls without reasoning |")
    out.append(f"| **Repeated sequences** | {offload['repeated_sequences']} | Procedural n-grams |")
    out.append(f"| **Retry loops** | {offload['retry_loops']} | Retried failed calls |")
    out.append(f"| **Offloadable share** | **{int(offload['offloadable_share'] * 100)}%** | {offload_cmp} |")
    out.append(f"| **Projected calls after scripting** | **{offload['projected_calls_after_scripting']}** | Potential tool reduction |")
    out.append("")

    out.append("## 2. Top Script Candidates")
    out.append("")
    if offload["candidates"]:
        out.append("| Sequence | Occurrences | Calls Saved | Class | Suggested Script | Sample Context |")
        out.append("| --- | ---: | ---: | --- | --- | --- |")
        for c in offload["candidates"]:
            samp = c['sample_args'][:45] + "..." if len(c['sample_args']) > 45 else c['sample_args']
            out.append(f"| {c['sequence_display']} | {c['occurrences']} | {c['calls_saved']} | **{c['suggested_class']}** | `{c['suggested_script']}` | `{samp}` |")
    else:
        out.append("- None detected above recurrence threshold.")
    out.append("")

    out.append("## 3. Failed Tool Calls & Command Smells")
    out.append("")
    smells = sess.command_smells
    out.append(f"- **Terminal executions:** {smells['terminal_executions']}")
    out.append(f"- **Inline Python or heredocs:** {smells['inline_python']}")
    out.append(f"- **Pipelines with >2 pipes:** {smells['deep_pipelines']}")
    out.append(f"- **Exact repeated terminal commands:** {smells['repeated_commands']}")
    out.append(f"- **Duplicate file reads:** {smells['duplicate_file_reads']}")
    out.append("")

    if sess.failed_calls:
        out.append("### Failed Tool Calls Detail")
        for fcall in sess.failed_calls[:8]:
            out.append(f"- **Event #{fcall['event_idx']}** (`{fcall['tool_name']}`): args=`{fcall['args_summary']}`")
            if fcall["error"]:
                out.append(f"  *Error:* `{fcall['error']}`")
        if len(sess.failed_calls) > 8:
            out.append(f"- ... and {len(sess.failed_calls) - 8} more failed calls.")
        out.append("")
    else:
        out.append("- No failed tool calls detected.\n")

    out.append("## 4. User Turns & Corrections Timeline")
    out.append("")
    corrections = [u for u in sess.user_turns if u["is_correction"]]
    if corrections:
        out.append(f"**Detected User Corrections ({len(corrections)}):**")
        for c in corrections:
            snippet = c["content"].replace("\n", " ")[:120]
            out.append(f"- **User Turn {c['turn_num']} (Event #{c['event_idx']})** [Keyword: `{c['correction_keyword']}`]: \"{snippet}...\"")
        out.append("")

    out.append(f"**User Turns Overview (Showing {min(len(sess.user_turns), max_user_turns)} of {len(sess.user_turns)}):**")
    for uturn in sess.user_turns[:max_user_turns]:
        snippet = uturn["content"].replace("\n", " ")[:100]
        corr_flag = " ⚠️ [CORRECTION]" if uturn["is_correction"] else ""
        out.append(f"- Turn {uturn['turn_num']} (Event #{uturn['event_idx']}){corr_flag}: \"{snippet}...\"")
    if len(sess.user_turns) > max_user_turns:
        out.append(f"- ... {len(sess.user_turns) - max_user_turns} older user turns omitted.")
    out.append("")
    return "\n".join(out)


# ---------------------------------------------------------------------------
# CLI Entrypoint
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Universal multi-platform conversation audit, schema, and statistics.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("target", nargs="?", default=None, help="Transcript path, session UUID, or OpenCode ses_...")
    parser.add_argument("--latest", action="store_true", help="Auto-resolve most recently modified transcript")
    parser.add_argument("--platform", choices=["copilot", "antigravity", "opencode", "claude"], help="Platform filter for --latest")

    # Analysis modes
    parser.add_argument("--schema", action="store_true", help="Inspect event types, depth-3 keys, and field mappings")
    parser.add_argument("--sizes", action="store_true", help="Analyze serialized byte sizes, event distribution, and context hogs")
    parser.add_argument("--segment", type=str, default=None, help="Extract event-by-event slice: 'final', 'turn:N', or 'START:END'")
    parser.add_argument("--user-turns", action="store_true", help="List all user turns with timestamps and snippets")

    # Options
    parser.add_argument("--record", action="store_true", help="Append audit entry with metadata to review-history.jsonl")
    parser.add_argument("--history-file", type=Path, default=None, help="Custom review-history.jsonl file path")
    parser.add_argument("--top-candidates", type=int, default=8, help="Number of script candidates to report (default: 8)")
    parser.add_argument("--max-user-turns", type=int, default=30, help="Maximum user turns in timeline (default: 30)")
    parser.add_argument("--json", action="store_true", help="Emit structured JSON instead of Markdown")

    args = parser.parse_args()

    # 1. Resolve Target
    resolved = resolve_target(args.target, latest=args.latest, platform_filter=args.platform)

    # 2. Ingest
    sess = ingest_session(resolved)

    # 3. Handle Specialized Modes
    if args.schema:
        print(run_schema_analysis(sess))
        return

    if args.sizes:
        print(run_size_analysis(sess))
        return

    if args.segment:
        print(run_segment_analysis(sess, args.segment))
        return

    if args.user_turns:
        for u in sess.user_turns:
            print(f"Turn {u['turn_num']} (Event #{u['event_idx']}) [{u.get('timestamp') or 'no ts'}]: {u['content'][:120]}")
        return

    # 4. Default Mode: Audit & Offload Dossier
    offload = run_offload_analysis(sess, top=args.top_candidates)
    hist_file = args.history_file or default_history_file()
    history = load_history(hist_file)
    prev_entry = history[-1] if history else None
    history_delta = compare_history(offload, prev_entry)

    record_obj = {
        "timestamp": datetime.now().isoformat(),
        "session_id": sess.session_id,
        "platform": sess.platform,
        "transcript_path": str(sess.target.location),
        "user_turns": len(sess.user_turns),
        "assistant_turns": len(sess.assistant_turns),
        "tool_calls": offload["tool_calls"],
        "failed_calls": len(sess.failed_calls),
        "offloadable_share": offload["offloadable_share"],
        "projected_calls_after_scripting": offload["projected_calls_after_scripting"],
        "mechanical_chains": offload["mechanical_chains"],
        "calls_in_chains": offload["calls_in_chains"],
        "repeated_sequences": offload["repeated_sequences"],
        "retry_loops": offload["retry_loops"],
        "command_smells": sess.command_smells,
        "candidates": offload["candidates"],
    }

    if args.record:
        record_history_entry(hist_file, record_obj)

    if args.json:
        print(json.dumps(record_obj, separators=(",", ":")))
    else:
        dossier = render_audit_dossier(sess, offload, history_delta, max_user_turns=args.max_user_turns)
        print(dossier)


if __name__ == "__main__":
    try:
        main()
    except BrokenPipeError:
        sys.exit(0)
