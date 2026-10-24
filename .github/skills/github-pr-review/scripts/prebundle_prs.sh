#!/usr/bin/env bash
# Pre-generate PR audit bundles for many PRs in one call, from the PARENT session.
#
# Subagents cannot obtain an interactive `BypassSandbox` approval, so any reviewer
# that has to run `pr_audit_bundle.sh` itself blocks on a permission prompt (10 of
# 29 reviewers did on 2026-10-18). Run this once BEFORE `invoke_subagent` and tell
# each reviewer: "bundle is in <out-root>/pr<N>; read it with view_file; run no gh
# or network commands".
#
# One `gh pr list` call supplies every open PR's head SHA, so bundles whose head
# has not moved since the last run are skipped (no per-PR metadata round-trip).
#
# Usage:
#   prebundle_prs.sh --repo owner/name (--prs 1,2,3 | --all-open) [options]
#
#   --repo OWNER/NAME  repository (combined form)            [required]
#   --prs LIST         comma-separated PR numbers
#   --all-open         bundle every open PR (mutually exclusive with --prs)
#   --out-root DIR     parent directory for pr<N> bundles    [default: /tmp]
#   --jobs N           parallel bundle jobs                  [default: 4]
#   --force            ignore the head-SHA cache and rebuild
#
# Output: one status line per PR. Exit 0 = all bundled or cached, 1 = usage error
# or at least one bundle failed (see <out-root>/pr<N>.log).

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(dirname -- "$(dirname -- "$SCRIPT_DIR")")"
BUNDLE="$SKILLS_DIR/github-cli/scripts/pr_audit_bundle.sh"

die() { printf 'prebundle_prs: %s\n' "$*" >&2; exit 1; }

REPO=""; PRS=""; ALL_OPEN=0; OUT_ROOT="/tmp"; JOBS=4; FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)     REPO="${2:-}";     shift 2 ;;
    --prs)      PRS="${2:-}";      shift 2 ;;
    --all-open) ALL_OPEN=1;        shift ;;
    --out-root) OUT_ROOT="${2:-}"; shift 2 ;;
    --jobs)     JOBS="${2:-}";     shift 2 ;;
    --force)    FORCE=1;           shift ;;
    -h|--help)  sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$REPO" ]] || die "--repo owner/name is required"
[[ "$REPO" == */* ]] || die "--repo must be owner/name"
[[ "$JOBS" =~ ^[0-9]+$ && "$JOBS" -ge 1 ]] || die "--jobs must be a positive integer"
if [[ "$ALL_OPEN" -eq 1 && -n "$PRS" ]]; then die "--prs and --all-open are mutually exclusive"; fi
if [[ "$ALL_OPEN" -eq 0 && -z "$PRS" ]]; then die "pass --prs LIST or --all-open"; fi
[[ -f "$BUNDLE" ]] || die "missing $BUNDLE"

mkdir -p "$OUT_ROOT"

# One call: head SHA for every open PR (used for the cache and for --all-open).
declare -A HEAD_SHA=()
while read -r num sha; do
  [[ -n "$num" ]] && HEAD_SHA["$num"]="$sha"
done < <(gh pr list --repo "$REPO" --state open --limit 200 \
  --json number,headRefOid --jq '.[] | "\(.number) \(.headRefOid)"')

if [[ "$ALL_OPEN" -eq 1 ]]; then
  PR_LIST=("${!HEAD_SHA[@]}")
else
  IFS=',' read -r -a PR_LIST <<<"$PRS"
fi
[[ ${#PR_LIST[@]} -gt 0 ]] || die "no pull requests to bundle"
for n in "${PR_LIST[@]}"; do
  [[ "$n" =~ ^[0-9]+$ ]] || die "invalid PR number: $n"
done

bundle_one() {
  local n="$1" sha="${HEAD_SHA[$1]:-}" dir="$OUT_ROOT/pr$1"
  if [[ "$FORCE" -eq 0 && -n "$sha" && -f "$dir/.head_sha" \
        && "$(cat "$dir/.head_sha")" == "$sha" ]]; then
    echo "cached" >"$OUT_ROOT/.prebundle_status.$n"
    return 0
  fi
  if bash "$BUNDLE" --repo "$REPO" --pr "$n" --out "$dir" >"$OUT_ROOT/pr$n.log" 2>&1; then
    [[ -n "$sha" ]] && printf '%s\n' "$sha" >"$dir/.head_sha"
    echo "ok" >"$OUT_ROOT/.prebundle_status.$n"
  else
    echo "FAILED" >"$OUT_ROOT/.prebundle_status.$n"
  fi
}

running=0
for n in "${PR_LIST[@]}"; do
  rm -f "$OUT_ROOT/.prebundle_status.$n"
  bundle_one "$n" &
  running=$((running + 1))
  if [[ "$running" -ge "$JOBS" ]]; then
    wait -n || true
    running=$((running - 1))
  fi
done
wait || true

failed=0
for n in $(printf '%s\n' "${PR_LIST[@]}" | sort -n); do
  status="$(cat "$OUT_ROOT/.prebundle_status.$n" 2>/dev/null || echo FAILED)"
  [[ "$status" == "FAILED" ]] && failed=1
  printf '#%s\t%s\t%s\n' "$n" "$status" "$OUT_ROOT/pr$n"
  rm -f "$OUT_ROOT/.prebundle_status.$n"
done
exit "$failed"
