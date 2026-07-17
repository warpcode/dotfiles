#!/bin/bash
# Resolve GitHub PR review threads using GraphQL
# Usage: ./resolve_review_thread.sh <thread_id1> [thread_id2 ...] [--raw]

RAW_OUTPUT=false
THREAD_IDS=()
for arg in "$@"; do
    if [[ "$arg" == "--raw" ]]; then
        RAW_OUTPUT=true
    else
        THREAD_IDS+=("$arg")
    fi
done

if [[ ${#THREAD_IDS[@]} -eq 0 ]]; then
    echo "Usage: $0 <thread_id1> [thread_id2 ...] [--raw]" >&2
    exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
QUERY_FILE="${SCRIPT_DIR}/../queries/resolve_review_thread.gql"

success=true
for THREAD_ID in "${THREAD_IDS[@]}"; do
    STDERR_FILE=$(mktemp)
    RESPONSE=$(gh api graphql -F query="@$QUERY_FILE" -f threadId="$THREAD_ID" 2>"$STDERR_FILE")
    GH_STATUS=$?

    if [[ $GH_STATUS -ne 0 ]]; then
        echo "Error: Failed to resolve thread $THREAD_ID (exit code: $GH_STATUS)." >&2
        cat "$STDERR_FILE" >&2
        rm -f "$STDERR_FILE"
        success=false
        continue
    fi
    rm -f "$STDERR_FILE"

    if [[ "$RAW_OUTPUT" == "true" ]]; then
        echo "$RESPONSE"
    else
        echo "$RESPONSE" | jq -r '
          .data.resolveReviewThread.thread |
          "Thread ID: \(.id) | Resolved: \(.isResolved)"
        '
    fi
done

if [[ "$success" == "false" ]]; then
    exit 1
fi



