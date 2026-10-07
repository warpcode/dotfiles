#!/usr/bin/env bash
# verify_delivery.sh: Deterministically verify whether a completed Jules session pushed changes or opened a PR.
# Usage: verify_delivery.sh <repo> <source-branch> [base-branch]
# Example: verify_delivery.sh warpcode/cloakenv feat/memory-scrub main

set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <owner/repo> <source-branch> [base-branch]" >&2
    exit 1
fi

REPO="$1"
BRANCH="$2"
BASE="${3:-main}"

echo "=== Delivery Audit: $REPO ($BRANCH -> $BASE) ==="

# 1. Check if remote branch exists and has commits ahead of base
if git ls-remote --exit-code --heads "git@github.com:$REPO.git" "$BRANCH" >/dev/null 2>&1; then
    AHEAD=$(git log --oneline "origin/$BASE..origin/$BRANCH" 2>/dev/null | wc -l || echo "0")
    echo "Remote Branch: EXISTS ($AHEAD commit(s) ahead of $BASE)"
else
    echo "Remote Branch: MISSING (Session never pushed to remote)"
fi

# 2. Check for associated PR via gh
PR_JSON=$(gh pr list --repo "$REPO" --head "$BRANCH" --state all --json number,title,state,url --jq '.[0] // empty' 2>/dev/null || true)

if [ -n "$PR_JSON" ]; then
    echo "Pull Request:"
    echo "$PR_JSON" | jq -r '"- #\(.number): \(.title) [\(.state)] (\(.url))"'
else
    echo "Pull Request: NONE (No pull request exists for this branch)"
fi

