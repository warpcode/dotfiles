#!/bin/bash
# List issues for a repository
# Usage: ./list_issues.sh <owner/repo> [state] [limit]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/client.sh"

REPO=$1
STATE=${2:-open}
LIMIT=${3:-30}

if [[ -z "$REPO" ]]; then
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || true
fi

if [[ -z "$REPO" ]]; then
    echo "Usage: $0 <owner/repo> [state] [limit]" >&2
    exit 1
fi

RESPONSE=$(github_api_request "GET" "repos/${REPO}/issues?state=${STATE}&per_page=${LIMIT}")

echo "$RESPONSE" | jq -r '.[] | "#\(.number)\t\(.state)\t@\(.user.login)\t\(.title)"'
