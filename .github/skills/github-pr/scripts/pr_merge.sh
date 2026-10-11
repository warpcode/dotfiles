#!/usr/bin/env bash
# pr_merge.sh - Safely preflight and squash-merge a pull request.
#
# Preflights:
#   1. Resolves repository and PR number.
#   2. Verifies PR is OPEN and mergeable (no conflicts).
#   3. Verifies CI statusCheckRollup (all checks completed and succeeded).
#   4. Executes `gh pr merge <pr> --squash` (with optional --admin and --delete-branch).
#
# Usage:
#   pr_merge.sh <pr> --repo <owner/repo> [--admin] [--dry-run] [--delete-branch]
#   pr_merge.sh --pr <pr> --repo <owner/repo> [--admin] [--dry-run] [--delete-branch]

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: pr_merge.sh <pr> --repo <owner/repo> [options]

Preflights mergeability and CI status, then squash-merges the PR.

Arguments & Options:
  <pr>, --pr <number>      PR number to merge.
  --repo <owner/repo>      Repository in owner/name format.
  --admin                  Bypass branch rulesets with admin privileges.
  --delete-branch          Delete head branch after merging.
  --dry-run                Preflight only; do not merge.
  -h, --help               Show this help.

Exit codes:
  0  Merged successfully (or dry-run passed)
  1  Usage error or PR not open
  2  Merge conflicts detected
  3  CI checks failed or pending
  4  Merge execution failed
EOF
}

pr=""
repo=""
admin=0
dry_run=0
delete_branch=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --pr)
      pr="${2:-}"
      shift 2
      ;;
    --repo)
      repo="${2:-}"
      shift 2
      ;;
    --admin)
      admin=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --delete-branch)
      delete_branch=1
      shift
      ;;
    -*)
      echo "Error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ -z "$pr" && "$1" =~ ^[0-9]+$ ]]; then
        pr="$1"
        shift
      else
        echo "Error: unexpected positional argument: $1" >&2
        usage >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$pr" ]]; then
  echo "Error: PR number is required." >&2
  usage >&2
  exit 1
fi

if [[ -z "$repo" ]]; then
  remote_url="$(git remote get-url origin 2>/dev/null || true)"
  if [[ "$remote_url" =~ github\.com[:/]([^/]+)/([^/\s]+?)(\.git)?$ ]]; then
    repo="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
  else
    echo "Error: --repo is required and cannot be determined from origin remote." >&2
    exit 1
  fi
fi

# Fetch PR state and CI rollup
meta="$(gh pr view "$pr" --repo "$repo" \
  --json number,title,state,mergeable,mergeStateStatus,statusCheckRollup,headRefName,baseRefName 2>&1)" || {
  echo "Error: failed to fetch PR #$pr for repo $repo: $meta" >&2
  exit 1
}

state="$(jq -r '.state' <<< "$meta")"
title="$(jq -r '.title' <<< "$meta")"
mergeable="$(jq -r '.mergeable' <<< "$meta")"
merge_state_status="$(jq -r '.mergeStateStatus' <<< "$meta")"
head_ref="$(jq -r '.headRefName' <<< "$meta")"
base_ref="$(jq -r '.baseRefName' <<< "$meta")"

if [[ "$state" != "OPEN" ]]; then
  echo "Error: PR #$pr is not OPEN (current state: $state)." >&2
  exit 1
fi

# Check mergeability / conflicts
if [[ "$mergeable" == "CONFLICTING" || "$merge_state_status" == "DIRTY" ]]; then
  echo "Error: PR #$pr has merge conflicts with $base_ref (mergeable: $mergeable, status: $merge_state_status)." >&2
  exit 2
fi

# Check CI check runs / statuses
failing_checks="$(jq -r '
  [.statusCheckRollup[]? |
   select((.conclusion // "") as $c | ($c == "FAILURE" or $c == "TIMED_OUT" or $c == "ACTION_REQUIRED" or $c == "CANCELLED")) |
   "  - \(.name // .context): \(.conclusion)"] | join("\n")
' <<< "$meta")"

pending_checks="$(jq -r '
  [.statusCheckRollup[]? |
   select((.status // "") as $s | ($s == "IN_PROGRESS" or $s == "QUEUED" or $s == "PENDING" or $s == "WAITING")) |
   select((.conclusion // "") == "") |
   "  - \(.name // .context): \(.status)"] | join("\n")
' <<< "$meta")"

if [[ -n "$failing_checks" ]]; then
  echo "Error: PR #$pr has failing CI checks:" >&2
  echo "$failing_checks" >&2
  exit 3
fi

if [[ -n "$pending_checks" ]]; then
  echo "Error: PR #$pr has pending CI checks:" >&2
  echo "$pending_checks" >&2
  exit 3
fi

total_checks="$(jq -r '(.statusCheckRollup // []) | length' <<< "$meta")"

merge_args=("$pr" --repo "$repo" --squash)
[[ "$admin" -eq 1 ]] && merge_args+=(--admin)
[[ "$delete_branch" -eq 1 ]] && merge_args+=(--delete-branch)

if [[ "$dry_run" -eq 1 ]]; then
  echo "# PR #$pr Merge Preflight ($repo)"
  echo "- Title: $title"
  echo "- Branch: $head_ref -> $base_ref"
  echo "- Mergeable: $mergeable ($merge_state_status)"
  echo "- CI Checks: Passed ($total_checks checks verified)"
  echo "- Intended Command: gh pr merge ${merge_args[*]}"
  exit 0
fi

echo "Merging PR #$pr ($repo)..."
if gh pr merge "${merge_args[@]}"; then
  echo "Successfully merged PR #$pr into $base_ref."
  exit 0
else
  err_code=$?
  echo "Error: failed to merge PR #$pr (exit code $err_code)." >&2
  exit 4
fi
