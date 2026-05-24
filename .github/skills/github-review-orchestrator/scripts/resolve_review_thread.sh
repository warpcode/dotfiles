#!/bin/bash
# Resolve a GitHub PR review thread using GraphQL
# Usage: ./resolve_thread.sh <thread_id>

THREAD_ID=$1

if [[ -z "$THREAD_ID" ]]; then
    echo "Usage: $0 <thread_id>" >&2
    exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

gh api graphql -f query="@${SCRIPT_DIR}/../queries/resolve_review_thread.gql" -f threadId="$THREAD_ID"


