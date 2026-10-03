#!/usr/bin/env bash
# detect_empty_commits.sh: Detect empty commits in a commit range (e.g. PR branch above base).
# Usage: detect_empty_commits.sh <base-ref> <head-ref>
# Example: detect_empty_commits.sh origin/main origin/pr-123

set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <base-ref> <head-ref>" >&2
  exit 1
fi

BASE="$1"
HEAD="$2"

mb=$(git merge-base "$BASE" "$HEAD")
empty_count=0

for c in $(git rev-list "$mb..$HEAD"); do
  s=$(git show --shortstat --format='' "$c" | tr -d ' \n')
  if [ -z "$s" ]; then
    printf '%s [EMPTY]\n' "$c"
    empty_count=$((empty_count + 1))
  else
    printf '%s [%s]\n' "$c" "$s"
  fi
done

if [ "$empty_count" -ge 2 ]; then
  echo "WARNING: Detected $empty_count empty commit(s). Branch is wedged." >&2
  exit 2
elif [ "$empty_count" -gt 0 ]; then
  echo "WARNING: Detected $empty_count empty commit(s)." >&2
  exit 1
fi
