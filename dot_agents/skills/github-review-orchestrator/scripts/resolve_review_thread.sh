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

success=true

DYNAMIC_QUERY="mutation {"
for i in "${!THREAD_IDS[@]}"; do
    THREAD_ID="${THREAD_IDS[$i]}"
    DYNAMIC_QUERY+="m$i: resolveReviewThread(input: { threadId: \"$THREAD_ID\" }) { thread { id isResolved } } "
done
DYNAMIC_QUERY+="}"

STDERR_FILE=$(mktemp)
RESPONSE=$(gh api graphql -f query="$DYNAMIC_QUERY" 2>"$STDERR_FILE")
GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
    echo "Error: Failed to resolve threads (exit code: $GH_STATUS)." >&2
    cat "$STDERR_FILE" >&2
    rm -f "$STDERR_FILE"
    success=false
else
    rm -f "$STDERR_FILE"
    if [[ "$RAW_OUTPUT" == "true" ]]; then
        echo "$RESPONSE"
    else
        echo "$RESPONSE" | jq -r '
          .data[] | select(. != null) |
          .thread |
          "Thread ID: \(.id) | Resolved: \(.isResolved)"
        '
    fi
fi

if [[ "$success" == "false" ]]; then
    exit 1
fi



