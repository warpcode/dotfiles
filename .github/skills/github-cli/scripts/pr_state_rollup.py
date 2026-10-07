#!/usr/bin/env python3
"""Roll up pull request state, review decision, mergeability and CI checks.

One `gh pr list` call replaces dozens of `gh pr view` / `gh pr checks` /
sleep-poll invocations, and returns a single dense Markdown table.

Usage
-----
  pr_state_rollup.py --repo owner/name                     # every open PR
  pr_state_rollup.py --repo owner/name 148 152 153        # specific PRs
  pr_state_rollup.py --repo owner/name --all-states       # include closed/merged
  pr_state_rollup.py --repo owner/name --wait --timeout 900
  pr_state_rollup.py --repo owner/name --expect-sha 153=787c668
  pr_state_rollup.py --repo owner/name --json

Why the flags exist
-------------------
`--wait`      polls internally instead of the agent sleeping in a bash loop.
`--expect-sha` detects a bot or collaborator pushing mid-audit. Reviews anchored
to a stale head are invalid, and a bot amending without warning is routine.

Exit codes: 0 all clear, 1 usage/fetch error, 2 at least one PR needs attention
(conflicting, checks failing, or head SHA drifted from --expect-sha).
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time

FIELDS = ",".join([
    "number", "title", "state", "isDraft", "author", "headRefName", "headRefOid",
    "baseRefName", "reviewDecision", "mergeable", "mergeStateStatus",
    "statusCheckRollup", "createdAt", "updatedAt", "additions", "deletions",
    "changedFiles",
])

OK, WARN, FAIL, PENDING, NONE = "pass", "warn", "fail", "pending", "-"

# Pre-allocated sets for O(1) status check lookup
SUCCESS_STATES = {"success", "neutral", "skipped"}
FAIL_STATES = {"failure", "error", "timed_out", "cancelled", "action_required", "startup_failure"}
PENDING_STATES = {"pending", "queued", "in_progress", "waiting", "requested"}


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


def fetch(repo: str, state: str) -> list[dict]:
    code, out, err = run(
        ["gh", "pr", "list", "--repo", repo, "--state", state,
         "--limit", "200", "--json", FIELDS]
    )
    if code != 0:
        sys.stderr.write(f"gh pr list failed:\n{err}\n")
        raise SystemExit(1)
    return json.loads(out or "[]")


def rollup_status(pr: dict) -> tuple[str, str, str]:
    """(overall, failing, pending) from statusCheckRollup."""
    checks = pr.get("statusCheckRollup") or []
    if not checks:
        return NONE, "", ""
    failing, pending = [], []
    for c in checks:
        state = c.get("conclusion") or c.get("state") or c.get("status") or ""
        low = state.lower()
        if low in SUCCESS_STATES:
            continue
        name = c.get("name") or c.get("context") or "?"
        if low in FAIL_STATES:
            failing.append(name)
        elif low in PENDING_STATES:
            pending.append(name)
    if failing:
        return FAIL, ",".join(failing), ""
    if pending:
        return PENDING, "", ",".join(pending)
    return OK, "", ""


def attention_reasons(pr: dict, expect: dict[int, str], overall: str | None = None, failing: str | None = None) -> list[str]:
    reasons = []
    if (pr.get("mergeable") or "").upper() == "CONFLICTING":
        reasons.append("CONFLICTING")
    if overall is None or failing is None:
        overall, failing, _ = rollup_status(pr)
    if overall == FAIL:
        reasons.append(f"checks failing: {failing}")
    if pr.get("isDraft"):
        reasons.append("draft")
    want = expect.get(pr["number"])
    if want and (pr.get("headRefOid") or "")[:len(want)] != want:
        reasons.append(f"HEAD DRIFT expected {want} got {(pr.get('headRefOid') or '')[:7]}")
    return reasons


def render(prs: list[dict], expect: dict[int, str], repo: str) -> tuple[str, bool]:
    out = [f"# PR state -- {repo}", ""]
    out.append("| # | State | Draft | Head | Review | Merge | Checks | +/- | Files | Flags |")
    out.append("|---|---|---|---|---|---|---|---|---|---|")
    bad = False
    for pr in sorted(prs, key=lambda p: p["number"]):
        overall, failing, pending = rollup_status(pr)
        if overall == FAIL:
            checks = f"FAIL {failing}"
        elif overall == PENDING:
            checks = f"pending {pending}"
        else:
            checks = "pass" if overall == OK else "-"
        flags = attention_reasons(pr, expect, overall, failing)
        if flags:
            bad = True
        sha = (pr.get("headRefOid") or "")[:7]
        out.append(
            f"| #{pr['number']} | {(pr.get('state') or '').lower()} "
            f"| {'yes' if pr.get('isDraft') else ''} "
            f"| `{sha}` `{(pr.get('headRefName') or '')[:28]}` "
            f"| {pr.get('reviewDecision') or '-'} "
            f"| {pr.get('mergeStateStatus') or pr.get('mergeable') or '-'} "
            f"| {checks} "
            f"| +{pr.get('additions', 0)}/-{pr.get('deletions', 0)} "
            f"| {pr.get('changedFiles', '?')} "
            f"| {'; '.join(flags)} |"
        )
    out.append("")
    if expect:
        out.append("`--expect-sha` set: head drift is reported in Flags.")
        out.append("")
    return "\n".join(out), bad


def main() -> None:
    ap = argparse.ArgumentParser(
        description="One-call pull request state / review / CI rollup.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    ap.add_argument("prs", nargs="*", type=int, help="PR numbers (default: all open)")
    ap.add_argument("--repo", help="owner/name. Defaults to origin remote.")
    ap.add_argument("--all-states", action="store_true", help="include closed/merged")
    ap.add_argument("--wait", action="store_true", help="poll until no checks pending")
    ap.add_argument("--timeout", type=int, default=900, help="--wait ceiling seconds")
    ap.add_argument("--interval", type=int, default=20, help="--wait poll seconds")
    ap.add_argument("--expect-sha", action="append", default=[], metavar="N=SHA",
                    help="flag head drift, e.g. --expect-sha 153=787c668")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    repo = resolve_repo(args.repo)
    expect: dict[int, str] = {}
    for item in args.expect_sha:
        if "=" not in item:
            sys.stderr.write(f"--expect-sha needs N=SHA, got {item!r}\n")
            raise SystemExit(1)
        n, sha = item.split("=", 1)
        expect[int(n)] = sha.strip()

    state = "all" if args.all_states else "open"
    deadline = time.time() + args.timeout
    prs: list[dict] = []
    while True:
        prs = fetch(repo, state)
        if args.prs:
            wanted = set(args.prs)
            prs = [p for p in prs if p["number"] in wanted]
            missing = wanted - {p["number"] for p in prs}
            if missing and not args.all_states:
                sys.stderr.write(
                    f"not found in state '{state}': "
                    f"{', '.join('#' + str(m) for m in sorted(missing))}\n")
        if not args.wait:
            break
        pending = [p["number"] for p in prs if rollup_status(p)[0] == PENDING]
        if not pending or time.time() > deadline:
            if pending:
                sys.stderr.write(
                    f"--wait timed out with checks still pending on "
                    f"{', '.join('#' + str(n) for n in pending)}\n")
            break
        time.sleep(args.interval)

    bad = False
    if args.json:
        payload = []
        for p in prs:
            overall, failing, pending = rollup_status(p)
            flags = attention_reasons(p, expect, overall, failing)
            if flags:
                bad = True
            payload.append({
                "number": p["number"], "state": p.get("state"),
                "headRefName": p.get("headRefName"),
                "headRefOid": p.get("headRefOid"),
                "reviewDecision": p.get("reviewDecision"),
                "mergeable": p.get("mergeable"),
                "mergeStateStatus": p.get("mergeStateStatus"),
                "checks": overall, "failing": failing, "pending": pending,
                "flags": flags,
            })
        print(json.dumps({"repo": repo, "prs": payload}, indent=2))
    else:
        text, bad = render(prs, expect, repo)
        print(text)
        if bad:
            print("attention needed: conflicting, failing checks, or head drift "
                  "(see Flags column)")
    raise SystemExit(2 if bad else 0)


if __name__ == "__main__":
    main()