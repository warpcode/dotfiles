#!/bin/bash
# Get PR head OID and diff for review context
# Usage: ./get_pr_context.sh <owner> <repo> <pr_number> [--raw]

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

if [[ -z "$OWNER" || -z "$REPO" || -z "$PR_NUMBER" ]]; then
    echo "Usage: $0 <owner> <repo> <pr_number> [--raw]" >&2
    exit 1
fi

REPO_FLAG=("--repo" "${OWNER}/${REPO}")

# Fetch head OID
HEAD_OID=$(gh pr view "$PR_NUMBER" "${REPO_FLAG[@]}" --json headRefOid --template '{{.headRefOid}}')

if [[ -z "$HEAD_OID" ]]; then
    echo "Error: Could not fetch headRefOid for PR #$PR_NUMBER in $OWNER/$REPO" >&2
    exit 1
fi

if [[ "$RAW_OUTPUT" == "true" ]]; then
    DIFF=$(gh pr diff "$PR_NUMBER" "${REPO_FLAG[@]}")
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to fetch diff for PR #$PR_NUMBER" >&2
        exit 1
    fi
    jq -n --arg headRefOid "$HEAD_OID" --arg diff "$DIFF" \
        '{headRefOid: $headRefOid, diff: $diff}'
else
    # Token-efficient summary displaying all required metadata without truncating
    gh pr view "$PR_NUMBER" "${REPO_FLAG[@]}" --json headRefOid,title,body,additions,deletions,changedFiles,files | jq -r '
      "HEAD_OID: \(.headRefOid)",
      "Title: \(.title)",
      "Description:",
      "\(.body)",
      "",
      "Stats: \(.changedFiles) files changed, +\(.additions) -\(.deletions) lines",
      "Files:",
      (.files[] | "  - \(.path) (+\(.additions) -\(.deletions))")
    '
fi
