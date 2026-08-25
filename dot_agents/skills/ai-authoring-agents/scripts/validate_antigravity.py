#!/usr/bin/env python3
"""
validate_antigravity.py

Strict validation for Google Antigravity subagent definitions (.md), per
https://antigravity.google/docs/subagents/

Split from validate.py because Antigravity is stricter than other platforms:
undocumented frontmatter keys break configuration, and misspelled tool names
can hang the subagent process (known issue).

Checks performed:
  - Frontmatter delimited by '---' and parses as YAML
  - Required keys present: name, description
  - No undocumented top-level frontmatter keys
  - `model` (if set) is a documented tier: inherit | flash | pro
  - `commandExecutionPolicy` (if set) is documented: off | auto | eager | sandbox
  - WARN on `tools` entries not attested in official docs (known hang risk)

Usage:
    ./validate_antigravity.py <path-to-agent-file-or-dir> [<path> ...]
    ./validate_antigravity.py --self-test
"""

import argparse
import os
import sys
import tempfile
from pathlib import Path

from validate import split_agent_file

# https://antigravity.google/docs/subagents/#frontmatter-configuration-yaml
DOCUMENTED_KEYS = {
    "name", "description", "tools", "mainAgent", "subagent", "model",
    "commandExecutionPolicy", "mcpServers", "skills", "plugins",
}
REQUIRED_KEYS = ("name", "description")
MODEL_TIERS = {"inherit", "flash", "pro"}
EXEC_POLICIES = {"off", "auto", "eager", "sandbox"}

# Attested in official docs/runtime; anything else risks the known hang issue.
ATTESTED_TOOLS = {
    "view_file", "replace_file_content", "grep_search", "run_command",
    "list_dir", "invoke_subagent",
}


def validate_agent(file_path):
    """Validate one Antigravity agent file. Returns list of (check, status, detail)."""
    results = []

    def add(check, status, detail=""):
        results.append((check, status, detail))

    file_path = Path(file_path).resolve()
    if not file_path.is_file():
        return [("file-exists", "FAIL", f"File not found: {file_path}")]

    try:
        meta, _body = split_agent_file(file_path)
        add("frontmatter-yaml", "PASS")
    except Exception as e:
        return results + [("frontmatter-yaml", "FAIL", str(e))]

    missing = [k for k in REQUIRED_KEYS if not str(meta.get(k, "")).strip()]
    if missing:
        add("required-keys", "FAIL", f"missing or empty: {', '.join(missing)}")
    else:
        add("required-keys", "PASS")

    unknown = sorted(set(meta) - DOCUMENTED_KEYS)
    if unknown:
        add("documented-keys", "FAIL",
            f"undocumented key(s): {', '.join(unknown)}; "
            f"allowed: {', '.join(sorted(DOCUMENTED_KEYS))}")
    else:
        add("documented-keys", "PASS")

    model = meta.get("model")
    if model is not None and str(model) not in MODEL_TIERS:
        add("model-tier", "FAIL",
            f"model {model!r} is not a documented tier "
            f"({'/'.join(sorted(MODEL_TIERS))})")
    elif model is not None:
        add("model-tier", "PASS")

    policy = meta.get("commandExecutionPolicy")
    if policy is not None and str(policy) not in EXEC_POLICIES:
        add("exec-policy", "FAIL",
            f"commandExecutionPolicy {policy!r} is not documented "
            f"({'/'.join(sorted(EXEC_POLICIES))})")
    elif policy is not None:
        add("exec-policy", "PASS")

    tools = meta.get("tools") or []
    if isinstance(tools, list):
        unattested = sorted({str(t) for t in tools} - ATTESTED_TOOLS)
        if unattested:
            add("tool-names", "WARN",
                f"not attested in docs (may hang agent): {', '.join(unattested)}")
        else:
            add("tool-names", "PASS")

    return results


def _self_test():
    """Run built-in self-test assertions."""
    with tempfile.TemporaryDirectory() as tmp:
        tmp = Path(tmp)

        good = tmp / "clean-agent.md"
        good.write_text(
            "---\n"
            "name: Clean Agent\n"
            "description: Documented-keys-only agent.\n"
            "subagent: true\n"
            "mainAgent: false\n"
            "model: flash\n"
            "commandExecutionPolicy: sandbox\n"
            "tools:\n"
            "  - view_file\n"
            "  - grep_search\n"
            "---\n"
            "# System prompt\n"
            "You are a clean agent. Analyze diffs carefully.\n"
        )

        bad = tmp / "leaky-agent.md"
        bad.write_text(
            "---\n"
            "name: Leaky Agent\n"
            "description: Superset-contaminated agent.\n"
            "mode: subagent\n"
            "temperature: 0.1\n"
            "tools:\n"
            "  - view_fiel\n"
            "---\n"
            "# System prompt\n"
            "You are a leaky agent. Analyze diffs carefully.\n"
        )

        good_res = validate_agent(good)
        assert not any(s == "FAIL" for _, s, _ in good_res), f"good agent failed: {good_res}"

        bad_res = validate_agent(bad)
        assert any(c == "documented-keys" and s == "FAIL" for c, s, _ in bad_res), \
            "expected documented-keys FAIL"
        assert any(c == "tool-names" and s == "WARN" for c, s, _ in bad_res), \
            "expected tool-names WARN"

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
                    if f.endswith(".md") and not f.startswith("."):
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
