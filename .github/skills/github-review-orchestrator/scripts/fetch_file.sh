#!/bin/bash
# fetch_file.sh <owner> <repo> <path> <branch>
# Fetches a file from a remote GitHub repository branch without checkout.
# Outputs file content to stdout.

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <owner> <repo> <path> <branch>"
    exit 1
fi

OWNER=$1
REPO=$2
FILE_PATH=$3
BRANCH=$4

RESPONSE=$(gh api "repos/${OWNER}/${REPO}/contents/${FILE_PATH}?ref=${BRANCH}" 2>&1)
GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
    echo "Error: Failed to fetch file from GitHub (exit code: $GH_STATUS)." >&2
    echo "Details: $RESPONSE" >&2
    if echo "$RESPONSE" | grep -iq -e "token" -e "auth" -e "connect"; then
        echo "Tip: Run 'gh auth login' to re-authenticate or check your internet connection." >&2
    fi
    exit 1
fi

echo "$RESPONSE" | jq -r '.content' | base64 -d
