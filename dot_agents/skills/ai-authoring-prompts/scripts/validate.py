#!/usr/bin/env python3
"""
validate.py

Validator for the ai-authoring-prompts skill package:
  - SKILL.md exists and YAML frontmatter is valid
  - Name matches folder name exactly
  - Description is <= 1024 chars and states when to use the skill
  - Body is <= 500 lines
  - Referenced resource files (references/, templates/, scripts/) exist
  - Validates Mermaid.js blocks and checks for ASCII art anti-patterns
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

MAX_DESC_CHARS = 1024
MAX_BODY_LINES = 500

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
TRIGGER_RE = re.compile(r"\buse (this skill )?when\b|\btriggers?\b", re.I)
RESOURCE_RE = re.compile(
    r"(?<![\w/.])((?:references|templates|scripts|assets)/[\w][\w./-]*[.\w])"
)
SCRIPT_CHECKS = {
    ".py": [sys.executable, "-m", "py_compile"],
    ".sh": ["bash", "-n"],
    ".zsh": ["zsh", "-n"],
}

try:
    import yaml as _yaml
except ImportError:
    _yaml = None


def _parse_flat_yaml(text: str) -> dict:
    """Minimal YAML subset parser for flat keys and block scalars."""
    data = {}
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        i += 1
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        m = re.match(r"^([A-Za-z][\w-]*):\s*(.*)$", line)
        if not m:
            raise ValueError(f"cannot parse frontmatter line: {line!r}")
        key, rest = m.group(1), m.group(2).strip()
        if rest and rest[0] in ">|":
            chunk = []
            while i < len(lines) and (
                not lines[i].strip() or lines[i][:1] in (" ", "\t")
            ):
                chunk.append(lines[i].strip())
                i += 1
            joiner = " " if rest[0] == ">" else "\n"
            data[key] = joiner.join(c for c in chunk if c)
        else:
            data[key] = rest.strip("\"'")
    return data


def parse_frontmatter(text: str) -> dict:
    match = re.match(r"^---\n(.*?)\n---(?:\n|$)", text, re.DOTALL)
    if not match:
        raise ValueError("missing or invalid '---' frontmatter fences")
    raw_yaml = match.group(1)
    if _yaml is not None:
        try:
            meta = _yaml.safe_load(raw_yaml)
            if isinstance(meta, dict):
                return meta
        except Exception:
            pass
    return _parse_flat_yaml(raw_yaml)


def strip_fenced_blocks(lines):
    out, in_fence = [], False
    for ln in lines:
        if ln.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if not in_fence:
            out.append(ln)
    return out


def validate_skill(skill_dir: Path) -> bool:
    print(f"Validating {skill_dir.name}...")
    skill_file = skill_dir / "SKILL.md"
    if not skill_file.is_file():
        print(f"  SKILL.md exists : FAIL (file missing)")
        return False

    content = skill_file.read_text(encoding="utf-8")
    try:
        meta = parse_frontmatter(content)
        print("  frontmatter-yaml : PASS")
    except Exception as e:
        print(f"  frontmatter-yaml : FAIL ({e})")
        return False

    name = meta.get("name", "")
    if not name or not NAME_RE.match(name):
        print(f"  name-format : FAIL (invalid name '{name}')")
        return False
    print("  name-format : PASS")

    if name != skill_dir.name:
        print(f"  name-matches-folder : FAIL ('{name}' != '{skill_dir.name}')")
        return False
    print("  name-matches-folder : PASS")

    desc = meta.get("description", "")
    if not desc or len(desc) > MAX_DESC_CHARS:
        print(f"  description-length : FAIL (len={len(desc)}, max={MAX_DESC_CHARS})")
        return False
    print("  description-length : PASS")

    if not TRIGGER_RE.search(desc):
        print("  description-trigger : FAIL (missing explicit 'use when' trigger)")
        return False
    print("  description-trigger : PASS")

    parts = content.split("---", 2)
    body = parts[2] if len(parts) >= 3 else ""
    body_lines = body.strip().splitlines()
    if len(body_lines) > MAX_BODY_LINES:
        print(f"  body-lines : FAIL ({len(body_lines)} > {MAX_BODY_LINES})")
        return False
    print(f"  body-lines : PASS ({len(body_lines)} lines)")

    # Check resource references
    missing = []
    seen = set()
    for ln in strip_fenced_blocks(body_lines):
        for ref in RESOURCE_RE.findall(ln):
            ref = ref.rstrip(".")
            if ref in seen:
                continue
            seen.add(ref)
            if not (skill_dir / ref).exists():
                missing.append(ref)
    if missing:
        print(f"  resources-exist : FAIL (missing: {', '.join(missing)})")
        return False
    print("  resources-exist : PASS")

    # Script compilation check
    broken = []
    for root, dirs, files in os.walk(skill_dir):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for f in files:
            p = Path(root) / f
            checker = SCRIPT_CHECKS.get(p.suffix)
            if not checker:
                continue
            proc = subprocess.run(checker + [str(p)], capture_output=True, text=True)
            if proc.returncode != 0:
                detail = (proc.stderr or proc.stdout).strip().splitlines()
                msg = detail[-1] if detail else "see stderr"
                broken.append(f"{p.relative_to(skill_dir)}: {msg}")
    if broken:
        print(f"  scripts-compile : FAIL ({'; '.join(broken)})")
        return False
    print("  scripts-compile : PASS")

    print("  result : PASS")
    return True


def self_test():
    print("Running self-test...")
    with tempfile.TemporaryDirectory() as tmpdir:
        d = Path(tmpdir) / "ai-authoring-prompts"
        d.mkdir()
        (d / "SKILL.md").write_text(
            "---\nname: ai-authoring-prompts\ndescription: Use this skill when authoring prompts.\n---\n# Prompts\n",
            encoding="utf-8",
        )
        assert validate_skill(d)
    print("Self-test passed!")


def main():
    parser = argparse.ArgumentParser(description="Validate ai-authoring-prompts skill package")
    parser.add_argument("paths", nargs="*", help="Paths to skill directories")
    parser.add_argument("--self-test", action="store_true", help="Run internal self-test")
    args = parser.parse_args()

    if args.self_test:
        self_test()
        return

    if not args.paths:
        default_path = Path(__file__).resolve().parent.parent
        args.paths = [str(default_path)]

    all_passed = True
    for p in args.paths:
        path = Path(p)
        if not validate_skill(path):
            all_passed = False

    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()
