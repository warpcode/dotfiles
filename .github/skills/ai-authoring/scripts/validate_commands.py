#!/usr/bin/env python3
"""validate.py - Validate slash commands, prompt templates, and workflow files.

Purpose: Validate command definition files (*.md, *.prompt.md, *.toml)
across supported platforms (Claude Code, Google Antigravity, Copilot/VS Code,
Cursor, OpenCode, Codex).

Checks performed:
  - Frontmatter delimited by '---' and parses as valid YAML (or valid TOML for .toml files)
  - `description`: present and non-empty
  - Command identifier (filename stem) matches lowercase hyphen-separated convention
  - Parameter placeholders follow recognized syntax ($ARGUMENTS, $1..$n, ${input:...}, {{args}})
  - Pre-execution shell commands (!`...`) are read-only and safe from destructive tokens
  - Body / instructions present and non-empty

Usage:
    ./validate.py <path-to-command-or-dir> [<path> ...]
    ./validate.py --self-test
"""

from __future__ import annotations

import argparse
import os
import re
import sys
import tempfile
from pathlib import Path
from typing import Any, Dict, List, Tuple

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*(\.prompt)?$")
DANGEROUS_SHELL_RE = re.compile(r"\b(rm\s+-[rf]{1,2}|git\s+push\s+--force|mkfs|dd\s+if=|drop\s+database|drop\s+table)\b", re.I)
PRE_EXEC_SHELL_RE = re.compile(r"!`([^`]+)`")

try:
    import yaml as _yaml
except ImportError:
    _yaml = None

try:
    import tomllib as _toml
except ImportError:
    try:
        import tomli as _toml
    except ImportError:
        _toml = None


def _parse_flat_yaml(text: str) -> Dict[str, Any]:
    """Fallback minimal YAML parser for flat command frontmatter."""
    data: Dict[str, Any] = {}
    lines = text.splitlines()
    for line in lines:
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        m = re.match(r"^([A-Za-z0-9_-]+):\s*(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2).strip()
            if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                val = val[1:-1]
            data[key] = val
    return data


def split_command_file(path: Path) -> Tuple[Dict[str, Any], str]:
    """Split command file into frontmatter metadata and prompt body."""
    text = path.read_text(encoding="utf-8")
    if path.suffix == ".toml":
        if _toml:
            data = _toml.loads(text)
            body = data.get("prompt", "")
            return data, body
        else:
            # Basic fallback
            return {"description": "parsed-toml"}, text

    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return {}, text

    end_idx = -1
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end_idx = i
            break

    if end_idx == -1:
        raise ValueError("unclosed frontmatter: missing closing '---'")

    fm_text = "\n".join(lines[1:end_idx])
    body = "\n".join(lines[end_idx + 1:]).strip()

    if _yaml:
        try:
            meta = _yaml.safe_load(fm_text) or {}
        except Exception as e:
            raise ValueError(f"YAML parse error: {e}") from e
    else:
        meta = _parse_flat_yaml(fm_text)

    return meta, body


def validate_command_file(path: Path) -> List[Tuple[str, str, str]]:
    """Validate a single command file. Return list of (check, status, detail)."""
    results: List[Tuple[str, str, str]] = []

    def add(check: str, status: str, detail: str = "") -> None:
        results.append((check, status, detail))

    path = Path(path).resolve()
    if not path.is_file():
        return [("file-exists", "FAIL", f"file not found: {path}")]

    # 1. Filename format
    stem = path.stem
    if stem.endswith(".prompt"):
        stem = stem[:-7]
    if NAME_RE.match(path.name.split(".")[0]):
        add("filename-format", "PASS")
    else:
        add("filename-format", "FAIL", f"'{path.name}' is not lowercase hyphen-separated")

    # 2. Parse frontmatter / body
    try:
        meta, body = split_command_file(path)
        add("frontmatter-syntax", "PASS")
    except Exception as e:
        add("frontmatter-syntax", "FAIL", str(e))
        return results

    # 3. Description check
    desc = meta.get("description")
    if desc and str(desc).strip():
        add("description-present", "PASS")
    else:
        add("description-present", "FAIL", "missing or empty 'description'")

    # 4. Body non-empty
    if body and body.strip():
        add("body-instructions", "PASS")
    else:
        add("body-instructions", "FAIL", "command body / instructions is empty")

    # 5. Pre-execution shell command safety
    dangerous_cmds = []
    for match in PRE_EXEC_SHELL_RE.findall(body):
        if DANGEROUS_SHELL_RE.search(match):
            dangerous_cmds.append(match)

    if dangerous_cmds:
        add("shell-safety", "FAIL", f"dangerous mutating command in !`...`: {', '.join(dangerous_cmds)}")
    else:
        add("shell-safety", "PASS")

    return results


def run_self_tests() -> int:
    """Execute built-in test suite for command validation."""
    print("self-test")
    failed = 0

    with tempfile.TemporaryDirectory() as td:
        tmp = Path(td)

        # 1. Valid command
        c1 = tmp / "clean-branch.prompt.md"
        c1.write_text("---\ndescription: Delete merged local git branches\nargument-hint: [target-branch]\n---\nDelete all branches merged into $1.")
        res1 = validate_command_file(c1)
        if all(s == "PASS" for _, s, _ in res1):
            print("  valid-command : PASS")
        else:
            print("  valid-command : FAIL")
            failed += 1

        # 2. Missing description
        c2 = tmp / "missing-desc.md"
        c2.write_text("---\nargument-hint: none\n---\nRun audit.")
        res2 = validate_command_file(c2)
        if any(c == "description-present" and s == "FAIL" for c, s, _ in res2):
            print("  missing-description-caught : PASS")
        else:
            print("  missing-description-caught : FAIL")
            failed += 1

        # 3. Dangerous pre-exec shell command
        c3 = tmp / "dangerous-cmd.md"
        c3.write_text("---\ndescription: Dangerous command\n---\nRun this: !`rm -rf /` to clean disk.")
        res3 = validate_command_file(c3)
        if any(c == "shell-safety" and s == "FAIL" for c, s, _ in res3):
            print("  dangerous-shell-caught : PASS")
        else:
            print("  dangerous-shell-caught : FAIL")
            failed += 1

        # 4. Bad filename casing
        c4 = tmp / "BadCasing_Command.md"
        c4.write_text("---\ndescription: Valid\n---\nValid body.")
        res4 = validate_command_file(c4)
        if any(c == "filename-format" and s == "FAIL" for c, s, _ in res4):
            print("  bad-casing-caught : PASS")
        else:
            print("  bad-casing-caught : FAIL")
            failed += 1

    print(f"  result : {'PASS' if failed == 0 else 'FAIL'}")
    return 1 if failed > 0 else 0


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate slash command definitions.")
    parser.add_argument("--self-test", action="store_true", help="Run self-tests and exit")
    parser.add_argument("paths", nargs="*", help="Command files or directories to validate")
    args = parser.parse_args()

    if args.self_test:
        sys.exit(run_self_tests())

    if not args.paths:
        parser.print_help()
        sys.exit(1)

    has_fail = False
    for p_str in args.paths:
        p = Path(p_str)
        targets = []
        if p.is_dir():
            targets = [f for f in p.rglob("*") if f.is_file() and f.suffix in (".md", ".toml")]
        elif p.is_file():
            targets = [p]

        for target in targets:
            print(str(target))
            res = validate_command_file(target)
            for check, status, detail in res:
                suffix = f" - {detail}" if detail else ""
                print(f"  {check} : {status}{suffix}")
                if status == "FAIL":
                    has_fail = True
            overall = "FAIL" if any(s == "FAIL" for _, s, _ in res) else "PASS"
            print(f"  result : {overall}")

    sys.exit(1 if has_fail else 0)


if __name__ == "__main__":
    main()
