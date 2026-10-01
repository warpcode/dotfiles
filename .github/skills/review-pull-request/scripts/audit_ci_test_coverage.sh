#!/usr/bin/env bash
# Determine which test files a repository's CI actually executes.
#
# Motivation: a PR that claims "all tests pass" is only meaningful if some
# workflow runs those tests. This script reports the gap between the test files
# present on a ref and the test paths CI references, so reviewers can flag
# unverified verification claims instead of trusting them.
#
# Usage:
#   audit_ci_test_coverage.sh [--repo <owner>/<repo>] [--ref <ref>] [--local] [path ...]
#
# Options:
#   --repo <owner>/<repo>  GitHub repo to inspect. Default: origin's owner/repo.
#   --ref <ref>            Ref to inspect. Default: origin/master (falls back to
#                          origin/main). Ignored with --local.
#   --local                Inspect the local working tree instead of a remote ref.
#                          Use for read-only reconnaissance only.
#   -h, --help             Show this help and exit.
#
# Exit codes:
#   0  Coverage inspected successfully.
#   1  Bad usage, or the ref/repo could not be resolved.

set -euo pipefail

repo=""
ref=""
local_mode=0
paths=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)  repo="${2:-}"; shift 2 ;;
    --ref)   ref="${2:-}"; shift 2 ;;
    --local) local_mode=1; shift ;;
    -h|--help) sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --)      shift; paths+=("$@"); break ;;
    -*)      echo "error: unknown option $1" >&2; exit 1 ;;
    *)       paths+=("$1"); shift ;;
  esac
done

if [[ -z "$repo" ]]; then
  repo="$(git remote get-url origin 2>/dev/null |
          sed -E 's#^(git@[^:]+:|https?://[^/]+/)##; s#\.git$##')"
fi
[[ -n "$repo" ]] || { echo "error: could not determine repo; pass --repo" >&2; exit 1; }

if [[ -z "$ref" ]]; then
  for candidate in origin/master origin/main; do
    if git rev-parse --verify -q "$candidate" >/dev/null; then ref="$candidate"; break; fi
  done
  ref="${ref:-origin/master}"
fi

# Fetch all files on the ref into an index we can grep uniformly.
list_files() {
  if [[ $local_mode -eq 1 ]]; then
    git ls-files
  else
    git ls-tree -r --name-only "$ref"
  fi
}

file_body() {
  local path="$1"
  if [[ $local_mode -eq 1 ]]; then
    [[ -f "$path" ]] && cat -- "$path" || true
  else
    git show "$ref:$path" 2>/dev/null || true
  fi
}

echo "== repo: $repo"
echo "== ref : $([[ $local_mode -eq 1 ]] && echo '(working tree)' || echo "$ref")"
echo

# --- Test files present -------------------------------------------------------
mapfile -t all_tests < <(
  list_files | grep -E '(^|/)(tests?/.*|[^/]*_test\.[a-z]+|test_[^/]*\.[a-z]+)$' |
    grep -E '\.(py|js|ts|sh|zsh|rb|go)$' | sort
)
if [[ ${#all_tests[@]} -eq 0 ]]; then
  echo "No test files detected on this ref."
  exit 0
fi
printf 'Test files present: %d\n' "${#all_tests[@]}"

# --- What CI references -------------------------------------------------------
mapfile -t workflows < <(list_files | grep -E '^\.github/workflows/.*\.ya?ml$' | sort)
echo "Workflow files: ${#workflows[@]}"
echo

if [[ ${#workflows[@]} -gt 0 ]]; then
  echo "-- test invocations found in workflows --"
  found_invocation=0
  for wf in "${workflows[@]}"; do
    body="$(file_body "$wf")" || continue
    # Only lines that plausibly execute a test runner.
    hits="$(printf '%s' "$body" |
      grep -nE '(unittest|pytest|python3 +-m +[a-z_]+test|tox|nox|jest|vitest|go +test|cargo +test|bundle +exec|rspec|phpunit|ctest)' || true)"
    if [[ -n "$hits" ]]; then
      found_invocation=1
      printf '  %s:\n' "$wf"
      printf '%s\n' "$hits" | sed 's/^/    /'
    fi
  done
  [[ $found_invocation -eq 0 ]] && echo "  (none — no workflow invokes a test runner)"
  echo

  echo "-- path filters (a PR must match one to trigger the workflow) --"
  for wf in "${workflows[@]}"; do
    body="$(file_body "$wf")" || continue
    filters="$(printf '%s' "$body" |
      grep -nE "^ +- +'?[^ ]*\.(py|js|ts|sh|zsh|rb|go)'?|^ +paths:" || true)"
    [[ -n "$filters" ]] || continue
    printf '  %s:\n' "$wf"
    printf '%s\n' "$filters" | sed 's/^/    /'
  done
  echo
fi

# --- Coverage gap -------------------------------------------------------------
echo "-- referenced-but-absent / never-referenced --"
referenced_any=0
for wf in "${workflows[@]:-}"; do
  [[ -n "$wf" ]] || continue
  for t in "${all_tests[@]}"; do
    if file_body "$wf" | grep -qF "$t"; then
      echo "  REFERENCED  $t   ($wf)"
      referenced_any=1
    fi
  done
done
if [[ $referenced_any -eq 0 && ${#workflows[@]} -gt 0 ]]; then
  echo "  NO test file is named in any workflow."
fi
if [[ ${#paths[@]} -gt 0 ]]; then
  echo
  echo "-- requested paths --"
  for p in "${paths[@]}"; do
    if printf '%s\n' "${all_tests[@]}" | grep -qxF "$p"; then
      hit=no
      for wf in "${workflows[@]:-}"; do
        [[ -n "$wf" ]] || continue
        if file_body "$wf" | grep -qF "$p"; then hit="yes ($wf)"; fi
      done
      printf '  %-60s referenced-by-ci: %s\n' "$p" "$hit"
    else
      printf '  %-60s not a detected test file\n' "$p"
    fi
  done
fi