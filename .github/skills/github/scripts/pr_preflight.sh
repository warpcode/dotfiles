#!/usr/bin/env bash
# Capture a PR's diff and head ref from ONE fetch, and assert the head has not
# moved since the audit started.
#
# Why this exists: verify_review_anchors.sh cross-checks every anchor against a
# local ref, while the diff comes from `gh pr diff`. If those two come from
# different moments, the verifier prints line text that no longer matches --
# which reads as a valid cross-check while proving nothing. Bot PRs amend
# without warning (observed 2026-10-01 on warpcode/dotfiles#143: one of four
# drafted comments became obsolete and every anchor after the first hunk
# shifted). This script makes the pair unfalsifiable by construction.
#
# Usage:
#   pr_preflight.sh --repo o/r --pr N [--out DIR] [--expect-sha SHA]
#
#   --repo OWNER/NAME  required; never guessed from the directory name
#   --pr N             required
#   --out DIR          output directory        [default: /tmp/opencode/pr<N>]
#   --expect-sha SHA   fail unless the fetched head equals this commit
#   --base REF         base branch to diff against  [default: origin/main, then
#                      origin/master]
#   --json             print the manifest as JSON instead of Markdown
#   -h, --help         show this help
#
# Output (in --out):
#   manifest.json   {repo, pr, head_sha, base_ref, diff, files, changed}
#   pr<N>.diff      the diff, captured in the same fetch as the ref
#
# Prints a Markdown summary: head SHA, whether it moved, files changed, and the
# exact `verify_review_anchors.sh` / `submit_review.sh` invocations to run next.
#
# Exit codes:
#   0  preflight captured (and matched --expect-sha, if given)
#   1  usage error, or the PR could not be fetched
#   3  the head moved away from --expect-sha -- re-run the audit, do not submit

set -euo pipefail

repo=""
pr=""
out=""
expect_sha=""
base=""
json=0

die() { printf 'pr_preflight: %s\n' "$*" >&2; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)        repo="${2:-}"; shift 2 ;;
    --pr)          pr="${2:-}"; shift 2 ;;
    --out)         out="${2:-}"; shift 2 ;;
    --expect-sha)  expect_sha="${2:-}"; shift 2 ;;
    --base)        base="${2:-}"; shift 2 ;;
    --json)        json=1; shift ;;
    -h|--help)     sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)             die "unknown argument: $1" ;;
  esac
done

[[ -n "$repo" ]] || die "--repo is required"
[[ -n "$pr"   ]] || die "--pr is required"
command -v gh >/dev/null 2>&1 || die "gh is not installed"

[[ -n "$out" ]] || out="/tmp/opencode/pr${pr}"
mkdir -p "$out"

ref="origin/pr-${pr}"
diff_file="$out/pr${pr}.diff"
manifest="$out/manifest.json"

# --- the single fetch that both outputs are derived from ---------------------
# Fully qualify the destination ref. A short destination like `origin/pr-N`
# makes git create a LOCAL BRANCH refs/heads/origin/pr-N rather than the
# remote-tracking ref, and once the real refs/remotes/origin/pr-N also exists
# (any documented fetch creates it) `origin/pr-N` is ambiguous -- so
# `git rev-parse "$ref"` and every `--head $ref` cross-check downstream fail.
git fetch -q origin "+refs/pull/${pr}/head:refs/remotes/${ref}" --force \
  || die "could not fetch refs/pull/${pr}/head into $ref"

head_sha="$(git rev-parse "$ref" 2>/dev/null || true)"
[[ -n "$head_sha" ]] || die "$ref did not resolve to a commit"

# `gh pr diff` is the canonical merge-base-relative diff, and it is what the
# anchor rules are defined against. Captured here, next to the fetch, so the
# two cannot drift.
gh pr diff "$pr" --repo "$repo" > "$diff_file" 2>&1 \
  || die "could not fetch diff for #$pr"
[[ -s "$diff_file" ]] || die "diff for #$pr is empty"

# --- has the head moved since the audit started? ------------------------------
moved=0
if [[ -n "$expect_sha" && "$head_sha" != "$expect_sha" ]]; then
  moved=1
fi

if [[ -z "$base" ]]; then
  for candidate in origin/main origin/master; do
    if git rev-parse --verify -q "$candidate" >/dev/null; then base="$candidate"; break; fi
  done
  base="${base:-origin/main}"
fi

files="$(git diff --name-only "$(git merge-base "$base" "$ref")" "$ref" 2>/dev/null || true)"
file_count=0
[[ -n "$files" ]] && file_count="$(printf '%s\n' "$files" | wc -l | tr -d ' ')"

jq -n \
  --arg repo "$repo" \
  --arg pr "$pr" \
  --arg head_sha "$head_sha" \
  --arg head_ref "$ref" \
  --arg base_ref "$base" \
  --arg diff "$diff_file" \
  --argjson files "$file_count" \
  '{repo: $repo, pr: ($pr | tonumber), head_sha: $head_sha, head_ref: $head_ref,
    base_ref: $base_ref, diff: $diff, files: $files}' > "$manifest"

if [[ "$json" -eq 1 ]]; then
  cat "$manifest"
else
  echo "== repo       : $repo"
  echo "== pr         : #$pr"
  echo "== head       : $head_sha  ($ref)"
  echo "== base       : $base"
  echo "== diff       : $diff_file"
  echo "== files      : $file_count changed vs $(git merge-base "$base" "$ref" 2>/dev/null | cut -c1-12)"
  echo
  if [[ "$moved" -eq 1 ]]; then
    echo "!! HEAD MOVED: expected $expect_sha, fetched $head_sha"
    echo "   Re-run the audit against $head_sha before drafting or submitting."
    echo "   Existing findings may already be addressed by the amendment."
  elif [[ -n "$expect_sha" ]]; then
    echo "head unchanged since capture ($head_sha)"
  fi
  echo
  echo "-- next --"
  echo "  verify anchors:"
  echo "    bash verify_review_anchors.sh --diff $diff_file --payload <payload.json> --head $ref"
  echo "  submit (re-fetches and re-verifies in one call, so prefer this):"
  echo "    bash submit_review.sh --spec <findings.json> --repo $repo --pr $pr"
fi

if [[ "$moved" -eq 1 ]]; then
  exit 3
fi