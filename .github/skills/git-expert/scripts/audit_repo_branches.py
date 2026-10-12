#!/usr/bin/env python3
"""Classify git branches as keep / delete / review before pruning a remote.

Answers "which remote branches are obsolete?" without deleting anything. Read-only.

Why this exists
---------------
`git branch -d` and `git merge-base --is-ancestor` both give wrong answers on a
repo that squash-merges:

  * squash merges create a NEW commit, so the branch tip is never an ancestor of
    the base branch and already-merged branches look unmerged;
  * `git cherry` compares patch-ids, and a squash of three commits matches none
    of the three originals, so it also reports landed work as outstanding.

The only reliable signal is content: compare the blob hash of every file the
branch touches against the base branch. This script does that, and additionally
detects sibling branches that conflict with each other (only one can merge).

Classification
--------------
  KEEP          open pull request -- the branch is required to keep it alive
  DELETE_MERGED pull request merged; work is in the base branch
  DELETE_STALE  pull request closed and every changed file is already on base
  SUPERSEDED    pull request closed, unique work exists, but a sibling branch
                covers the same files and conflicts (recommend the sibling)
  REVIEW_STALE  pull request closed, unlanded work remains, branch is far behind
                base -- needs a human decision: the work is real but unmergeable
                without porting. NEVER auto-delete.
  REVIEW        pull request closed, unlanded work remains and is recent enough
                to still be actionable. NEVER auto-delete.

Usage
-----
  audit_repo_branches.py --repo owner/name
  audit_repo_branches.py --repo owner/name --json
  audit_repo_branches.py --repo owner/name --base main --include-open

Requires: git, gh (authenticated). Exits 0 even when REVIEW rows exist; exits 1
only on a hard failure.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from collections import defaultdict

STALE_BEHIND = 30  # commits behind base before a closed branch is called stale


def run(cmd: list[str], check: bool = False) -> tuple[int, str, str]:
    p = subprocess.run(cmd, capture_output=True, text=True)
    if check and p.returncode != 0:
        sys.stderr.write(f"command failed: {' '.join(cmd)}\n{p.stderr}")
        raise SystemExit(1)
    return p.returncode, p.stdout, p.stderr


def resolve_repo(explicit: str | None) -> str:
    """Never guess owner/repo from the directory name or a remembered value."""
    if explicit:
        return explicit
    code, out, _ = run(["git", "remote", "get-url", "origin"])
    if code != 0 or not out.strip():
        sys.stderr.write("cannot resolve origin remote; pass --repo owner/name\n")
        raise SystemExit(1)
    url = out.strip()
    m = re.search(r"github\.com[:/]([^/]+)/([^/\s]+?)(?:\.git)?$", url)
    if not m:
        sys.stderr.write(f"cannot parse owner/repo from remote URL: {url}\n")
        raise SystemExit(1)
    return f"{m.group(1)}/{m.group(2)}"


def fetch_pr_map(repo: str) -> dict[str, dict]:
    """branch headRefName -> {number, state, mergedAt, title}. Last wins."""
    code, out, _ = run(
        [
            "gh", "pr", "list", "--repo", repo, "--state", "all",
            "--limit", "500", "--json", "number,headRefName,state,mergedAt,title",
        ]
    )
    if code != 0:
        sys.stderr.write(f"gh pr list failed for {repo}\n")
        raise SystemExit(1)
    outmap: dict[str, dict] = {}
    for pr in json.loads(out):
        if pr.get("headRefName"):
            outmap[pr["headRefName"]] = pr
    return outmap


def list_branches() -> list[str]:
    code, out, _ = run(["git", "for-each-ref", "--format=%(refname:short)",
                        "refs/remotes/origin"])
    if code != 0:
        raise SystemExit(1)
    names = []
    for line in out.splitlines():
        line = line.strip()
        if not line or line.endswith("/HEAD") or line == "origin/master" or line == "origin/main":
            continue
        names.append(line[len("origin/"):] if line.startswith("origin/") else line)
    return sorted(names)


def rev(ref: str) -> str | None:
    code, out, _ = run(["git", "rev-parse", "--verify", "--quiet", ref])
    return out.strip() if code == 0 else None


def merge_base(a: str, b: str) -> str | None:
    code, out, _ = run(["git", "merge-base", a, b])
    return out.strip() if code == 0 else None


def blob(ref: str, path: str) -> str | None:
    code, out, _ = run(["git", "cat-file", "-e", f"{ref}:{path}"])
    if code != 0:
        return None
    code2, out2, _ = run(["git", "rev-parse", f"{ref}:{path}"])
    return out2.strip() if code2 == 0 else None


def changed_files(base: str, tip: str, mb: str) -> list[str]:
    code, out, _ = run(["git", "diff", "--name-only", mb, tip])
    return out.split() if code == 0 else []


def conflict_markers(a: str, b: str) -> int:
    mb = merge_base(a, b)
    if not mb:
        return 0
    _, out, _ = run(["git", "merge-tree", mb, a, b])
    return out.count("<<<<<<<")


def analyse(branch: str, base: str, prmap: dict[str, dict]) -> dict:
    tip = rev(f"origin/{branch}")
    base_ref = f"origin/{base}"
    row: dict = {"branch": branch, "pr": None, "behind": 0, "ahead": 0,
                 "files": 0, "landed": False, "unique_files": []}
    if not tip:
        row["verdict"] = "REVIEW"
        row["reason"] = "branch ref missing locally; run git fetch --prune"
        return row

    pr = prmap.get(branch)
    row["pr"] = pr["number"] if pr else None
    row["pr_state"] = (pr["state"].upper() if pr else None)

    mb = merge_base(base_ref, tip)
    if not mb:
        row["verdict"] = "REVIEW"
        row["reason"] = f"no merge base with origin/{base}"
        return row

    _, out, _ = run(["git", "rev-list", "--left-right", "--count", f"{tip}...{base_ref}"])
    parts = out.split()
    if len(parts) == 2:
        row["ahead"], row["behind"] = int(parts[0]), int(parts[1])

    files = changed_files(base_ref, tip, mb)
    row["files"] = len(files)
    unique = []
    for f in files:
        if blob(base_ref, f) != blob(tip, f):
            unique.append(f)
    row["unique_files"] = unique
    row["landed"] = not unique

    state = row["pr_state"]
    if state == "OPEN":
        row["verdict"] = "KEEP"
        row["reason"] = "open pull request"
    elif state == "MERGED":
        row["verdict"] = "DELETE_MERGED"
        row["reason"] = "pull request merged" + (" (content already on base)" if row["landed"] else "")
    elif state == "CLOSED":
        if row["landed"]:
            row["verdict"] = "DELETE_STALE"
            row["reason"] = f"closed; all {len(files)} changed files already on base"
        elif row["behind"] >= STALE_BEHIND:
            row["verdict"] = "REVIEW_STALE"
            row["reason"] = (f"closed; {row['behind']} commits behind base and "
                             f"{len(unique)} file(s) still differ -- unlanded work, "
                             "but too stale to merge as-is")
        else:
            row["verdict"] = "REVIEW"
            row["reason"] = f"closed; {len(unique)} file(s) differ from base -- unlanded work"
    else:
        row["verdict"] = "REVIEW"
        row["reason"] = "no pull request found for this branch"
    return row


def find_siblings(rows: list[dict], base: str) -> list[dict]:
    """Closed branches whose unique files overlap an open/merged sibling's."""
    live = [r for r in rows if r["verdict"] in ("KEEP", "DELETE_MERGED") and r["unique_files"]]
    pairs = []
    for dead in [r for r in rows if r["verdict"] in ("REVIEW", "DELETE_STALE")]:
        if not dead["unique_files"]:
            continue
        for live_row in live:
            shared = set(dead["unique_files"]) & set(live_row["unique_files"])
            if not shared:
                continue
            a, b = f"origin/{dead['branch']}", f"origin/{live_row['branch']}"
            markers = conflict_markers(a, b)
            pairs.append({
                "superseded": dead["branch"], "superseded_pr": dead["pr"],
                "by": live_row["branch"], "by_pr": live_row["pr"],
                "shared_files": sorted(shared), "conflict_markers": markers,
            })
    return pairs


def render(rows: list[dict], pairs: list[dict], base: str, repo: str) -> str:
    order = {"DELETE_MERGED": 0, "DELETE_STALE": 1, "SUPERSEDED": 2,
             "REVIEW": 3, "REVIEW_STALE": 4, "KEEP": 5}
    rows = sorted(rows, key=lambda r: (order.get(r["verdict"], 9), r["branch"]))
    by_verdict: dict[str, list[dict]] = defaultdict(list)
    for r in rows:
        by_verdict[r["verdict"]].append(r)

    out = [f"# Branch audit -- {repo} (base `origin/{base}`)", ""]
    out.append("Content comparison against the base branch, not `--is-ancestor` or "
               "`git cherry`: both misreport squash-merged work as unmerged.")
    out.append("")
    out.append("| Verdict | Branches | PRs |")
    out.append("|---|---|---|")
    for v in ("DELETE_MERGED", "DELETE_STALE", "SUPERSEDED", "REVIEW",
              "REVIEW_STALE", "KEEP"):
        n = len(by_verdict.get(v, []))
        prs = sorted({r["pr"] for r in by_verdict.get(v, []) if r["pr"]})
        if n:
            out.append(f"| `{v}` | {n} | {', '.join(f'#{p}' for p in prs) or '--'} |")
    out.append("")

    deletable = by_verdict.get("DELETE_MERGED", []) + by_verdict.get("DELETE_STALE", [])
    if deletable:
        out.append("## Safe to delete")
        out.append("")
        for r in deletable:
            pr = f"#{r['pr']}" if r["pr"] else "no PR"
            out.append(f"- `{r['branch']}` ({pr}) -- {r['reason']}")
        out.append("")
        out.append("```bash")
        out.append("git push origin --delete \\\n  " + " \\\n  ".join(
            r["branch"] for r in deletable))
        out.append("```")
        out.append("")

    needs_decision = by_verdict.get("REVIEW", []) + by_verdict.get("REVIEW_STALE", [])
    if needs_decision:
        out.append("## Needs a decision -- do NOT auto-delete")
        out.append("")
        out.append("These hold work that never landed. `REVIEW_STALE` branches are "
                   "too far behind base to merge directly; the usual resolution is to "
                   "port the coverage forward and only then delete the branch.")
        out.append("")
        for r in needs_decision:
            pr = f"#{r['pr']}" if r["pr"] else "no PR"
            files_label = ", ".join(f"`{f}`" for f in r["unique_files"][:3]) or "--"
            more = f" (+{len(r['unique_files']) - 3} more)" if len(r["unique_files"]) > 3 else ""
            out.append(f"- `{r['branch']}` ({pr}, `{r['verdict']}`) -- {r['reason']}")
            out.append(f"  - unlanded in: {files_label}{more}")
        out.append("")

    if pairs:
        out.append("## Sibling conflicts -- only one of each pair can merge")
        out.append("")
        out.append("| Closed / older | Competing | Shared files | Conflict markers |")
        out.append("|---|---|---|---|")
        for p in sorted(pairs, key=lambda x: -x["conflict_markers"]):
            out.append(f"| `{p['superseded']}` (#{p['superseded_pr']}) "
                       f"| `{p['by']}` (#{p['by_pr']}) "
                       f"| {len(p['shared_files'])} "
                       f"| {p['conflict_markers']} |")
        out.append("")
        out.append("A non-zero marker count means merging both is impossible; the "
                   "second to land partially reverts the first.")
        out.append("")

    if by_verdict.get("KEEP"):
        out.append(f"## Keep ({len(by_verdict['KEEP'])} open PRs)")
        out.append("")
        for r in by_verdict["KEEP"]:
            out.append(f"- `{r['branch']}` (#{r['pr']})")
        out.append("")
    return "\n".join(out)


def main() -> None:
    ap = argparse.ArgumentParser(
        description="Classify remote branches as keep/delete/review (read-only).",
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
    if not rev(f"origin/{args.base}"):
        sys.stderr.write(f"origin/{args.base} not found; pass --base or --fetch\n")
        raise SystemExit(1)

    prmap = fetch_pr_map(repo)
    rows = [analyse(b, args.base, prmap) for b in list_branches()]
    pairs = find_siblings(rows, args.base)

    for r in rows:
        if r["verdict"] == "REVIEW" and any(
            p["superseded"] == r["branch"] and p["conflict_markers"] > 0 for p in pairs
        ):
            r["verdict"] = "SUPERSEDED"

    if args.json:
        print(json.dumps({"repo": repo, "base": args.base, "branches": rows,
                          "sibling_conflicts": pairs}, indent=2))
    else:
        print(render(rows, pairs, args.base, repo))


if __name__ == "__main__":
    main()