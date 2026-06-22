#!/bin/bash
# Resolve a GitHub PR review thread using GraphQL
# Usage: ./resolve_review_thread.sh <thread_id> [--raw]

RAW_OUTPUT=false
ARGS=()
for arg in "$@"; do
    if [[ "$arg" == "--raw" ]]; then
        RAW_OUTPUT=true
    else
        ARGS+=("$arg")
    fi
done

THREAD_ID=${ARGS[0]}

if [[ -z "$THREAD_ID" ]]; then
    echo "Usage: $0 <thread_id> [--raw]" >&2
    exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

STDERR_FILE=$(mktemp)
RESPONSE=$(gh api graphql -F query="@${SCRIPT_DIR}/../queries/resolve_review_thread.gql" -f threadId="$THREAD_ID" 2>"$STDERR_FILE")
GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
    echo "Error: Failed to resolve thread $THREAD_ID (exit code: $GH_STATUS)." >&2
    cat "$STDERR_FILE" >&2
    rm -f "$STDERR_FILE"
    exit 1
fi
rm -f "$STDERR_FILE"

if [[ "$RAW_OUTPUT" == "true" ]]; then
    echo "$RESPONSE"
else
    # Token-efficient plain-text summary
    echo "$RESPONSE" | jq -r '
      .data.resolveReviewThread.thread |
      "Thread ID: \(.id)",
      "Resolved: \(.isResolved)"
    '
fi



