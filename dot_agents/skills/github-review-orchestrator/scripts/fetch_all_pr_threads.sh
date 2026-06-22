#!/bin/bash
# Fetch review threads for open PRs in one batch with configurable limit and sort.
# Usage: ./fetch_all_pr_threads.sh <owner> <repo> [limit] [direction] [--raw]
#   direction: ASC (oldest updated first) or DESC (newest updated first, default)

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
LIMIT=${ARGS[2]:-50}
DIRECTION=${ARGS[3]:-DESC}

if [[ -z "$OWNER" || -z "$REPO" ]]; then
    echo "Usage: $0 <owner> <repo> [limit] [direction] [--raw]" >&2
    echo "Example: $0 warpcode dotfiles 10 ASC" >&2
    exit 1
fi

# Path to the batch query file
QUERY_FILE="$(dirname "$0")/../queries/batch_review_threads.gql"

if [[ ! -f "$QUERY_FILE" ]]; then
    echo "Error: Query file not found at $QUERY_FILE" >&2
    exit 1
fi

STDERR_FILE=$(mktemp)
JSON_RESPONSE=$(gh api graphql \
  -F owner="$OWNER" \
  -F repo="$REPO" \
  -F limit="$LIMIT" \
  -F direction="$DIRECTION" \
  -f query="$(cat "$QUERY_FILE")" 2>"$STDERR_FILE")
GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
    echo "Error: Failed to query GitHub API (exit code: $GH_STATUS)." >&2
    cat "$STDERR_FILE" >&2
    rm -f "$STDERR_FILE"
    exit 1
fi
rm -f "$STDERR_FILE"

if [[ "$RAW_OUTPUT" == "true" ]]; then
    echo "$JSON_RESPONSE"
else
    # Token-efficient Markdown summary
    echo "$JSON_RESPONSE" | jq -r '
        .data.repository.pullRequests.nodes[] |
        "### PR #\(.number): \(.title)\n" +
        ([.reviewThreads.nodes[] | select(.isResolved == false) | 
          "* **Thread \(.id)**: \(.comments.nodes[-1].body | sub("\n.*"; "..."))"
        ] | join("\n"))
    ' | sed '/^$/d'
fi
