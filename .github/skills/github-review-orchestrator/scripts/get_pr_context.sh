#!/bin/bash
# Get PR head OID and diff for review context
# Usage: ./get_pr_context.sh <owner> <repo> <pr_number>

if [[ "$#" -ne 3 ]]; then
    echo "Usage: $0 <owner> <repo> <pr_number>" >&2
    exit 1
fi

OWNER=$1
REPO=$2
PR_NUMBER=$3
REPO_FLAG=("--repo" "${OWNER}/${REPO}")

# Fetch head OID
HEAD_OID=$(gh pr view "$PR_NUMBER" "${REPO_FLAG[@]}" --json headRefOid --template '{{.headRefOid}}')

if [[ -z "$HEAD_OID" ]]; then
    echo "Error: Could not fetch headRefOid for PR #$PR_NUMBER in $OWNER/$REPO" >&2
    exit 1
fi

# Output OID and then the diff
echo "HEAD_OID:$HEAD_OID"
gh pr diff "$PR_NUMBER" "${REPO_FLAG[@]}"


