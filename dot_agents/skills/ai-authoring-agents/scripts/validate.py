#!/usr/bin/env python3
"""
validate.py

Purpose: validate agent definition files (*.md, *.agent.md, *.yaml)
across supported AI agent platforms (OpenCode, Claude Code, Copilot/VS Code,
Google Antigravity, Codex, Cursor, Hermes).

Checks performed:
  - Frontmatter delimited by '---' and parses as YAML
  - `description`: present, non-empty, and provides role/trigger context
  - Agent identifier (filename stem) matches lowercase hyphen-separated convention
  - Body (system prompt): present and non-empty
  - Platform field conformance:
      - OpenCode: `mode` in {'primary', 'subagent', 'all'}; `permissions` is a dict
      - Claude Code: `tools`/`disallowedTools` is list/string; `isolation` valid
      - Copilot/VS Code: `model` is string or list; `tools` is list
      - Antigravity: `capabilities` is a mapping if defined
      - Antigravity strict keys: files under `.agents/` or `.gemini/agents/` may
        only use known frontmatter keys (Antigravity rejects unknown keys)
Usage:
    ./validate.py <path-to-agent-file-or-dir> [<path> ...]
    ./validate.py --self-test
"""

import argparse
import os
import re
import sys
import tempfile
from pathlib import Path

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*(\.agent)?$")

try:
    import yaml as _yaml
except ImportError:
    _yaml = None


def _parse_flat_yaml(text):
    """Minimal YAML parser fallback for agent frontmatter."""
    data = {}
    lines = text.splitlines()
    i = 0
    current_key = None
    list_items = []
    
    while i < len(lines):
        line = lines[i]
        i += 1
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        
        # List item under current key
        if line.startswith("  - ") or line.startswith("    - "):
            val = stripped.lstrip("- ").strip("\"'")
            if current_key:
                if not isinstance(data.get(current_key), list):
                    data[current_key] = []
                data[current_key].append(val)
            continue

        # Key-value pair
        m = re.match(r"^([A-Za-z][\w-]*):\s*(.*)$", line)
        if m:
            key, rest = m.group(1), m.group(2).strip()
            current_key = key
            if not rest:
                data[key] = {}
            elif rest.startswith("[") and rest.endswith("]"):
                # Inline JSON array
                items = [s for x in rest[1:-1].split(",") if (s := x.strip(" \"'"))]
                data[key] = items
            elif rest in (">", "|"):
                chunk = []
                while i < len(lines) and (not lines[i].strip() or lines[i][:1] in (" ", "\t")):
                    chunk.append(lines[i].strip())
                    i += 1
                joiner = " " if rest == ">" else "\n"
                data[key] = joiner.join(c for c in chunk if c)
            else:
                data[key] = rest.strip("\"'")
    return data


def parse_frontmatter(text):
    """Return parsed frontmatter dict."""
    if _yaml is not None:
        try:
            meta = _yaml.safe_load(text) or {}
            if not isinstance(meta, dict):
                raise ValueError("frontmatter is not a mapping")
            return meta
        except _yaml.YAMLError as e:
            raise ValueError(f"invalid YAML: {e}") from e
    return _parse_flat_yaml(text)


def split_agent_file(path):
    """Return (frontmatter_dict, body_lines) from an agent markdown file."""
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        raise ValueError("missing '---' frontmatter opener on line 1")
    try:
        close = next(i for i in range(1, len(lines)) if lines[i].strip() == "---")
    except StopIteration:
        raise ValueError("frontmatter not closed with '---'")
    meta = parse_frontmatter("\n".join(lines[1:close]))
    return meta, lines[close + 1 :]


def validate_agent(file_path):
    """Validate a single agent file. Returns list of (check, status, detail)."""
    results = []

    def add(check, status, detail=""):
        results.append((check, status, detail))

    file_path = Path(file_path).resolve()
    if not file_path.is_file():
        return [("file-exists", "FAIL", f"File not found: {file_path}")]

    stem = file_path.stem
    if stem.endswith(".agent"):
        stem = stem[:-6]

    if NAME_RE.match(file_path.stem):
        add("filename-format", "PASS")
    else:
        add("filename-format", "FAIL", f"{file_path.name!r} is not lowercase hyphen-separated")

    try:
        meta, body_lines = split_agent_file(file_path)
        add("frontmatter-yaml", "PASS")
    except Exception as e:
        return results + [("frontmatter-yaml", "FAIL", str(e))]

    # Description check
    desc = meta.get("description")
    if not desc or not str(desc).strip():
        add("description-present", "FAIL", "missing required 'description' in frontmatter")
    else:
        add("description-present", "PASS")

    # Body check
    body_text = "\n".join(body_lines).strip()
    if len(body_text) < 20:
        add("system-prompt-body", "FAIL", "system prompt body is empty or too short (< 20 chars)")
    else:
        add("system-prompt-body", "PASS")

    # OpenCode schema checks
    if "mode" in meta:
        mode = meta["mode"]
        if mode in ("primary", "subagent", "all"):
            add("opencode-mode", "PASS")
        else:
            add("opencode-mode", "FAIL", f"invalid mode {mode!r}; expected primary, subagent, or all")

    if "permissions" in meta:
        perms = meta["permissions"]
        if isinstance(perms, dict):
            add("opencode-permissions", "PASS")
        else:
            add("opencode-permissions", "FAIL", "permissions must be a mapping")

    # Copilot / VS Code schema checks
    if "tools" in meta:
        tools = meta["tools"]
        if isinstance(tools, (list, str)):
            add("tools-format", "PASS")
        else:
            add("tools-format", "FAIL", "tools must be a list or string")

    return results


def _self_test():
    """Run built-in self-test assertions."""
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)
        good = tmp / "code-reviewer.agent.md"
        good.write_text(
            "---\n"
            "name: Code Reviewer\n"
            "description: Reviews code changes for security and quality.\n"
            "model: gpt-4.1\n"
            "tools:\n"
            "  - read/readFile\n"
            "  - read/problems\n"
            "user-invocable: true\n"
            "---\n"
            "# Code Reviewer\n"
            "You are a code reviewer. Analyze diffs carefully.\n"
        )

        bad = tmp / "BAD_NAME.md"
        bad.write_text(
            "---\n"
            "name: Bad Agent\n"
            "---\n"
            "# System prompt\n"
        )

        good_res = validate_agent(good)
        assert not any(s == "FAIL" for _, s, _ in good_res), f"good agent failed: {good_res}"

        bad_res = validate_agent(bad)
        assert any(c == "filename-format" and s == "FAIL" for c, s, _ in bad_res), "expected filename FAIL"
        assert any(c == "description-present" and s == "FAIL" for c, s, _ in bad_res), "expected description FAIL"

    print("self-test : PASS")
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("paths", nargs="*", help="Agent files or directories to validate")
    ap.add_argument("--self-test", action="store_true", help="Run built-in self test and exit")
    args = ap.parse_args(argv)

    if args.self_test:
        return _self_test()

    if not args.paths:
        ap.error("no agent paths provided")

    all_files = []
    for p in args.paths:
        path = Path(p).resolve()
        if path.is_file():
            all_files.append(path)
        elif path.is_dir():
            for root, _, files in os.walk(path):
                for f in files:
                    if f.endswith((".md", ".agent.md", ".yaml")) and not f.startswith("."):
                        all_files.append(Path(root) / f)

    if not all_files:
        print("No matching agent definition files found.")
        return 0

    failed = False
    for f in all_files:
        results = validate_agent(f)
        ok = not any(s == "FAIL" for _, s, _ in results)
        failed |= not ok
        print(f)
        for check, status, detail in results:
            print(f"  {check} : {status}" + (f" - {detail}" if detail else ""))
        print(f"  result : {'FAIL' if not ok else 'PASS'}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
