#!/bin/bash
# View a specific issue
# Usage: ./view_issue.sh <owner/repo> <issue_number>

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/client.sh"

REPO=$1
NUMBER=$2

if [[ -z "$REPO" || -z "$NUMBER" ]]; then
    echo "Usage: $0 <owner/repo> <issue_number>" >&2
    exit 1
fi

ISSUE=$(github_api_request "GET" "repos/${REPO}/issues/${NUMBER}")
COMMENTS=$(github_api_request "GET" "repos/${REPO}/issues/${NUMBER}/comments")

echo "# $(echo "$ISSUE" | jq -r .title) (#$NUMBER)"
echo "State: $(echo "$ISSUE" | jq -r .state)"
echo "Author: @$(echo "$ISSUE" | jq -r .user.login)"
echo ""
echo "$(echo "$ISSUE" | jq -r .body)"
echo ""
echo "## Comments"
echo "$COMMENTS" | jq -r '.[] | "--- @\(.user.login) ---\n\(.body)\n"'
