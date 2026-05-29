#!/bin/bash
# Submit a PR review using a JSON payload
# Usage: ./submit_review.sh <owner> <repo> <pr_number> <payload_file> [--raw]

RAW_OUTPUT=false
ARGS=()
for arg in "$@"; do
    if [[ "$arg" == "--raw" ]]; then
        RAW_OUTPUT=true
    else
        ARGS+=("$arg")
    fi
done

OWNER=${ARGS[0]}
REPO=${ARGS[1]}
PR_NUMBER=${ARGS[2]}
PAYLOAD_FILE=${ARGS[3]}

if [[ -z "$OWNER" || -z "$REPO" || -z "$PR_NUMBER" || -z "$PAYLOAD_FILE" ]]; then
    echo "Usage: $0 <owner> <repo> <pr_number> <payload_file> [--raw]" >&2
    exit 1
fi

if [[ ! -f "$PAYLOAD_FILE" ]]; then
    echo "Error: Payload file not found: $PAYLOAD_FILE" >&2
    exit 1
fi

# Submit review
STDERR_FILE=$(mktemp)
RESPONSE=$(gh api "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/reviews" --input "$PAYLOAD_FILE" 2>"$STDERR_FILE")
GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
    echo "Error: Failed to submit review (exit code: $GH_STATUS)." >&2
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
      "Review ID: \(.id)",
      "State: \(.state)",
      "URL: \(.html_url)"
    '
fi

