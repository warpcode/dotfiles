#!/usr/bin/env python3
"""
validate.py

Purpose: validate agent skill packages (folders containing SKILL.md)
against the key rules documented in ../SKILL.md:

  - SKILL.md exists; frontmatter delimited by '---' and parses as YAML
  - frontmatter `name`: present, lowercase hyphen-separated,
    matches the folder name exactly
  - frontmatter `description`: present, <=1024 chars (platform cap),
    states when to use the skill
  - body <=500 lines (progressive-disclosure budget)
  - every referenced resource path (references/, templates/, scripts/,
    assets/) exists relative to the skill folder; fenced code blocks are
    ignored so illustrative examples do not false-positive
  - bundled scripts compile: *.py -> python3 -m py_compile,
    *.sh -> bash -n, *.zsh -> zsh -n

YAML parsing uses PyYAML when installed; otherwise falls back to a
minimal parser covering the flat key/value + block-scalar subset that
skill frontmatter actually uses.

Usage:
    ./validate.py <skill-dir> [<skill-dir> ...]
    ./validate.py --self-test

Each check prints "<check> : PASS|FAIL|WARN"; exit status is 1 if any
check fails.
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


def _parse_flat_yaml(text):
    """Minimal YAML subset parser: flat keys, quoted/plain scalars and
    > / | block scalars - enough for SKILL.md frontmatter."""
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


def parse_frontmatter(text):
    """Return the frontmatter as a dict. Raise ValueError on bad structure."""
    meta = {}
    if _yaml is not None:
        try:
            meta = _yaml.safe_load(text) or {}
        except _yaml.YAMLError as e:
            raise ValueError(f"invalid YAML: {e}") from e
        if not isinstance(meta, dict):
            raise ValueError("frontmatter is not a mapping")
    else:
        meta = _parse_flat_yaml(text)
    return meta


def split_skill_md(path):
    """Return (meta, body_lines) from a SKILL.md path."""
    lines = path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        raise ValueError("missing '---' frontmatter opener on line 1")
    try:
        close = next(i for i in range(1, len(lines)) if lines[i].strip() == "---")
    except StopIteration:
        raise ValueError("frontmatter not closed with '---'")
    meta = parse_frontmatter("\n".join(lines[1:close]))
    return meta, lines[close + 1 :]


def strip_fenced_blocks(lines):
    """Drop fenced code blocks so example paths are not validated."""
    out, in_fence = [], False
    for ln in lines:
        if ln.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if not in_fence:
            out.append(ln)
    return out


def validate_skill(skill_dir):
    """Return a list of (check, status, detail); status is PASS/FAIL/WARN."""
    results = []

    def add(check, status, detail=""):
        results.append((check, status, detail))

    skill_dir = Path(skill_dir).resolve()
    md = skill_dir / "SKILL.md"
    if not md.is_file():
        return [("skill-md-exists", "FAIL", "SKILL.md not found")]

    try:
        meta, body_lines = split_skill_md(md)
        add("frontmatter-yaml", "PASS")
    except ValueError as e:
        return [("frontmatter-yaml", "FAIL", str(e))]

    name = meta.get("name")
    folder = skill_dir.name
    if not name:
        add("name-format", "FAIL", "missing required key: name")
        add("name-matches-folder", "FAIL", "no frontmatter name to compare")
    else:
        name = str(name)
        if NAME_RE.match(name):
            add("name-format", "PASS")
        else:
            add("name-format", "FAIL", f"{name!r} is not lowercase hyphen-separated")
        if name == folder:
            add("name-matches-folder", "PASS")
        else:
            add("name-matches-folder", "FAIL", f"{name!r} != folder name {folder!r}")

    desc = meta.get("description")
    if not desc:
        add("description-length", "FAIL", "missing required key: description")
        add("description-trigger", "FAIL", "missing required key: description")
    else:
        desc = str(desc)
        if len(desc) > MAX_DESC_CHARS:
            add("description-length", "FAIL", f"{len(desc)} chars > {MAX_DESC_CHARS}")
        else:
            add("description-length", "PASS")
        if TRIGGER_RE.search(desc):
            add("description-trigger", "PASS")
        else:
            add("description-trigger", "FAIL",
                "does not state when to use the skill "
                "(expected phrasing like 'Use when...' / 'triggers')")

    if len(body_lines) > MAX_BODY_LINES:
        add("body-lines", "FAIL", f"{len(body_lines)} lines > {MAX_BODY_LINES}")
    else:
        add("body-lines", "PASS")

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
        add("resources-exist", "FAIL", "missing: " + ", ".join(missing))
    else:
        add("resources-exist", "PASS")

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
        add("scripts-compile", "FAIL", "; ".join(broken))
    else:
        add("scripts-compile", "PASS")

    return results


def _self_test():
    """Run each assertion as a named check, reported like main() output."""
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)

        good = tmp / "my-skill"
        (good / "references").mkdir(parents=True)
        (good / "references" / "deep.md").write_text("# deep\n" + "x\n" * 10)
        (good / "scripts").mkdir()
        (good / "scripts" / "helper.py").write_text("print('hi')\n")
        (good / "SKILL.md").write_text(
            "---\n"
            "name: my-skill\n"
            "description: >\n"
            "  Does a thing. Use when the user asks to do the thing,\n"
            "  says \"do the thing\", or needs thing automation.\n"
            "---\n"
            "# My skill\n"
            "Read references/deep.md for details.\n"
        )

        bad = tmp / "Bad_Name"
        bad.mkdir()
        (bad / "SKILL.md").write_text(
            "---\n"
            "name: other-name\n"
            "---\n"
            "See templates/nope.md.\n"
        )

        def no_fails(results):
            problems = [f"{c}: {m}" for c, s, m in results if s == "FAIL"]
            assert not problems, "; ".join(problems)

        def failing_check(results, check, needle=""):
            msg = {c: m for c, s, m in results if s == "FAIL"}.get(check)
            assert msg is not None, f"expected FAIL for {check}"
            assert needle in msg, f"{check}: {msg!r} lacks {needle!r}"

        def no_fails_relative_dot():
            old = os.getcwd()
            try:
                os.chdir(good)
                no_fails(validate_skill("."))
            finally:
                os.chdir(old)

        checks = [
            ("good-skill-all-pass", lambda: no_fails(validate_skill(good))),
            ("relative-cwd-path", no_fails_relative_dot),
            ("bad-skill-name-mismatch",
             lambda: failing_check(validate_skill(bad), "name-matches-folder",
                                   "folder name")),
            ("bad-skill-description-missing",
             lambda: failing_check(validate_skill(bad), "description-length")),
            ("bad-skill-resource-missing",
             lambda: failing_check(validate_skill(bad), "resources-exist",
                                   "templates/nope.md")),
            ("flat-yaml-plain-scalar",
             lambda: _expect(_parse_flat_yaml("a: 1") == {"a": "1"})),
            ("flat-yaml-block-scalars",
             lambda: _expect(
                 _parse_flat_yaml("a: >\n  x\n  y\nb: |\n  l1\n  l2\nc: \"q\"\n")
                 == {"a": "x y", "b": "l1\nl2", "c": "q"})),
            ("strip-fenced-blocks",
             lambda: _expect(strip_fenced_blocks(
                 ["```", "templates/x.md", "```", "ok"]) == ["ok"])),
        ]

        results = []
        for name, fn in checks:
            try:
                fn()
                results.append((name, "PASS", ""))
            except Exception as e:  # ponytail: report every check, never crash mid-run
                results.append((name, "FAIL", str(e)))

    failed = False
    print("self-test")
    for name, status, detail in results:
        print(f"  {name} : {status}" + (f" - {detail}" if detail else ""))
        failed |= status == "FAIL"
    print(f"  result : {'FAIL' if failed else 'PASS'}")
    return 1 if failed else 0


def _expect(cond, msg="assertion failed"):
    assert cond, msg


def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("skills", nargs="*", help="skill directories to validate")
    ap.add_argument(
        "--self-test", action="store_true", help="run built-in assertions and exit"
    )
    args = ap.parse_args(argv)

    if args.self_test:
        return _self_test()
    if not args.skills:
        ap.error("no skill directories given")

    failed = False
    for d in args.skills:
        results = validate_skill(d)
        ok = not any(s == "FAIL" for _, s, _ in results)
        failed |= not ok
        print(d)
        for check, status, detail in results:
            print(f"  {check} : {status}" + (f" - {detail}" if detail else ""))
        print(f"  result : {'FAIL' if not ok else 'PASS'}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
