#!/bin/bash
# Fetch review threads for open PRs in one batch with configurable limit and sort.
# Usage: ./fetch_all_pr_threads.sh <owner> <repo> [limit] [direction]
#   direction: ASC (oldest updated first) or DESC (newest updated first, default)

OWNER=$1
REPO=$2
LIMIT=${3:-50}
DIRECTION=${4:-DESC}

if [[ -z "$OWNER" || -z "$REPO" ]]; then
    echo "Usage: $0 <owner> <repo> [limit] [direction]" >&2
    echo "Example: $0 warpcode dotfiles 10 ASC" >&2
    exit 1
fi

# Path to the batch query file
QUERY_FILE="$(dirname "$0")/../queries/batch_review_threads.gql"

if [[ ! -f "$QUERY_FILE" ]]; then
    echo "Error: Query file not found at $QUERY_FILE" >&2
    exit 1
fi

gh api graphql \
  -F owner="$OWNER" \
  -F repo="$REPO" \
  -F limit="$LIMIT" \
  -F direction="$DIRECTION" \
  -f query="$(cat "$QUERY_FILE")"
