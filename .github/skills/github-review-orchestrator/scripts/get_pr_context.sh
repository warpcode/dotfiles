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
HEAD_OID_RESPONSE=$(gh pr view "$PR_NUMBER" "${REPO_FLAG[@]}" --json headRefOid --template '{{.headRefOid}}' 2>&1)
GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
    echo "Error: Failed to fetch PR head OID (exit code: $GH_STATUS)." >&2
    echo "Details: $HEAD_OID_RESPONSE" >&2
    if echo "$HEAD_OID_RESPONSE" | grep -iq -e "token" -e "auth" -e "connect"; then
        echo "Tip: Run 'gh auth login' to re-authenticate or check your internet connection." >&2
    fi
    exit 1
fi

HEAD_OID="$HEAD_OID_RESPONSE"

if [[ "$RAW_OUTPUT" == "true" ]]; then
    DIFF_RESPONSE=$(gh pr diff "$PR_NUMBER" "${REPO_FLAG[@]}" 2>&1)
    GH_STATUS=$?
    if [[ $GH_STATUS -ne 0 ]]; then
        echo "Error: Failed to fetch diff for PR #$PR_NUMBER (exit code: $GH_STATUS)." >&2
        echo "Details: $DIFF_RESPONSE" >&2
        if echo "$DIFF_RESPONSE" | grep -iq -e "token" -e "auth" -e "connect"; then
            echo "Tip: Run 'gh auth login' to re-authenticate or check your internet connection." >&2
        fi
        exit 1
    fi
    DIFF="$DIFF_RESPONSE"
    jq -n --arg headRefOid "$HEAD_OID" --arg diff "$DIFF" \
        '{headRefOid: $headRefOid, diff: $diff}'
else
    # Token-efficient summary displaying all required metadata without truncating
    PR_VIEW_RESPONSE=$(gh pr view "$PR_NUMBER" "${REPO_FLAG[@]}" --json headRefOid,title,body,additions,deletions,changedFiles,files 2>&1)
    GH_STATUS=$?
    if [[ $GH_STATUS -ne 0 ]]; then
        echo "Error: Failed to view PR #$PR_NUMBER (exit code: $GH_STATUS)." >&2
        echo "Details: $PR_VIEW_RESPONSE" >&2
        if echo "$PR_VIEW_RESPONSE" | grep -iq -e "token" -e "auth" -e "connect"; then
            echo "Tip: Run 'gh auth login' to re-authenticate or check your internet connection." >&2
        fi
        exit 1
    fi
    echo "$PR_VIEW_RESPONSE" | jq -r '
      "HEAD_OID: \(.headRefOid)",
      "Title: \(.title)",
      "Description: \(.body | sub("\n.*"; "..."))",
      "Stats: \(.changedFiles) files changed, +\(.additions) -\(.deletions) lines",
      "Files:",
      (.files[] | "  - \(.path) (+\(.additions) -\(.deletions))")
    '
fi
