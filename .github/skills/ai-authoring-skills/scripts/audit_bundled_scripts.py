#!/usr/bin/env python3
"""audit_bundled_scripts.py - Audit empirical usage of a skill's bundled scripts across conversations.

Connects to ai-conversation-review's search_tools.py to determine how frequently
agents actually execute a skill's bundled scripts in real conversation sessions.
Identifies:
  - ACTIVE scripts: frequently executed by agents.
  - LOW USAGE scripts: executed rarely (1-3 times); candidates for consolidation
    into composite workflow scripts to reduce tool call round-trips.
  - NEVER USED / OBSOLETE scripts: 0 executions across scanned sessions;
    candidates for deprecation and removal.

Usage:
  audit_bundled_scripts.py <skill-dir> [options]

Options:
  --sessions <N>    Number of most recent conversation sessions to scan (default: 200)
  --all             Scan all available sessions
  --json            Output results as structured JSON
  --strict          Exit 1 if any NEVER_USED or ORPHAN scripts are detected
  -h, --help        Show this help message and exit
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Set, Tuple


def find_search_tools_script() -> Optional[Path]:
    """Locate search_tools.py from ai-conversation-review."""
    # 1. Relative sibling skill directory (.github/skills/ai-conversation-review or ~/.gemini/config/skills/...)
    curr = Path(__file__).resolve()
    # ../../../ai-conversation-review/scripts/search_tools.py
    cand1 = curr.parent.parent.parent / "ai-conversation-review" / "scripts" / "search_tools.py"
    if cand1.is_file():
        return cand1

    # 2. User config path
    cand2 = Path.home() / ".gemini/config/skills/ai-conversation-review/scripts/search_tools.py"
    if cand2.is_file():
        return cand2

    # 3. Search under workspace skills
    cand3 = Path.cwd() / ".github/skills/ai-conversation-review/scripts/search_tools.py"
    if cand3.is_file():
        return cand3

    return None


def get_bundled_scripts(skill_dir: Path) -> List[Path]:
    """Find all runnable script files in <skill-dir>/scripts/ excluding tests and caches."""
    scripts_dir = skill_dir / "scripts"
    if not scripts_dir.is_dir():
        return []

    valid_extensions = {".sh", ".py", ".bash", ".zsh", ".awk"}
    scripts = []
    for p in sorted(scripts_dir.iterdir()):
        if not p.is_file():
            continue
        if p.name.startswith(".") or p.name.startswith("test_"):
            continue
        if p.suffix in valid_extensions:
            scripts.append(p)
    return scripts


def check_skill_references(skill_dir: Path, script_name: str) -> bool:
    """Check if script is referenced in SKILL.md or reference markdown files."""
    skill_md = skill_dir / "SKILL.md"
    if skill_md.is_file():
        try:
            content = skill_md.read_text(encoding="utf-8", errors="replace")
            if script_name in content:
                return True
        except Exception:
            pass

    # Check references directory
    ref_dir = skill_dir / "references"
    if ref_dir.is_dir():
        for r in ref_dir.glob("*.md"):
            try:
                if script_name in r.read_text(encoding="utf-8", errors="replace"):
                    return True
            except Exception:
                pass
    return False


def audit_skill_scripts(
    skill_dir: Path,
    sessions: int = 200,
    scan_all: bool = False,
) -> Dict[str, Any]:
    """Audit empirical usage of skill's bundled scripts across conversations."""
    skill_dir = skill_dir.resolve()
    scripts = get_bundled_scripts(skill_dir)
    if not scripts:
        return {
            "skill": skill_dir.name,
            "scripts_count": 0,
            "scanned_sessions": 0,
            "scripts": {},
            "verdict": "NO_SCRIPTS",
        }

    search_tools_bin = find_search_tools_script()
    if not search_tools_bin:
        raise RuntimeError("Could not find search_tools.py in ai-conversation-review skill.")

    script_names = [s.name for s in scripts]
    cmd = [
        sys.executable,
        str(search_tools_bin),
        "--scripts", ",".join(script_names),
        "--json",
    ]
    if scan_all:
        cmd.append("--all")
    else:
        cmd.extend(["--sessions", str(sessions)])

    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        raise RuntimeError(f"search_tools.py failed:\n{proc.stderr}")

    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError as e:
        raise RuntimeError(f"Failed to parse search_tools.py output: {e}\n{proc.stdout}")

    results = data.get("results", {})
    audit_report: Dict[str, Any] = {}

    for s_path in scripts:
        s_name = s_path.name
        s_data = results.get(s_name, {})
        invocations = s_data.get("invocations", 0)
        sess_count = s_data.get("sessions", 0)
        last_seen = s_data.get("last_seen")
        samples = s_data.get("samples", [])
        in_docs = check_skill_references(skill_dir, s_name)

        if invocations >= 5:
            status = "ACTIVE"
            recommendation = "Keep (frequently invoked in agent workflows)"
        elif invocations > 0:
            status = "LOW_USAGE"
            recommendation = "Consider consolidating into a composite script to reduce tool round-trips"
        else:
            if in_docs:
                status = "NEVER_USED"
                recommendation = "Documented but never invoked; evaluate utility or consider removal"
            else:
                status = "ORPHAN"
                recommendation = "Undocumented and never invoked; strong candidate for removal (dead code)"

        audit_report[s_name] = {
            "path": str(s_path.relative_to(skill_dir)),
            "invocations": invocations,
            "sessions": sess_count,
            "in_documentation": in_docs,
            "status": status,
            "last_seen": last_seen,
            "recommendation": recommendation,
            "samples": samples,
        }

    return {
        "skill": skill_dir.name,
        "skill_path": str(skill_dir),
        "scripts_count": len(scripts),
        "scanned_sessions": data.get("scanned_sessions", sessions),
        "matched_sessions": data.get("matched_sessions", 0),
        "scripts": audit_report,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Audit empirical usage of a skill's bundled scripts across conversations.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("skill_dir", type=Path, help="Path to the skill directory")
    parser.add_argument("--sessions", type=int, default=200, help="Number of recent sessions to scan (default: 200)")
    parser.add_argument("--all", action="store_true", help="Scan all available conversation sessions")
    parser.add_argument("--json", action="store_true", help="Output results in structured JSON")
    parser.add_argument("--strict", action="store_true", help="Exit 1 if NEVER_USED or ORPHAN scripts exist")

    args = parser.parse_args()

    if not args.skill_dir.is_dir():
        print(f"Error: '{args.skill_dir}' is not a directory.", file=sys.stderr)
        return 1

    try:
        report = audit_skill_scripts(args.skill_dir, sessions=args.sessions, scan_all=args.all)
    except Exception as e:
        print(f"Error during script audit: {e}", file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(report, indent=2))
        if args.strict:
            has_obsolete = any(
                item["status"] in ("NEVER_USED", "ORPHAN")
                for item in report.get("scripts", {}).values()
            )
            return 1 if has_obsolete else 0
        return 0

    print(f"# Bundled Script Usage Audit: `{report['skill']}`")
    print(f"- **Scanned Sessions:** {report['scanned_sessions']} | **Bundled Scripts:** {report['scripts_count']}\n")

    if not report.get("scripts"):
        print("No bundled scripts found in skill.")
        return 0

    print("| Script | Invocations | Sessions | Documented | Status | Recommendation |")
    print("|---|---:|---:|:---:|---|---|")

    has_obsolete = False
    for s_name, data in report["scripts"].items():
        doc_icon = "Yes" if data["in_documentation"] else "No"
        status = data["status"]
        if status in ("NEVER_USED", "ORPHAN"):
            has_obsolete = True
            badge = f"❌ {status}"
        elif status == "LOW_USAGE":
            badge = f"⚠️ {status}"
        else:
            badge = f"✅ {status}"

        print(f"| `{s_name}` | {data['invocations']} | {data['sessions']} | {doc_icon} | {badge} | {data['recommendation']} |")

    if has_obsolete:
        print("\n> [!WARNING] Unused or orphan scripts detected. Review for potential removal or consolidation.")

    if args.strict and has_obsolete:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())

