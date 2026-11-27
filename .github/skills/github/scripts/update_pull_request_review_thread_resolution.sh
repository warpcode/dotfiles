#!/bin/bash
# Resolve GitHub PR review threads using a GraphQL mutation.
# Usage: ./update_pull_request_review_thread_resolution.sh [OPTIONS] [THREAD_ID...]

set -euo pipefail
export GH_PAGER=""
export PAGER=cat

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
QUERY_FILE="${SCRIPT_DIR}/../queries/resolve_review_thread.gql"

if [[ ! -f "$QUERY_FILE" ]]; then
  echo "Error: Query file not found at $QUERY_FILE" >&2
  exit 1
fi

THREAD_IDS=()

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./update_pull_request_review_thread_resolution.sh"
      echo "  [OPTIONS] [THREAD_ID...]"
      echo ""
      echo "Resolve pull request review comment threads via GraphQL."
      echo ""
      echo "Options:"
      echo "  --thread-id <value>  Review thread ID to resolve (repeatable)"
      echo "  --thread-ids <list>  Comma- or whitespace-separated IDs"
      echo "  --stdin              Read review thread IDs from stdin"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    --thread-id)
      if [[ $# -lt 2 || -z "$2" ]]; then
        echo "Error: --thread-id requires a thread ID." >&2
        exit 1
      fi
      THREAD_IDS+=("$2")
      shift 2
      ;;
    --thread-ids)
      if [[ $# -lt 2 || -z "$2" ]]; then
        echo "Error: --thread-ids requires a list of thread IDs." >&2
        exit 1
      fi
      IFS=$' ,\t' read -r -a parsed_ids <<< "$2"
      THREAD_IDS+=("${parsed_ids[@]}")
      shift 2
      ;;
    --stdin)
      while IFS= read -r line || [[ -n "$line" ]]; do
        IFS=$' ,\t' read -r -a parsed_ids <<< "$line"
        THREAD_IDS+=("${parsed_ids[@]}")
      done
      shift
      ;;
    -*)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
    *)
      THREAD_IDS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#THREAD_IDS[@]} -eq 0 ]]; then
  echo "Error: At least one thread ID is required. Use --help for usage." >&2
  exit 1
fi

if [[ ${#THREAD_IDS[@]} -gt 1 ]]; then
  echo "Resolving ${#THREAD_IDS[@]} review thread(s)..."
  echo ""
fi

RESOLVED_COUNT=0
FAILED_COUNT=0
TOTAL_COUNT=${#THREAD_IDS[@]}

for thread_id in "${THREAD_IDS[@]}"; do
  response=""
  gh_status=0
  response=$(gh api graphql -F query="@$QUERY_FILE" \
    -f threadId="$thread_id" 2>&1) || gh_status=$?

  if [[ $gh_status -ne 0 ]]; then
    FAILED_COUNT=$((FAILED_COUNT + 1))
    echo "- [FAILED]   \`$thread_id\`: $response" >&2
    continue
  fi

  if jq -e '.errors | length > 0' >/dev/null 2>&1 <<< "$response"; then
    FAILED_COUNT=$((FAILED_COUNT + 1))
    error_message=$(jq -r '.errors[].message' <<< "$response")
    echo "- [FAILED]   \`$thread_id\`: $error_message" >&2
    continue
  fi

  is_resolved=$(jq -r '.data.resolveReviewThread.thread.isResolved // false' \
    2>/dev/null <<< "$response" || echo "false")
  if [[ "$is_resolved" == "true" ]]; then
    RESOLVED_COUNT=$((RESOLVED_COUNT + 1))
    if [[ $TOTAL_COUNT -eq 1 ]]; then
      jq -r '.data.resolveReviewThread.thread |
        "Thread ID: \(.id) | Resolved: \(.isResolved)"' <<< "$response"
    else
      echo "- [RESOLVED] \`$thread_id\`"
    fi
  else
    FAILED_COUNT=$((FAILED_COUNT + 1))
    echo "- [FAILED]   \`$thread_id\` (API returned isResolved=false)" >&2
  fi
done

if [[ $TOTAL_COUNT -gt 1 ]]; then
  echo ""
  printf 'Summary: %d resolved, %d failed out of %d total.\n' \
    "$RESOLVED_COUNT" "$FAILED_COUNT" "$TOTAL_COUNT"
fi

if [[ $FAILED_COUNT -gt 0 ]]; then
  exit 1
fi
