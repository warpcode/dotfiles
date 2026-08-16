#!/bin/bash
# Submit a PR review atomically via GitHub REST API.
# Supports line-level, multi-line, and summary comments in a single atomic payload.
# Usage: ./submit_review.sh <owner> <repo> <pr_number> <payload_file> [--raw]
#
# Payload format (JSON):
# {
#   "commit_id": "optional_head_sha",
#   "event": "APPROVE" | "REQUEST_CHANGES" | "COMMENT",
#   "body": "Review body text",
#   "comments": [
#     {
#       "path": "file/path",
#       "body": "Comment text",
#       "line": 42,                    // Line within diff
#       "side": "RIGHT"                // Optional: LEFT or RIGHT
#     }
#   ]
# }

set -euo pipefail

RAW_OUTPUT=false
ARGS=()
for arg in "$@"; do
    if [[ "$arg" == "--raw" ]]; then
        RAW_OUTPUT=true
    else
        ARGS+=("$arg")
    fi
done

OWNER="${ARGS[0]:-}"
REPO="${ARGS[1]:-}"
PR_NUMBER="${ARGS[2]:-}"
PAYLOAD_FILE="${ARGS[3]:-}"

if [[ -z "$OWNER" || -z "$REPO" || -z "$PR_NUMBER" || -z "$PAYLOAD_FILE" ]]; then
    echo "Usage: $0 <owner> <repo> <pr_number> <payload_file> [--raw]" >&2
    exit 1
fi

if [[ ! -f "$PAYLOAD_FILE" ]]; then
    echo "Error: Payload file not found: $PAYLOAD_FILE" >&2
    exit 1
fi

# Step 1: Submit the atomic review via REST API
STDERR_FILE=$(mktemp)
RESPONSE=$(gh api "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/reviews" \
  --method POST \
  --input "$PAYLOAD_FILE" 2>"$STDERR_FILE")
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
    echo "$RESPONSE" | jq -r '
      "Review ID: \(.id)",
      "State: \(.state)",
      "URL: \(.html_url)"
    '
fi

