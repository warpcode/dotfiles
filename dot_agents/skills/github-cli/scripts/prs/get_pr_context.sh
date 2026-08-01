#!/bin/bash
# Get PR head OID and diff for review context
# Usage: ./get_pr_context.sh <owner> <repo> <pr_number> [--raw]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/client.sh"

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

# Fetch head OID
STDERR_FILE=$(mktemp)
HEAD_OID_RESPONSE=$(github_api_request "GET" "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}" 2>"$STDERR_FILE")
GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
    echo "Error: Failed to fetch PR info (exit code: $GH_STATUS)." >&2
    cat "$STDERR_FILE" >&2
    rm -f "$STDERR_FILE"
    exit 1
fi
rm -f "$STDERR_FILE"

HEAD_OID=$(echo "$HEAD_OID_RESPONSE" | jq -r '.head.sha')

if [[ "$RAW_OUTPUT" == "true" ]]; then
    STDERR_FILE=$(mktemp)
    # gh pr diff equivalent via API
    DIFF=$(github_api_request "GET" "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}" -H "Accept: application/vnd.github.v3.diff" 2>"$STDERR_FILE")
    GH_STATUS=$?
    if [[ $GH_STATUS -ne 0 ]]; then
        echo "Error: Failed to fetch diff for PR #$PR_NUMBER (exit code: $GH_STATUS)." >&2
        cat "$STDERR_FILE" >&2
        rm -f "$STDERR_FILE"
        exit 1
    fi
    rm -f "$STDERR_FILE"
    jq -n --arg headRefOid "$HEAD_OID" --arg diff "$DIFF" \
        '{headRefOid: $headRefOid, diff: $diff}'
else
    # Token-efficient summary
    echo "$HEAD_OID_RESPONSE" | jq -r '
      "HEAD_OID: \(.head.sha)",
      "Branch: \(.head.ref)",
      "Title: \(.title)",
      "Description: \(.body | sub("\n.*"; "..."))",
      "Stats: \(.changed_files) files changed, +\(.additions) -\(.deletions) lines"
    '
    # Files list is separate in REST API for pulls if we want specific additions/deletions per file,
    # but for summary we can just skip or add another request if needed.
    # To keep it simple and efficient, I will stop here or fetch files if really needed.
fi
