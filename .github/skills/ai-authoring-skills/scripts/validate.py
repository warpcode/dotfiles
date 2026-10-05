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
  - bundled scripts compile: *.py -> py_compile.compile (in-process),
    *.sh -> bash -n, *.zsh -> zsh -n
  - workflow scriptability: SKILL.md does not hand-roll loops and does not
    document long command chains the agent must execute one call at a time
    (WARN only - prose guidance to bundle workflows into scripts)
  - bundled script usage: empirical conversation usage check via search_tools.py
    identifying active, low usage, and obsolete scripts (--audit-script-usage,
    default 200 sessions)

YAML parsing uses PyYAML when installed; otherwise falls back to a
minimal parser covering the flat key/value + block-scalar subset that
skill frontmatter actually uses.

Usage:
    ./validate.py <skill-dir> [<skill-dir> ...]
    ./validate.py --audit-script-usage [--sessions 200] <skill-dir>
    ./validate.py --self-test

Each check prints "<check> : PASS|FAIL|WARN"; exit status is 1 if any
check fails.
"""

import argparse
import os
import py_compile
import re
import subprocess
import sys
import tempfile
from pathlib import Path

_SCRIPTS_DIR = Path(__file__).resolve().parent
if str(_SCRIPTS_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPTS_DIR))
try:
    from audit_bundled_scripts import audit_skill_scripts, get_bundled_scripts
except Exception:
    audit_skill_scripts = None
    get_bundled_scripts = None

MAX_DESC_CHARS = 1024
MAX_BODY_LINES = 500

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
TRIGGER_RE = re.compile(r"\buse (this skill )?when\b|\btriggers?\b", re.I)

# Scriptability heuristics. These detect the *narration-only* workflow defect:
# a SKILL.md that documents a multi-step command chain for the agent to run one
# invocation at a time, instead of bundling it into a script. Guidance, not
# enforcement - hence WARN.
#
# Matching is line-oriented so a prohibition ("never run `python3 -c`", "use the
# bundle instead of hand-rolling the loop") is not mistaken for a prescription.
CODEISH_RE = re.compile(r"[;{}]|\bdo\b|\bdone\b|\$\(|`|\$\[")
# A shell loop needs shell structure after the keyword: an arithmetic form, a
# glob/quoted head, or a variable followed by `in`/`;`. This keeps English
# ("for the workflow", "for each PR") out of the results.
LOOP_RE = re.compile(
    r"^\s*(?:\$\(\()?\s*(?:for|while|until)\s+"
    r"(?:\(\(|\{|\$|\"|'|\[\[|\w+\s+in\s|\w+\s*;\s*do|\w+\s+in\b)"
    r"|^\s*\$\(\(\s*(?:for|while)\b"
)
INLINE_PY_RE = re.compile(r"python3?\s+-c\s+['\"]")
JQ_CHAIN_RE = re.compile(r"\|\s*(?:jq|grep|awk|sed)\b[^|]*\|\s*(?:jq|grep|awk|sed)\b")
# A documented instruction line ("1. run ...", "- execute ...") that ends in a
# shell-ish command *invoked bare* - not quoted as an inline code reference.
# Two or more of these outside a fenced block means the agent is being told to
# chain invocations. A prohibition ("no `gh`", "never run git push") or a passing
# mention in backticks is not a chain.
INSTRUCTION_CMD_RE = re.compile(
    r"^\s*(?:\d+\.|[-*])\s+[^`\n]{0,90}?"
    r"(?<![`\w])(?:gh|git|jq|curl|aws|kubectl|docker|glab|hub|ghcr)\s+[a-z][\w-]*"
)
# Prose that forbids or merely mentions the pattern rather than prescribing it.
# Split by strictness: PROHIBITION_RE is unambiguous and suppresses every
# finding; NEGATION_RE is weaker and only suppresses inline-code and chain
# findings, where a passing mention is the common false positive.
_PROHIBITION = (
    r"\b(?:never|avoid|instead\s+of|rather\s+than|anti-?pattern|forbidden"
    r"|prohibited|prohibit\w*|do\s*n[o']t|must\s+not|eliminat\w+|ban\w*"
    r"|block\w*|❌|✗|✘)\b"
)
# Unambiguous prohibition: suppresses every finding on the line.
PROHIBITION_RE = re.compile(_PROHIBITION, re.I)
# Weaker hedging ("no `gh`", "flag any use of") plus the prohibitions. Only
# suppresses inline-code and chain findings, where passing mentions dominate.
NEGATION_RE = re.compile(
    r"\b(?:no|not|cannot|only|flag|wrong|bad|❌|✗|✘)\b|" + _PROHIBITION, re.I
)
MAX_SCRIPTABILITY_CHAIN = 2
RESOURCE_RE = re.compile(
    r"(?<![\w/.])@?((?:references|templates|scripts|assets)/[\w][\w./-]*[.\w])"
)
SCRIPT_CHECKS = {
    ".sh": ["bash", "-n"],
    ".zsh": ["zsh", "-n"],
}

try:
    import yaml as _yaml
except ImportError:
    _yaml = None


def _scan_scalar(rest):
    """Walk a scalar string, tracking quote states and bracket/brace depths.
    Returns (cleaned_val, rest_tail). Raises ValueError if quotes or depth
    are unbalanced."""
    i = 0
    n = len(rest)
    in_quote = None
    stack = []
    end_idx = None
    is_quoted_scalar = rest.startswith('"') or rest.startswith("'")
    is_flow_collection = rest.startswith("[") or rest.startswith("{")

    while i < n:
        ch = rest[i]

        if in_quote:
            if ch == "\\" and i + 1 < n and rest[i + 1] in ('"', "'", "\\"):
                i += 2
                continue
            if ch == in_quote:
                in_quote = None
                i += 1
                if is_quoted_scalar and end_idx is None:
                    end_idx = i
                continue
            i += 1
            continue

        if ch in ('"', "'"):
            if is_quoted_scalar or is_flow_collection:
                in_quote = ch
            i += 1
            continue

        if ch == "#" and not stack:
            # YAML 1.2 §6.6: A '#' begins a comment only when preceded by whitespace
            if i > 0 and rest[i - 1] in (" ", "\t"):
                if end_idx is None:
                    end_idx = i
                break

        if is_flow_collection and ch in ("[", "{"):
            stack.append(ch)
            i += 1
            continue

        if is_flow_collection and ch in ("]", "}"):
            if not stack:
                raise ValueError("unexpected closing delimiter")
            top = stack.pop()
            if (ch == "]" and top != "[") or (ch == "}" and top != "{"):
                raise ValueError("mismatched closing delimiter")
            i += 1
            if not stack and end_idx is None:
                # Top level collection ended; record candidate end_idx
                end_idx = i
            continue

        i += 1

    if in_quote:
        raise ValueError("unclosed quote")
    if stack:
        raise ValueError("unclosed bracket/brace depth")

    if end_idx is None:
        end_idx = n

    val_part = rest[:end_idx].strip()
    tail_part = rest[end_idx:].strip()

    if tail_part and not tail_part.startswith("#"):
        raise ValueError(f"invalid trailing content after delimiter: {tail_part!r}")

    return val_part, tail_part


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
        m = re.match(r"^([A-Za-z][\w-]*):[ \t]*(.*)$", line)
        if not m:
            raise ValueError(f"cannot parse frontmatter line: {line!r}")
        key, rest = m.group(1), m.group(2).strip()

        # Reject tab immediately following key colon
        colon_idx = line.find(":")
        if colon_idx != -1 and line[colon_idx + 1 :].startswith("\t"):
            raise ValueError(f"invalid tab separator after key: {line!r}")

        if rest in (">", "|", ">-", "|-"):
            chunk = []
            while i < len(lines) and (
                not lines[i].strip() or lines[i][:1] in (" ", "\t")
            ):
                chunk.append(lines[i].strip())
                i += 1
            joiner = " " if rest.startswith(">") else "\n"
            data[key] = joiner.join(c for c in chunk if c)
        else:
            if rest.startswith(">") or rest.startswith("|"):
                raise ValueError(f"invalid block scalar indicator: {line!r}")

            try:
                val, _ = _scan_scalar(rest)
            except ValueError as e:
                raise ValueError(f"invalid YAML value in line {line!r}: {e}") from e

            if (val.startswith('"') and val.endswith('"')) or (
                val.startswith("'") and val.endswith("'")
            ):
                data[key] = val[1:-1]
            else:
                data[key] = val
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


def validate_skill(skill_dir, audit_script_usage=False, sessions=200):
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
    pyc_dir = Path(tempfile.gettempdir()) / "skill_validate_pyc"
    pyc_dir.mkdir(exist_ok=True)

    for root, dirs, files in os.walk(skill_dir):
        dirs[:] = [d for d in dirs if not d.startswith(".")]
        for f in files:
            p = Path(root) / f
            if p.suffix == ".py":
                # In-process compilation for Python files avoids ~60ms subprocess overhead per file
                try:
                    cfile = pyc_dir / f"{p.stem}_{abs(hash(str(p)))}.pyc"
                    py_compile.compile(str(p), cfile=str(cfile), doraise=True)
                except py_compile.PyCompileError as e:
                    detail = str(getattr(e, "msg", e)).strip().splitlines()
                    msg = detail[-1] if detail else str(e)
                    broken.append(f"{p.relative_to(skill_dir)}: {msg}")
                except Exception as e:
                    detail = str(e).strip().splitlines()
                    msg = detail[-1] if detail else str(e)
                    broken.append(f"{p.relative_to(skill_dir)}: {msg}")
            else:
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

    results.append(_check_scriptability(body_lines)[0])
    if audit_script_usage:
        results.append(_check_bundled_script_usage(skill_dir, sessions=sessions))
    return results


def _scriptability_findings(prose_lines):
    """Return scriptability findings for the prose lines of a SKILL.md.

    Each finding is a string. Fenced code is assumed already stripped.
    """
    findings = []
    chain_count = 0

    for i, line in enumerate(prose_lines, start=1):
        if not line.strip():
            continue
        # A line that forbids the pattern is guidance, not a prescription.
        prohibited = bool(PROHIBITION_RE.search(line))
        hedged = bool(NEGATION_RE.search(line))

        # Loops are matched strictly: only an explicit prohibition suppresses
        # them, because "for ... in" prose is easy to over-read.
        if not prohibited and LOOP_RE.search(line) and CODEISH_RE.search(line):
            findings.append(f"shell loop in SKILL.md (~line {i}): "
                            f"{line.strip()[:60]!r}")

        # Inline code and pipe chains are matched leniently: a passing mention
        # ("flag any use of `python3 -c`") is far more common than a real
        # prescription, so weaker hedging words suppress them too.
        if not hedged:
            if INLINE_PY_RE.search(line):
                findings.append(f"inline python3 -c in SKILL.md (~line {i}): "
                                f"{line.strip()[:60]!r}")
            if JQ_CHAIN_RE.search(line):
                findings.append(f"chained pipe filter in SKILL.md (~line {i}): "
                                f"{line.strip()[:60]!r}")

        if INSTRUCTION_CMD_RE.match(line) and not hedged:
            chain_count += 1

    if chain_count >= MAX_SCRIPTABILITY_CHAIN:
        findings.append(
            f"{chain_count} documented instruction lines each end in a command "
            "- the agent is chaining invocations. Consider a bundle script."
        )
    return findings


def _check_scriptability(body_lines):
    """Return a list holding one (check, status, detail) scriptability result.

    WARN when SKILL.md documents a workflow the agent must execute one call at a
    time, instead of bundling it into a script. Detects hand-rolled loops and
    documented command chains - the two shapes that make an agent burn hundreds
    of tool calls re-deriving a procedure it could have run once.

    Advisory by design (WARN, never FAIL): the check is heuristic, and a
    prohibition that mentions a loop in order to forbid it must not be flagged.
    """
    findings = _scriptability_findings(strip_fenced_blocks(body_lines))
    if findings:
        return [("workflow-scriptability", "WARN", "; ".join(findings))]
    return [("workflow-scriptability", "PASS", "")]


def _check_bundled_script_usage(skill_dir, sessions=200):
    """Audit empirical usage of a skill's bundled scripts in recent conversations.

    Identifies ACTIVE, LOW_USAGE, and NEVER_USED/ORPHAN scripts.
    WARN when obsolete or orphan scripts are found that should be removed or consolidated.
    """
    skill_dir = Path(skill_dir).resolve()
    if audit_skill_scripts is None or get_bundled_scripts is None:
        return ("bundled-script-usage", "WARN", "audit_bundled_scripts module unavailable")

    scripts = get_bundled_scripts(skill_dir)
    if not scripts:
        return ("bundled-script-usage", "PASS", "no bundled scripts to audit")

    try:
        report = audit_skill_scripts(skill_dir, sessions=sessions)
    except Exception as e:
        return ("bundled-script-usage", "WARN", f"audit failed: {e}")

    scripts_data = report.get("scripts", {})
    obsolete = [
        f"{name} ({d['status']})"
        for name, d in scripts_data.items()
        if d.get("status") in ("NEVER_USED", "ORPHAN")
    ]
    low_usage = [
        f"{name} ({d['invocations']} calls)"
        for name, d in scripts_data.items()
        if d.get("status") == "LOW_USAGE"
    ]
    scanned = report.get("scanned_sessions", sessions)
    if obsolete:
        detail = (
            f"scanned {scanned} sessions: {len(obsolete)} obsolete script(s) [{', '.join(obsolete)}]; "
            f"consider removal or consolidation"
        )
        return ("bundled-script-usage", "WARN", detail)
    elif low_usage:
        detail = (
            f"scanned {scanned} sessions: {len(scripts_data)} script(s) active/low-usage [{', '.join(low_usage)}]"
        )
        return ("bundled-script-usage", "PASS", detail)
    else:
        return (
            "bundled-script-usage",
            "PASS",
            f"scanned {scanned} sessions: all {len(scripts_data)} script(s) active",
        )


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

        loopy = tmp / "loopy-skill"
        loopy.mkdir()
        (loopy / "SKILL.md").write_text(
            "---\n"
            "name: loopy-skill\n"
            "description: >\n"
            "  Does a thing. Use when the user asks to do the thing.\n"
            "---\n"
            "# Loopy\n"
            "Run this:\n"
            "for f in $(git diff --name-only); do\n"
            "  git show origin/main:$f | git hash-object --stdin\n"
            "done\n"
        )

        chainy = tmp / "chainy-skill"
        chainy.mkdir()
        (chainy / "SKILL.md").write_text(
            "---\n"
            "name: chainy-skill\n"
            "description: >\n"
            "  Does a thing. Use when the user asks to do the thing.\n"
            "---\n"
            "# Chainy\n"
            "1. Run gh pr view 42 --json title\n"
            "2. Run gh pr checks 42\n"
            "3. Compare the two results.\n"
        )

        fenced = tmp / "fenced-skill"
        fenced.mkdir()
        (fenced / "SKILL.md").write_text(
            "---\n"
            "name: fenced-skill\n"
            "description: >\n"
            "  Does a thing. Use when the user asks to do the thing.\n"
            "---\n"
            "# Fenced\n"
            "Never do this:\n"
            "```bash\n"
            "for f in a b; do gh pr view $f; done\n"
            "gh pr view 1 --json x\n"
            "gh pr view 2 --json x\n"
            "```\n"
            "Use the bundle instead.\n"
        )

        def scriptability_of(d):
            """Return the finding strings for a skill dir (test helper)."""
            _, body = split_skill_md(Path(d) / "SKILL.md")
            return [
                detail
                for _, status, detail in _check_scriptability(body)
                if status == "WARN"
            ]

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
            ("scriptability-clean-skill",
             lambda: _expect(scriptability_of(good) == [])),
            ("scriptability-detects-loop",
             lambda: _expect(any("shell loop" in f for f in scriptability_of(loopy)))),
            ("scriptability-detects-chain",
             lambda: _expect(any("documented instruction lines" in f
                                 for f in scriptability_of(chainy)))),
            ("scriptability-ignores-fenced-code",
             lambda: _expect(scriptability_of(fenced) == [])),
            ("scriptability-ignores-prohibitions",
             lambda: _expect(_scriptability_findings(
                 ["Never write a python3 -c heredoc inline.",
                  "Use the bundle instead of hand-rolling the loop.",
                  "Anti-pattern: for f in a; do gh pr view $f; done"]) == [])),
            ("scriptability-flags-inline-py",
             lambda: _expect(any("inline python3 -c" in f
                                 for f in _scriptability_findings(
                                     ["Run python3 -c \"import json\" to parse."])))),
            ("scriptability-flags-loop-not-prose-for",
             lambda: _expect(any("shell loop" in f
                                 for f in _scriptability_findings(
                                     ["for f in $(git diff --name-only); do",
                                      "  git show origin/main:$f | jq ."])))),
            ("scriptability-allows-english-for",
             lambda: _expect(_scriptability_findings(
                 ["Collect the data for the report and summarise it."]) == [])),
            ("bundled-script-usage-no-scripts",
             lambda: _expect(_check_bundled_script_usage(loopy)[1] == "PASS")),
            ("bundled-script-usage-flag-integration",
             lambda: _expect(any(c[0] == "bundled-script-usage" and c[1] == "PASS"
                                 for c in validate_skill(loopy, audit_script_usage=True)))),
            ("flat-yaml-invalid-brackets",
             lambda: _expect_raises(ValueError, lambda: _parse_flat_yaml("name: [invalid yaml"))),
            ("flat-yaml-invalid-braces",
             lambda: _expect_raises(ValueError, lambda: _parse_flat_yaml("name: {unclosed"))),
            ("flat-yaml-trailing-comment",
             lambda: _expect(_parse_flat_yaml('metadata: {"a": 1} # note') == {"metadata": '{"a": 1}'})),
            ("flat-yaml-nested-brackets-error",
             lambda: _expect_raises(ValueError, lambda: _parse_flat_yaml("metadata: [a, [b, c]"))),
            ("flat-yaml-overclosed-braces-error",
             lambda: _expect_raises(ValueError, lambda: _parse_flat_yaml("metadata: {a: b}}"))),
            ("flat-yaml-quoted-comment-with-delimiter",
             lambda: _expect(_parse_flat_yaml('name: "x" # he said "hi"') == {"name": "x"})),
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


def _expect_raises(exc_type, fn):
    try:
        fn()
    except exc_type:
        return
    except Exception as e:
        raise AssertionError(f"expected {exc_type.__name__}, got {type(e).__name__}") from e
    raise AssertionError(f"expected {exc_type.__name__} to be raised")


def main(argv=None):
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("skills", nargs="*", help="skill directories to validate")
    ap.add_argument(
        "--self-test", action="store_true", help="run built-in assertions and exit"
    )
    ap.add_argument(
        "--audit-script-usage",
        action="store_true",
        help="audit empirical usage of bundled scripts across conversations (default: 200 sessions)",
    )
    ap.add_argument(
        "--sessions",
        type=int,
        default=200,
        help="max recent conversation sessions to scan for script audit (default: 200)",
    )
    args = ap.parse_args(argv)

    if args.self_test:
        return _self_test()
    if not args.skills:
        ap.error("no skill directories given")

    failed = False
    for d in args.skills:
        results = validate_skill(
            d,
            audit_script_usage=args.audit_script_usage,
            sessions=args.sessions,
        )
        ok = not any(s == "FAIL" for _, s, _ in results)
        failed |= not ok
        print(d)
        for check, status, detail in results:
            print(f"  {check} : {status}" + (f" - {detail}" if detail else ""))
        print(f"  result : {'FAIL' if not ok else 'PASS'}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
