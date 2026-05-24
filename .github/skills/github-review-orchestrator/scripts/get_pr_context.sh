#!/bin/bash
# Get PR head OID and diff for review context
# Usage: ./get_pr_context.sh <pr_number>

PR_NUMBER=$1

if [[ -z "$PR_NUMBER" ]]; then
    echo "Usage: $0 <pr_number>" >&2
    exit 1
fi

# Fetch head OID
HEAD_OID=$(gh pr view "$PR_NUMBER" --json headRefOid --template '{{.headRefOid}}')

if [[ -z "$HEAD_OID" ]]; then
    echo "Error: Could not fetch headRefOid for PR #$PR_NUMBER" >&2
    exit 1
fi

# Output OID and then the diff
echo "HEAD_OID:$HEAD_OID"
gh pr diff "$PR_NUMBER"
