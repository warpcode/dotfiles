#!/usr/bin/env bash
# Fail a PR before it is created if the head branch is not based on the target base.
#
# Why this exists: a branch cut from another feature branch inherits its commits,
# so the resulting PR conflicts and has to be cherry-picked onto the base and
# reopened. Observed 2026-10-10 on warpcode/dotfiles: a branch created from
# `bolt/registry-reply-nofork` instead of `master` carried 2 unrelated commits,
# producing a CONFLICTING PR that had to be cherry-picked into a second PR while
# the first was closed. Ancestry is cheap to verify before `gh pr create` and
# expensive to discover after, via `mergeable=CONFLICTING`.
#
# Usage:
#   branch_base_check.sh [--base REF] [--head REF] [--json]
#
#   --base REF   base ref to check ancestry against  [default: origin/master]
#   --head REF   head ref                            [default: HEAD]
#   --json       machine-readable output
#   -h, --help   show this help
#
# Exit codes: 0 = head descends from base; 1 = not based on base; 2 = bad usage.
# Non-interactive, read-only (fetches, but never mutates refs), idempotent.

set -euo pipefail

BASE="origin/master"
HEAD_REF="HEAD"
JSON=0

while [ $# -gt 0 ]; do
  case "$1" in
    --base) [ $# -ge 2 ] || { echo "--base requires a value" >&2; exit 2; }; BASE="$2"; shift 2 ;;
    --head) [ $# -ge 2 ] || { echo "--head requires a value" >&2; exit 2; }; HEAD_REF="$2"; shift 2 ;;
    --json) JSON=1; shift ;;
    -h|--help) sed -n '2,22p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

if ! git rev-parse --verify -q "$BASE" >/dev/null; then
  echo "base ref not found: $BASE (fetch it first, or pass --base)" >&2
  exit 1
fi
if ! git rev-parse --verify -q "$HEAD_REF" >/dev/null; then
  echo "head ref not found: $HEAD_REF" >&2
  exit 1
fi

# Refresh the remote-tracking ref so ancestry reflects the current base, but never
# move a local branch: a check must not be able to rewrite history.
git fetch -q "$(git rev-parse --abbrev-ref --symbolic-full-name "$BASE" 2>/dev/null || echo origin)" \
  "${BASE#origin/}" 2>/dev/null || true

ANCESTOR=false
if git merge-base --is-ancestor "$BASE" "$HEAD_REF" 2>/dev/null; then
  ANCESTOR=true
fi

AHEAD=$(git rev-list --count "$BASE..$HEAD_REF" 2>/dev/null || echo 0)
BEHIND=$(git rev-list --count "$HEAD_REF..$BASE" 2>/dev/null || echo 0)
# Commits on head that are NOT on base -- the actual contamination when ancestry fails.
FOREIGN=$(git rev-list --count "$BASE..$HEAD_REF" 2>/dev/null || echo 0)

if [ "$JSON" -eq 1 ]; then
  printf '{"base":"%s","head":"%s","is_ancestor":%s,"ahead":%s,"behind":%s,"foreign_commits":%s}\n' \
    "$BASE" "$HEAD_REF" "$ANCESTOR" "$AHEAD" "$BEHIND" "$FOREIGN"
  [ "$ANCESTOR" = true ] || exit 1
else
  echo "== base   : $BASE"
  echo "== head   : $HEAD_REF"
  echo "== ahead  : $AHEAD   behind: $BEHIND"
  if [ "$ANCESTOR" = true ]; then
    echo "PASS: $HEAD_REF descends from $BASE"
  else
    echo "FAIL: $HEAD_REF is not based on $BASE." >&2
    echo "      Cherry-pick onto $BASE, or recreate:" >&2
    echo "        git checkout -b <new> $BASE && git cherry-pick <sha>..." >&2
  fi
fi

[ "$ANCESTOR" = true ]