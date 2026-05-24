#!/bin/bash
# Submit a PR review using a JSON payload
# Usage: ./submit_review.sh <pr_number> <payload_file>

PR_NUMBER=$1
PAYLOAD_FILE=$2

if [[ -z "$PR_NUMBER" || -z "$PAYLOAD_FILE" ]]; then
    echo "Usage: $0 <pr_number> <payload_file>" >&2
    exit 1
fi

if [[ ! -f "$PAYLOAD_FILE" ]]; then
    echo "Error: Payload file not found: $PAYLOAD_FILE" >&2
    exit 1
fi

# Resolve repository name
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

# Submit review
gh api "repos/${REPO}/pulls/${PR_NUMBER}/reviews" --input "$PAYLOAD_FILE"
