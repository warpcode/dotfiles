#!/bin/bash
# Resolve a single GitHub PR review thread using GraphQL mutation.
# Usage: ./update_pull_request_review_thread_resolution.sh [OPTIONS]

set -euo pipefail
export GH_PAGER=""
export PAGER=cat

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
QUERY_FILE="${SCRIPT_DIR}/../queries/resolve_review_thread.gql"

if [[ ! -f "$QUERY_FILE" ]]; then
  echo "Error: Query file not found at $QUERY_FILE" >&2
  exit 1
fi

thread_id=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./update_pull_request_review_thread_resolution.sh [OPTIONS]"
      echo ""
      echo "Resolve an active pull request review comment thread via GraphQL."
      echo ""
      echo "Options:"
      echo "  --thread-id <value>  Review thread ID to resolve (Required)"
      echo "  -h, --help           Show this help message"
      exit 0
      ;;
    --thread-id)
      thread_id="$2"
      shift 2
      ;;
    -*)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
    *)
      if [[ -z "$thread_id" ]]; then
        thread_id="$1"
        shift
      else
        echo "Error: Multiple thread IDs provided. Only 1 review thread ID is accepted." >&2
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$thread_id" ]]; then
  echo "Error: --thread-id is required. Use --help for usage." >&2
  exit 1
fi

STDERR_FILE=$(mktemp)
trap 'rm -f "$STDERR_FILE"' EXIT

GH_STATUS=0
RESPONSE=$(gh api graphql -F query="@$QUERY_FILE" -f threadId="$thread_id" 2>"$STDERR_FILE") || GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
  echo "Error: Failed to resolve thread $thread_id (exit code: $GH_STATUS)." >&2
  cat "$STDERR_FILE" >&2
  exit 1
fi

if echo "$RESPONSE" | jq -e '.errors' >/dev/null 2>&1; then
  echo "Error: Failed to resolve thread $thread_id:" >&2
  echo "$RESPONSE" | jq -r '.errors[].message' >&2
  exit 1
fi

echo "$RESPONSE" | jq -r '
  .data.resolveReviewThread.thread |
  "Thread ID: \(.id) | Resolved: \(.isResolved)"
'
