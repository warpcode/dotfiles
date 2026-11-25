#!/usr/bin/env bash
# pr_batch_merge.sh - Batch silent-approve and squash-merge green PRs
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

usage() {
  cat <<'EOF'
Usage: pr_batch_merge.sh [--repo <owner/repo>] [--admin] [--delete-branch] <pr_number> [pr_number...]

Silently approve and squash-merge verified green PRs.

Options:
  -R, --repo <owner/repo>   Target repository (e.g. warpcode/dotfiles)
  --admin                   Use administrator privileges to bypass rulesets (default: enabled)
  --delete-branch           Delete remote branch after merge (default: enabled)
  -n, --dry-run             Check eligibility without applying merges
  -h, --help                Show this help message
EOF
}

REPO=""
DRY_RUN=0
ADMIN="--admin"
DELETE_BRANCH="--delete-branch"
PRS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -R|--repo)
      REPO="$2"
      shift 2
      ;;
    --no-admin)
      ADMIN=""
      shift
      ;;
    --admin)
      ADMIN="--admin"
      shift
      ;;
    --no-delete-branch)
      DELETE_BRANCH=""
      shift
      ;;
    --delete-branch)
      DELETE_BRANCH="--delete-branch"
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      PRS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#PRS[@]} -eq 0 ]]; then
  echo "Error: At least one PR number is required." >&2
  usage
  exit 1
fi

REPO_ARGS=()
if [[ -n "$REPO" ]]; then
  REPO_ARGS=(--repo "$REPO")
fi

for pr in "${PRS[@]}"; do
  echo "=== Evaluating PR #${pr} ==="
  info="$(gh pr view "$pr" "${REPO_ARGS[@]}" --json state,mergeable,reviewDecision,statusCheckRollup,title 2>/dev/null || echo '')"
  if [[ -z "$info" ]]; then
    echo "Warning: Could not fetch PR #${pr}; skipping." >&2
    continue
  fi

  state="$(echo "$info" | jq -r '.state')"
  mergeable="$(echo "$info" | jq -r '.mergeable')"
  review="$(echo "$info" | jq -r '.reviewDecision // "NONE"')"
  title="$(echo "$info" | jq -r '.title')"

  if [[ "$state" != "OPEN" ]]; then
    echo "PR #${pr} is already $state ($title); skipping."
    continue
  fi

  if [[ "$mergeable" == "CONFLICTING" ]]; then
    echo "PR #${pr} is CONFLICTING; skipping."
    continue
  fi

  failed_checks="$(echo "$info" | jq '[.statusCheckRollup[]? | select(.conclusion != "SUCCESS")] | length')"
  if [[ "$failed_checks" -gt 0 ]]; then
    echo "PR #${pr} has $failed_checks non-successful checks; skipping."
    continue
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "[DRY RUN] Eligible for merge: PR #${pr} ($title, review: $review, mergeable: $mergeable)"
    continue
  fi

  # Invariant: Silent approval without body comments when review is required or changes requested
  if [[ "$review" == "REVIEW_REQUIRED" || "$review" == "CHANGES_REQUESTED" ]]; then
    echo "Submitting silent approval for PR #${pr}..."
    gh pr review "$pr" "${REPO_ARGS[@]}" --approve --body ""
  fi

  merge_cmd=(gh pr merge "$pr" "${REPO_ARGS[@]}" --squash)
  [[ -n "$DELETE_BRANCH" ]] && merge_cmd+=("$DELETE_BRANCH")
  [[ -n "$ADMIN" ]] && merge_cmd+=("$ADMIN")

  echo "Merging PR #${pr}..."
  "${merge_cmd[@]}"
  echo "✓ Successfully merged PR #${pr}."
done
