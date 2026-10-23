#!/usr/bin/env bash
# Preflight and squash-merge a batch of approved PRs sequentially.
# Usage: batch_merge.sh --repo <owner/repo> --prs <1,2,3> [--admin] [--delete-branch] [--dry-run]

set -euo pipefail
export GH_PAGER=""
export PAGER=cat

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PR_MERGE="$SCRIPT_DIR/pr_merge.sh"

show_help() {
  cat <<'EOF'
Usage:
  batch_merge.sh --repo <owner/repo> --prs <1,2,3> [options]

Preflights and squash-merges multiple approved pull requests sequentially.
If a pull request has merge conflicts, it is reported and skipped during execution.

Options:
  --repo <owner/repo>  Repository in owner/name format (Required)
  --prs <list>         Comma-separated list of PR numbers (Required)
  --admin              Bypass branch rulesets with admin privileges
  --delete-branch      Delete head branch after each successful merge
  --dry-run            Preflight all candidate PRs only; do not merge
  -h, --help           Show this help message and exit

Exit codes:
  0  All PRs preflighted or merged successfully
  1  Usage error or merge failed
  2  One or more PRs have conflicts / failed preflight during dry-run
EOF
}

REPO=""
PRS=""
ADMIN_FLAG=""
DELETE_FLAG=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --prs)
      PRS="${2:-}"
      shift 2
      ;;
    --admin)
      ADMIN_FLAG="--admin"
      shift
      ;;
    --delete-branch)
      DELETE_FLAG="--delete-branch"
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$REPO" || -z "$PRS" ]]; then
  echo "Error: Both --repo and --prs are required. Run with --help for usage." >&2
  exit 1
fi

if [[ ! -f "$PR_MERGE" ]]; then
  echo "Error: Missing pr_merge.sh helper at $PR_MERGE" >&2
  exit 1
fi

IFS=',' read -r -a PR_LIST <<< "$PRS"

echo "# Batch Merge Preflight (${#PR_LIST[@]} PRs for $REPO)"
echo ""
declare -a CLEAN=()
declare -a CONFLICTING=()

for pr in "${PR_LIST[@]}"; do
  # Trim whitespace
  pr="$(echo "$pr" | tr -d '[:space:]')"
  [[ -n "$pr" ]] || continue

  if bash "$PR_MERGE" "$pr" --repo "$REPO" --dry-run >/dev/null 2>&1; then
    CLEAN+=("$pr")
    echo "- ✅ **#$pr**: Clean (preflight passed)"
  else
    CONFLICTING+=("$pr")
    echo "- ❌ **#$pr**: Blocked / Conflicting (preflight failed)"
  fi
done

echo ""
echo "**Summary:** ${#CLEAN[@]} ready to merge, ${#CONFLICTING[@]} blocked."

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo ""
  echo "DRY RUN complete. Re-run without --dry-run to execute."
  if [[ "${#CONFLICTING[@]}" -gt 0 ]]; then
    exit 2
  fi
  exit 0
fi

if [[ "${#CLEAN[@]}" -eq 0 ]]; then
  echo "No mergeable PRs found." >&2
  exit 2
fi

echo ""
echo "## Executing Sequential Merges"
echo ""

MERGED_COUNT=0
FAILED=0

for pr in "${CLEAN[@]}"; do
  echo "### Merging #$pr..."
  # Re-check mergeability on demand right before merging in case previous merges changed master
  if ! bash "$PR_MERGE" "$pr" --repo "$REPO" $ADMIN_FLAG $DELETE_FLAG; then
    echo "⚠️ Failed to merge #$pr. Halting batch sequence to prevent cascading failures." >&2
    FAILED=1
    break
  fi
  MERGED_COUNT=$((MERGED_COUNT + 1))
done

echo ""
echo "**Batch Merge Result:** $MERGED_COUNT PR(s) merged successfully."
if [[ "$FAILED" -eq 1 ]]; then
  exit 1
fi
