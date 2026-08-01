#!/bin/bash
# fetch_file.sh <owner> <repo> <path> <branch>
# Fetches a file from a remote GitHub repository branch without checkout.
# Outputs file content to stdout.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/client.sh"

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <owner> <repo> <path> <branch>"
    exit 1
fi

OWNER=$1
REPO=$2
FILE_PATH=$3
BRANCH=$4

STDERR_FILE=$(mktemp)
RESPONSE=$(github_api_request "GET" "repos/${OWNER}/${REPO}/contents/${FILE_PATH}?ref=${BRANCH}" 2>"$STDERR_FILE")
GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
    echo "Error: Failed to fetch file from GitHub (exit code: $GH_STATUS)." >&2
    cat "$STDERR_FILE" >&2
    rm -f "$STDERR_FILE"
    exit 1
fi
rm -f "$STDERR_FILE"

echo "$RESPONSE" | jq -r '.content' | base64 -d
