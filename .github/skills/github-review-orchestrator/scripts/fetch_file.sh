#!/bin/bash
# fetch_file.sh <owner> <repo> <path> <branch> <tmp_path>
# Fetches a file from a remote GitHub repository branch without checkout.

if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <owner> <repo> <path> <branch> <tmp_path>"
    exit 1
fi

OWNER=$1
REPO=$2
FILE_PATH=$3
BRANCH=$4
TMP_PATH=$5

gh api "repos/${OWNER}/${REPO}/contents/${FILE_PATH}?ref=${BRANCH}" --jq '.content' | base64 -d > "${TMP_PATH}"
