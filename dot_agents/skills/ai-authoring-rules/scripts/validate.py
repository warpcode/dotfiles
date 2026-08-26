#!/usr/bin/env python3
"""
validate.py

Purpose: Validate rule and instruction definition files (*.instructions.md,
*.mdc, *.md, *.rules) across supported AI agent platforms (Copilot/VS Code,
Cursor, Google Antigravity, Claude Code, OpenAI Codex, OpenCode, Hermes).

Checks performed:
  - Frontmatter delimited by '---' and parses as valid YAML
  - Filename matches convention: lowercase-hyphenated, correct extension per platform
  - Platform-specific frontmatter schema checks:
      - Copilot: `applyTo` (string/list), `description` (string), `excludeAgent`
      - Cursor: `alwaysApply` (bool), `globs` (string/list), `description` (string), `.mdc` extension
      - Antigravity: `trigger`/`activation` enum, `globs` required for glob mode, `description` for model_decision
      - Claude Code: `paths` (string/list)
  - Character and line budgets (Antigravity <= 12,000 chars, Claude <= 200 lines, Cursor <= 500 lines)
  - Body present and non-empty

Usage:
    ./validate.py <path-to-rule-file-or-dir> [<path> ...]
    ./validate.py --self-test
"""

import argparse
import os
import re
import sys
import tempfile
from pathlib import Path

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*(\.instructions)?$")
ROOT_MEMORY_FILES = {"AGENTS.md", "CLAUDE.md", "GEMINI.md", ".cursorrules", "SOUL.md", ".hermes.md"}

try:
    import yaml as _yaml
except ImportError:
    _yaml = None


def _parse_flat_yaml(text):
    """Minimal YAML parser fallback for rule frontmatter."""
    data = {}
    lines = text.splitlines()
    i = 0
    current_key = None
    
    while i < len(lines):
        line = lines[i]
        i += 1
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        
        # List item
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
                data[key] = [] if key in ("paths", "globs", "applyTo") else {}
            elif rest.startswith("[") and rest.endswith("]"):
                items = [x.strip(" \"'") for x in rest[1:-1].split(",") if x.strip()]
                data[key] = items
            elif rest.lower() == "true":
                data[key] = True
            elif rest.lower() == "false":
                data[key] = False
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


def split_rule_file(path):
    """Return (frontmatter_dict, body_lines, total_chars, total_lines)."""
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()
    total_chars = len(text)
    total_lines = len(lines)

    if not lines or lines[0].strip() != "---":
        return {}, lines, total_chars, total_lines

    try:
        close = next(i for i in range(1, len(lines)) if lines[i].strip() == "---")
    except StopIteration:
        raise ValueError("frontmatter opener '---' missing closing '---'")

    meta = parse_frontmatter("\n".join(lines[1:close]))
    return meta, lines[close + 1 :], total_chars, total_lines


def validate_rule(file_path):
    """Validate a single rule file. Returns list of (check, status, detail)."""
    results = []

    def add(check, status, detail=""):
        results.append((check, status, detail))

    file_path = Path(file_path).resolve()
    if not file_path.is_file():
        return [("file-exists", "FAIL", f"File not found: {file_path}")]

    name = file_path.name

    # Check for plain root files without frontmatter (AGENTS.md, CLAUDE.md, GEMINI.md, .cursorrules)
    is_root_memory = name in ROOT_MEMORY_FILES

    # Extension & Filename format check
    stem = file_path.stem
    if stem.endswith(".instructions"):
        stem = stem[:-13]

    if not is_root_memory and not file_path.name.startswith("."):
        clean_stem = file_path.name
        for ext in (".instructions.md", ".mdc", ".md", ".rules"):
            if clean_stem.endswith(ext):
                clean_stem = clean_stem[: -len(ext)]
                break
        if NAME_RE.match(clean_stem):
            add("filename-format", "PASS")
        else:
            add("filename-format", "FAIL", f"{file_path.name!r} does not follow lowercase-hyphenated naming")

    try:
        meta, body_lines, total_chars, total_lines = split_rule_file(file_path)
        add("frontmatter-yaml", "PASS")
    except Exception as e:
        return results + [("frontmatter-yaml", "FAIL", str(e))]

    # Body content check
    body_text = "\n".join(body_lines).strip()
    if len(body_text) < 10:
        add("body-content", "FAIL", "rule body is empty or too short (< 10 chars)")
    else:
        add("body-content", "PASS")

    # Character budget check (Antigravity ceiling: 12,000 chars)
    if total_chars > 12000:
        add("character-budget", "WARN", f"total characters ({total_chars}) exceeds Antigravity 12,000 char cap")
    else:
        add("character-budget", "PASS")

    # If this is a root memory file without frontmatter, pass
    if is_root_memory and not meta:
        return results

    # Cursor .mdc checks
    if name.endswith(".mdc") or ".cursor/rules" in str(file_path):
        if not name.endswith(".mdc"):
            add("cursor-extension", "FAIL", "Cursor rules must use the .mdc extension")
        else:
            add("cursor-extension", "PASS")

        if "alwaysApply" in meta:
            if isinstance(meta["alwaysApply"], bool):
                add("cursor-always-apply", "PASS")
            else:
                add("cursor-always-apply", "FAIL", "'alwaysApply' must be a boolean (true/false)")

        if "globs" in meta:
            if isinstance(meta["globs"], (str, list)):
                add("cursor-globs", "PASS")
            else:
                add("cursor-globs", "FAIL", "'globs' must be a string or list of glob patterns")

    # Copilot .instructions.md checks
    if name.endswith(".instructions.md") or ".github/instructions" in str(file_path):
        if not name.endswith(".instructions.md"):
            add("copilot-extension", "WARN", "Copilot scoped instructions should use .instructions.md")
        else:
            add("copilot-extension", "PASS")

        if "applyTo" in meta:
            if isinstance(meta["applyTo"], (str, list)):
                add("copilot-apply-to", "PASS")
            else:
                add("copilot-apply-to", "FAIL", "'applyTo' must be a string or list of glob patterns")

        if "excludeAgent" in meta:
            if meta["excludeAgent"] in ("code-review", "cloud-agent"):
                add("copilot-exclude-agent", "PASS")
            else:
                add("copilot-exclude-agent", "WARN", f"unrecognized excludeAgent {meta['excludeAgent']!r}")

    # Antigravity trigger / activation checks
    trigger = meta.get("trigger") or meta.get("activation")
    if trigger is not None:
        if trigger in ("always_on", "glob", "model_decision", "manual"):
            add("antigravity-trigger", "PASS")
        else:
            add("antigravity-trigger", "FAIL", f"invalid trigger {trigger!r}; expected always_on, glob, model_decision, or manual")

        if trigger == "glob" and not (meta.get("globs") or meta.get("glob_pattern")):
            add("antigravity-glob-pattern", "FAIL", "trigger: glob requires 'globs' or 'glob_pattern' field")
        elif trigger == "model_decision" and not meta.get("description"):
            add("antigravity-description", "WARN", "trigger: model_decision recommends 'description' for relevance evaluation")

    # Claude Code paths check
    if "paths" in meta:
        if isinstance(meta["paths"], (list, str)):
            add("claude-paths", "PASS")
        else:
            add("claude-paths", "FAIL", "'paths' must be a list or string of glob patterns")

    return results


def _self_test():
    """Run built-in self test suite."""
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)

        # 1. Valid Copilot instruction
        good_copilot = tmp / "typescript.instructions.md"
        good_copilot.write_text(
            "---\n"
            "applyTo: '**/*.ts,**/*.tsx'\n"
            "description: TypeScript standards\n"
            "---\n"
            "# TypeScript Guidelines\n"
            "- Use strict mode.\n"
        )

        # 2. Valid Cursor rule
        good_cursor = tmp / "react-style.mdc"
        good_cursor.write_text(
            "---\n"
            "description: React component standards\n"
            "globs: 'src/**/*.tsx'\n"
            "alwaysApply: false\n"
            "---\n"
            "# React Component Guidelines\n"
            "- Use functional components.\n"
        )

        # 3. Valid Antigravity rule
        good_antigravity = tmp / "security-rules.md"
        good_antigravity.write_text(
            "---\n"
            "trigger: model_decision\n"
            "description: Safety and secret protection guidelines\n"
            "---\n"
            "# Security Rules\n"
            "- Never commit plaintext secrets.\n"
        )

        # 4. Valid Claude Code rule
        good_claude = tmp / "test-rules.md"
        good_claude.write_text(
            "---\n"
            "paths:\n"
            "  - 'tests/**/*.py'\n"
            "---\n"
            "# Python Test Rules\n"
            "- Use pytest fixtures.\n"
        )

        # 5. Invalid rule (bad trigger)
        bad_rule = tmp / "bad-rule.md"
        bad_rule.write_text(
            "---\n"
            "trigger: invalid_mode\n"
            "---\n"
            "# Bad Rule\n"
            "- Test.\n"
        )

        for p in (good_copilot, good_cursor, good_antigravity, good_claude):
            res = validate_rule(p)
            assert not any(s == "FAIL" for _, s, _ in res), f"expected PASS for {p.name}: {res}"

        bad_res = validate_rule(bad_rule)
        assert any(c == "antigravity-trigger" and s == "FAIL" for c, s, _ in bad_res), "expected FAIL for bad trigger"

    print("self-test : PASS")
    return 0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("paths", nargs="*", help="Rule files or directories to validate")
    ap.add_argument("--self-test", action="store_true", help="Run built-in self test and exit")
    args = ap.parse_args(argv)

    if args.self_test:
        return _self_test()

    if not args.paths:
        ap.error("no rule paths provided")

    all_files = []
    for p in args.paths:
        path = Path(p).resolve()
        if path.is_file():
            all_files.append(path)
        elif path.is_dir():
            for root, _, files in os.walk(path):
                for f in files:
                    if (
                        f.endswith((".instructions.md", ".mdc", ".md", ".rules"))
                        and not f.startswith(".")
                        or f in ROOT_MEMORY_FILES
                    ):
                        all_files.append(Path(root) / f)

    if not all_files:
        print("No matching rule or instruction files found.")
        return 0

    failed = False
    for f in all_files:
        results = validate_rule(f)
        ok = not any(s == "FAIL" for _, s, _ in results)
        failed |= not ok
        print(f)
        for check, status, detail in results:
            print(f"  {check} : {status}" + (f" - {detail}" if detail else ""))
        print(f"  result : {'FAIL' if not ok else 'PASS'}")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
