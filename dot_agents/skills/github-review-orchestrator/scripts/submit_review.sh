#!/bin/bash
# Submit a PR review using GraphQL mutations.
# Supports both line-level and file-level comments in a single atomic review.
# Usage: ./submit_review.sh <owner> <repo> <pr_number> <payload_file> [--raw]
#
# Payload format (JSON):
# {
#   "event": "APPROVE" | "REQUEST_CHANGES" | "COMMENT",
#   "body": "Review body text",
#   "comments": [
#     {
#       "path": "file/path",
#       "body": "Comment text",
#       "line": 42,                    // Optional: omit for file-level
#       "side": "RIGHT",               // Optional: LEFT or RIGHT (default: RIGHT)
#       "subject_type": "file"          // Optional: "file" for file-level comments
#     }
#   ]
# }

set -euo pipefail

RAW_OUTPUT=false
ARGS=()
for arg in "$@"; do
    if [[ "$arg" == "--raw" ]]; then
        RAW_OUTPUT=true
    else
        ARGS+=("$arg")
    fi
done

OWNER="${ARGS[0]:-}"
REPO="${ARGS[1]:-}"
PR_NUMBER="${ARGS[2]:-}"
PAYLOAD_FILE="${ARGS[3]:-}"

if [[ -z "$OWNER" || -z "$REPO" || -z "$PR_NUMBER" || -z "$PAYLOAD_FILE" ]]; then
    echo "Usage: $0 <owner> <repo> <pr_number> <payload_file> [--raw]" >&2
    exit 1
fi

if [[ ! -f "$PAYLOAD_FILE" ]]; then
    echo "Error: Payload file not found: $PAYLOAD_FILE" >&2
    exit 1
fi

# Step 1: Resolve the PR node ID
PR_NODE_ID=$(gh api graphql \
  -F owner="$OWNER" \
  -F repo="$REPO" \
  -F pr="$PR_NUMBER" \
  -f query='
    query($owner: String!, $repo: String!, $pr: Int!) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $pr) { id }
      }
    }' \
  --jq '.data.repository.pullRequest.id')

if [[ -z "$PR_NODE_ID" || "$PR_NODE_ID" == "null" ]]; then
    echo "Error: Could not resolve PR #$PR_NUMBER in $OWNER/$REPO" >&2
    exit 1
fi

# Parse payload
EVENT=$(jq -r '.event // "COMMENT"' "$PAYLOAD_FILE")
BODY=$(jq -r '.body // ""' "$PAYLOAD_FILE")
COMMENT_COUNT=$(jq -r '.comments | length' "$PAYLOAD_FILE")

# Step 2: Create a pending review
REVIEW_ID=$(gh api graphql \
  -F prId="$PR_NODE_ID" \
  -F body="$BODY" \
  -f query='
    mutation($prId: ID!, $body: String) {
      addPullRequestReview(input: {pullRequestId: $prId, body: $body}) {
        pullRequestReview { id }
      }
    }' \
  --jq '.data.addPullRequestReview.pullRequestReview.id')

if [[ -z "$REVIEW_ID" || "$REVIEW_ID" == "null" ]]; then
    echo "Error: Failed to create pending review" >&2
    exit 1
fi

# Cleanup helper: delete the pending review on failure
cleanup_review() {
    gh api graphql \
      -F reviewId="$REVIEW_ID" \
      -f query='
        mutation($reviewId: ID!) {
          deletePullRequestReview(input: {pullRequestReviewId: $reviewId}) {
            pullRequestReview { id }
          }
        }' >/dev/null 2>&1 || true
}

# Step 3: Add comment threads
for i in $(seq 0 $((COMMENT_COUNT - 1))); do
    C_PATH=$(jq -r  ".comments[$i].path" "$PAYLOAD_FILE")
    C_BODY=$(jq -r  ".comments[$i].body" "$PAYLOAD_FILE")
    C_LINE=$(jq -r  ".comments[$i].line // empty" "$PAYLOAD_FILE")
    C_SIDE=$(jq -r  ".comments[$i].side // \"RIGHT\"" "$PAYLOAD_FILE")
    C_SUBJECT=$(jq -r ".comments[$i].subject_type // .comments[$i].subjectType // empty" "$PAYLOAD_FILE")

    if [[ "$C_SUBJECT" == "file" || "$C_SUBJECT" == "FILE" ]] || [[ -z "$C_LINE" ]]; then
        # File-level comment (no line number)
        if ! gh api graphql \
          -F reviewId="$REVIEW_ID" \
          -F path="$C_PATH" \
          -F body="$C_BODY" \
          -f query='
            mutation($reviewId: ID!, $path: String!, $body: String!) {
              addPullRequestReviewThread(input: {
                pullRequestReviewId: $reviewId
                path: $path
                body: $body
                subjectType: FILE
              }) {
                thread { id }
              }
            }' >/dev/null 2>&1; then
            echo "Error: Failed to add file-level comment on $C_PATH" >&2
            cleanup_review
            exit 1
        fi
    else
        # Line-level comment
        if ! gh api graphql \
          -F reviewId="$REVIEW_ID" \
          -F path="$C_PATH" \
          -F body="$C_BODY" \
          -F line="$C_LINE" \
          -F side="$C_SIDE" \
          -f query='
            mutation($reviewId: ID!, $path: String!, $body: String!, $line: Int!, $side: DiffSide!) {
              addPullRequestReviewThread(input: {
                pullRequestReviewId: $reviewId
                path: $path
                body: $body
                line: $line
                side: $side
              }) {
                thread { id }
              }
            }' >/dev/null 2>&1; then
            echo "Error: Failed to add line-level comment on $C_PATH:$C_LINE" >&2
            cleanup_review
            exit 1
        fi
    fi
done

# Step 4: Submit the review
RESPONSE=$(gh api graphql \
  -F reviewId="$REVIEW_ID" \
  -F event="$EVENT" \
  -f query='
    mutation($reviewId: ID!, $event: PullRequestReviewEvent!) {
      submitPullRequestReview(input: {pullRequestReviewId: $reviewId, event: $event}) {
        pullRequestReview {
          id
          state
          url
        }
      }
    }' 2>&1)

if [[ $? -ne 0 ]]; then
    echo "Error: Failed to submit review: $RESPONSE" >&2
    cleanup_review
    exit 1
fi

if [[ "$RAW_OUTPUT" == "true" ]]; then
    echo "$RESPONSE"
else
    echo "$RESPONSE" | jq -r '
      .data.submitPullRequestReview.pullRequestReview |
      "Review ID: \(.id)",
      "State: \(.state)",
      "URL: \(.url)"
    '
fi
