#!/usr/bin/env python3
"""Triage Dependabot and code-scanning alerts for a repo in one call.

Read-only. Fetches every alert once, classifies each one against the default
branch, and prints the exact `gh` commands needed to clear the noise. It never
mutates alert state itself.

Why this exists
---------------
Two failure modes make hand-rolled alert review expensive and error-prone:

1. **Phantom alerts.** With no `.github/dependabot.yml`, Dependabot
   auto-discovers manifests repo-wide and keeps alerts for files that were later
   deleted or moved. One skill with a single `uv.lock` produced 9 open alerts for
   3 real ones -- the same advisories triplicated across the live path, a deleted
   tree, and a `.bk` backup directory. Each has to be checked against the default
   branch before it means anything, and that check is exactly where shell loops go
   wrong (see the zsh `path`/`PATH` trap in the module notes of
   audit_repo_branches.py).

2. **Unfixable alerts.** `first_patched_version: NONE` means no upgrade exists.
   Treating those as urgent wastes effort; they need recording, not chasing.

Code scanning alerts are included in the same pass because the two signals share
the "is this real?" question, and because an `error`-severity finding deserves
triage in the same sitting.

Usage
-----
  audit_repo_alerts.py --repo owner/name
  audit_repo_alerts.py --repo owner/name --base main --json
  audit_repo_alerts.py --repo owner/name --fetch

Requires: git, gh (authenticated, with `security_events` scope).
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import defaultdict


def run(cmd: list[str], check: bool = False) -> tuple[int, str, str]:
    p = subprocess.run(cmd, capture_output=True, text=True)
    if check and p.returncode != 0:
        sys.stderr.write(f"command failed: {' '.join(cmd)}\n{p.stderr}")
        raise SystemExit(1)
    return p.returncode, p.stdout, p.stderr


def resolve_repo(explicit: str | None) -> str:
    if explicit:
        return explicit
    code, out, _ = run(["git", "remote", "get-url", "origin"])
    if code != 0 or not out.strip():
        sys.stderr.write("cannot resolve origin remote; pass --repo owner/name\n")
        raise SystemExit(1)
    m = re.search(r"github\.com[:/]([^/]+)/([^/\s]+?)(?:\.git)?$", out.strip())
    if not m:
        sys.stderr.write(f"cannot parse owner/repo from remote URL: {out.strip()}\n")
        raise SystemExit(1)
    return f"{m.group(1)}/{m.group(2)}"


def gh_json(args: list[str]) -> object:
    code, out, err = run(["gh", "api", *args])
    if code != 0:
        if "Not Found" in err or "403" in err:
            return []
        sys.stderr.write(f"gh api {' '.join(args)} failed:\n{err}\n")
        return []
    try:
        return json.loads(out or "[]")
    except json.JSONDecodeError:
        return []


def file_exists_on_ref(ref: str, file_path: str) -> bool:
    """Existence check that cannot be corrupted by shell quirks.

    Never call this from a zsh loop that binds the result to a variable named
    `path` -- in zsh `path` is tied to `PATH`, so the assignment silently
    removes git from PATH and every check then "fails".
    """
    code, _, _ = run(["git", "cat-file", "-e", f"{ref}:{file_path}"])
    return code == 0


def fetch_dependabot(repo: str) -> list[dict]:
    return gh_json([f"repos/{repo}/dependabot/alerts", "--paginate"])


def fetch_code_scanning(repo: str) -> list[dict]:
    return gh_json([f"repos/{repo}/code-scanning/alerts", "--paginate"])


def classify_dependabot(alerts: list[dict], base_ref: str) -> list[dict]:
    rows = []
    for a in alerts:
        adv = a.get("security_advisory") or {}
        dep = a.get("dependency") or {}
        manifest = dep.get("manifest_path") or "?"
        vulns = a.get("security_vulnerabilities") or []
        patched = next(((v.get("first_patched_version") or {}).get("identifier")
                        for v in vulns
                        if (v.get("first_patched_version") or {}).get("identifier")),
                       None)
        rows.append({
            "number": a.get("number"),
            "state": a.get("state"),
            "severity": adv.get("severity"),
            "ghsa": adv.get("ghsa_id"),
            "summary": adv.get("summary"),
            "package": dep.get("package", {}).get("name"),
            "manifest": manifest,
            "manifest_exists": file_exists_on_ref(base_ref, manifest),
            "fix_available": bool(patched),
            "fixed_in": patched,
            "dismissed_reason": a.get("dismissed_reason"),
        })
    return rows


def pinned_manifests() -> set[str]:
    """Manifest directories declared in .github/dependabot.yml, if present."""
    code, out, _ = run(["git", "cat-file", "-e", "HEAD:.github/dependabot.yml"])
    if code != 0:
        return set()
    code2, cfg, _ = run(["git", "show", "HEAD:.github/dependabot.yml"])
    if code2 != 0:
        return set()
    return {m.group(1).strip().strip("/")
            for m in re.finditer(r"^\s*directory:\s*[\"']?([^\"'\n]+)", cfg, re.M)}


def render(dep: list[dict], cs: list[dict], repo: str, base: str) -> str:
    base_ref = f"origin/{base}"
    out = [f"# Alert audit -- {repo} (against `{base_ref}`)", ""]

    open_dep = [d for d in dep if d["state"] == "open"]
    phantom = [d for d in open_dep if not d["manifest_exists"]]
    real = [d for d in open_dep if d["manifest_exists"]]
    unfixable = [d for d in real if not d["fix_available"]]
    dismissed = [d for d in dep if d["state"] == "dismissed"]
    fixed = [d for d in dep if d["state"] == "fixed"]

    # Same advisory raised against several manifests -> one real issue, N noise rows.
    dupes: dict[tuple, list[dict]] = defaultdict(list)
    for d in open_dep:
        dupes[(d["ghsa"], d["package"])].append(d)

    out.append("| Signal | Count |")
    out.append("|---|---|")
    out.append(f"| Dependabot open (real manifest) | {len(real)} |")
    out.append(f"| Dependabot open (phantom -- manifest absent) | {len(phantom)} |")
    out.append(f"| ...of the real ones, no patched version exists | {len(unfixable)} |")
    out.append(f"| Dependabot dismissed | {len(dismissed)} |")
    out.append(f"| Dependabot fixed | {len(fixed)} |")
    out.append(f"| Code scanning open | {len([c for c in cs if c.get('state') == 'open'])} |")
    out.append("")

    pinned = pinned_manifests()
    if phantom:
        out.append("## Phantom alerts")
        out.append("")
        out.append("These reference a manifest that does not exist on the default branch, "
                   "so there is no pinned version to assess or upgrade.")
        out.append("")
        out.append("| # | Sev | Advisory | Package | Manifest |")
        out.append("|---|---|---|---|---|")
        for d in phantom:
            out.append(f"| {d['number']} | {d['severity']} | `{d['ghsa']}` "
                       f"| `{d['package']}` | `{d['manifest']}` |")
        out.append("")
        live_manifests = sorted({d["manifest"] for d in real})
        out.append("Dismiss as inaccurate -- one command per alert:")
        out.append("")
        out.append("```bash")
        for d in phantom:
            out.append(
                f"gh api --method PATCH repos/{repo}/dependabot/alerts/{d['number']} \\\n"
                f"  -f state=dismissed -f dismissed_reason=inaccurate \\\n"
                f"  -f dismissed_comment='Manifest absent from {base}; live path is "
                f"{live_manifests[0] if live_manifests else 'n/a'}'"
            )
        out.append("```")
        out.append("")
        out.append("> The comment field is capped at 280 characters; the API returns "
                   "HTTP 422 if you exceed it.")
        out.append("")
        if not pinned:
            out.append("**Dismissal does not fix the cause.** There is no "
                       "`.github/dependabot.yml`, so auto-discovery can re-adopt these "
                       "paths on the next scan. Pin `directory:` to the live manifest.")
            out.append("")

    if real:
        out.append("## Real alerts")
        out.append("")
        out.append("| # | Sev | Advisory | Package | Manifest | Fix |")
        out.append("|---|---|---|---|---|---|")
        for d in sorted(real, key=lambda x: (x["severity"] != "high", x["ghsa"] or "")):
            fix = f"`{d['fixed_in']}`" if d["fix_available"] else "**none available**"
            out.append(f"| {d['number']} | {d['severity']} | `{d['ghsa']}` "
                       f"| `{d['package']}` | `{d['manifest']}` | {fix} |")
        out.append("")
        for d in real:
            if d["summary"]:
                out.append(f"- `{d['ghsa']}` — {d['summary']}")
        out.append("")
        if unfixable:
            out.append(f"{len(unfixable)} of these have `first_patched_version: NONE` — "
                       "no upgrade exists yet. Record and revisit; do not churn on them.")
            out.append("")

    triplicated = {k: v for k, v in dupes.items() if len(v) > 1}
    if triplicated:
        out.append("## Duplicate advisories across manifests")
        out.append("")
        for (ghsa, pkg), group in sorted(triplicated.items()):
            live = sum(1 for d in group if d["manifest_exists"])
            out.append(f"- `{ghsa}` / `{pkg}` raised {len(group)}x "
                       f"({live} real, {len(group) - live} phantom) -- one issue, "
                       f"{len(group)} rows")
        out.append("")

    open_cs = [c for c in cs if c.get("state") == "open"]
    if open_cs:
        out.append("## Code scanning")
        out.append("")
        out.append("| # | Sev | Rule | Location |")
        out.append("|---|---|---|---|")
        for c in sorted(open_cs, key=lambda x: (x.get("rule", {}).get("severity") != "error",
                                                x.get("number", 0))):
            loc = (c.get("most_recent_instance") or {}).get("location") or {}
            rule = c.get("rule") or {}
            where = f"`{loc.get('path', '?')}`:{loc.get('start_line', '?')}"
            out.append(f"| {c.get('number')} | {rule.get('severity')} "
                       f"| `{rule.get('id')}` | {where} |")
        out.append("")
        out.append("Dismiss a false positive with:")
        out.append("")
        out.append("```bash")
        errs = [c for c in open_cs if (c.get("rule") or {}).get("severity") == "error"]
        c0 = errs[0] if errs else open_cs[0]
        out.append(f"gh api --method PATCH repos/{repo}/code-scanning/alerts/{c0.get('number')} \\")
        out.append("  -f state=dismissed -f dismissed_reason='false positive' \\")
        out.append("  -f dismissed_comment='<evidence: e.g. argv-list form, no shell=True>'")
        out.append("```")
        out.append("")
        out.append("Valid `dismissed_reason` values are exactly: "
                   "`false positive`, `won't fix`, `used in tests`, `mitigated`.")
        out.append("")
    else:
        out.append("## Code scanning\n\nNo open alerts.\n")

    return "\n".join(out)


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Triage Dependabot and code-scanning alerts (read-only).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    ap.add_argument("--repo", help="owner/name. Defaults to origin remote.")
    ap.add_argument("--base", default="master", help="base branch (default: master)")
    ap.add_argument("--json", action="store_true", help="emit JSON instead of Markdown")
    ap.add_argument("--fetch", action="store_true", help="git fetch --prune first")
    args = ap.parse_args()

    repo = resolve_repo(args.repo)
    if args.fetch:
        run(["git", "fetch", "--prune", "origin"])

    # Phantom classification depends on git. Outside a work tree every
    # `git cat-file -e` fails, which would mark EVERY alert as phantom -- the
    # exact over-dismissal this script exists to prevent.
    code, _, _ = run(["git", "rev-parse", "--verify", "--quiet", f"origin/{args.base}"])
    if code != 0:
        sys.stderr.write(
            f"origin/{args.base} not resolvable. Run from inside the repository "
            f"(or pass --fetch). Refusing to classify: without git every manifest "
            f"check would report 'absent' and all alerts would look like phantoms.\n"
        )
        raise SystemExit(1)

    dep = classify_dependabot(fetch_dependabot(repo), f"origin/{args.base}")
    cs = fetch_code_scanning(repo)

    if args.json:
        print(json.dumps({"repo": repo, "base": args.base,
                          "dependabot": dep, "code_scanning": cs}, indent=2))
    else:
        print(render(dep, cs, repo, args.base))


if __name__ == "__main__":
    main()