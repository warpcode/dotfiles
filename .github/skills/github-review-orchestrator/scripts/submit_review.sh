#!/bin/bash
# Submit a PR review using a JSON payload
# Usage: ./submit_review.sh <owner> <repo> <pr_number> <payload_file>

if [[ "$#" -ne 4 ]]; then
    echo "Usage: $0 <owner> <repo> <pr_number> <payload_file>" >&2
    exit 1
fi

OWNER=$1
REPO=$2
PR_NUMBER=$3
PAYLOAD_FILE=$4

if [[ ! -f "$PAYLOAD_FILE" ]]; then
    echo "Error: Payload file not found: $PAYLOAD_FILE" >&2
    exit 1
fi

# Submit review
gh api "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/reviews" --input "$PAYLOAD_FILE"

