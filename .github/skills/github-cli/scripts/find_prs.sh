#!/bin/bash
# Find and filter pull requests by review status, commit activity, and author responsiveness.
#
# Usage:
#   ./find_prs.sh [owner] [repo] [flags]
#
# Filters (can specify one or run default overview):
#   --approved                         Find all approved pull requests
#   --commits-after-review             Find PRs where commits were made after a review
#   --no-commits-since-review          Find PRs where reviews were submitted but no commits made since
#   --author-response-prior-to-commit  Find PRs where author's last comment was prior to latest commit
#   --author-not-responded             Find PRs where author has not responded to repo owner / reviewer
#   --waiting-on-author                Find PRs needing author action (unresponsive, no commits, or prior response)
#   --all                              Show comprehensive categorized status summary of all PRs
#
# Options:
#   --state <OPEN|CLOSED|MERGED|ALL>   PR state (default: OPEN)
#   --limit <number>                   Max PRs to fetch (default: 50)
#   --direction <ASC|DESC>             Order direction by updated time (default: DESC)
#   --raw                              Output raw JSON of classified PRs
#   --help                             Show this help message

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
QUERY_FILE="${SCRIPT_DIR}/../queries/find_prs.gql"

if [[ ! -f "$QUERY_FILE" ]]; then
    echo "Error: Query file not found at $QUERY_FILE" >&2
    exit 1
fi

OWNER=""
REPO=""
FILTER=""
STATE="OPEN"
LIMIT=50
DIRECTION="DESC"
RAW_OUTPUT=false

# Argument parsing
while [[ $# -gt 0 ]]; do
    case "$1" in
        --approved)
            FILTER="approved"
            shift
            ;;
        --commits-after-review)
            FILTER="commits_after_review"
            shift
            ;;
        --no-commits-since-review|--no-commits)
            FILTER="no_commits_since_review"
            shift
            ;;
        --author-response-prior-to-commit)
            FILTER="author_response_prior_to_commit"
            shift
            ;;
        --author-not-responded|--unresponsive-author)
            FILTER="author_not_responded"
            shift
            ;;
        --waiting-on-author)
            FILTER="waiting_on_author"
            shift
            ;;
        --all|--overview)
            FILTER="all"
            shift
            ;;
        --state)
            STATE="${2^^}"
            shift 2
            ;;
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        --direction)
            DIRECTION="${2^^}"
            shift 2
            ;;
        --raw|--raw-output)
            RAW_OUTPUT=true
            shift
            ;;
        --help|-h)
            sed -n '2,/^set -euo pipefail/p' "$0" | sed 's/^# \?//' | head -n -1
            exit 0
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            echo "Run $0 --help for usage." >&2
            exit 1
            ;;
        *)
            if [[ -z "$OWNER" ]]; then
                OWNER="$1"
            elif [[ -z "$REPO" ]]; then
                REPO="$1"
            else
                echo "Error: Unexpected positional argument: $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Auto-detect owner/repo if not provided
if [[ -z "$OWNER" || -z "$REPO" ]]; then
    DETECTED_REPO=$(gh repo view --json owner,name -q '.owner.login + " " + .name' 2>/dev/null || true)
    if [[ -n "$DETECTED_REPO" ]]; then
        DETECTED_OWNER=$(awk '{print $1}' <<< "$DETECTED_REPO")
        DETECTED_NAME=$(awk '{print $2}' <<< "$DETECTED_REPO")
        OWNER="${OWNER:-$DETECTED_OWNER}"
        REPO="${REPO:-$DETECTED_NAME}"
    fi
fi

if [[ -z "$OWNER" || -z "$REPO" ]]; then
    echo "Error: Could not determine GitHub repository. Provide <owner> <repo> explicitly." >&2
    echo "Usage: $0 <owner> <repo> [flags]" >&2
    exit 1
fi

# Build states GraphQL flags
STATES_FLAGS=()
case "$STATE" in
    OPEN)
        STATES_FLAGS=("-F" "states[]=OPEN")
        ;;
    CLOSED)
        STATES_FLAGS=("-F" "states[]=CLOSED")
        ;;
    MERGED)
        STATES_FLAGS=("-F" "states[]=MERGED")
        ;;
    ALL)
        STATES_FLAGS=("-F" "states[]=OPEN" "-F" "states[]=CLOSED" "-F" "states[]=MERGED")
        ;;
    *)
        echo "Error: Invalid state '$STATE'. Valid values: OPEN, CLOSED, MERGED, ALL" >&2
        exit 1
        ;;
esac

STDERR_FILE=$(mktemp)
RAW_RESPONSE=$(gh api graphql \
  -F query="@$QUERY_FILE" \
  -F owner="$OWNER" \
  -F repo="$REPO" \
  -F limit="$LIMIT" \
  -F direction="$DIRECTION" \
  "${STATES_FLAGS[@]}" 2>"$STDERR_FILE")
GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
    echo "Error: Failed to query GitHub GraphQL API (exit code: $GH_STATUS)." >&2
    cat "$STDERR_FILE" >&2
    rm -f "$STDERR_FILE"
    exit 1
fi
rm -f "$STDERR_FILE"

# Check for GraphQL query level errors
if echo "$RAW_RESPONSE" | jq -e '.errors' >/dev/null 2>&1; then
    echo "Error: GraphQL query returned errors:" >&2
    echo "$RAW_RESPONSE" | jq -r '.errors[].message' >&2
    exit 1
fi

# JQ transformation and classification script
CLASSIFIED_JSON=$(echo "$RAW_RESPONSE" | jq '
  .data.repository as $repo |
  ($repo.owner.login // "") as $owner |
  [
    $repo.pullRequests.nodes[]? |
    . as $pr |
    ($pr.author.login // "unknown") as $author |
    ($pr.commits.nodes[-1].commit.committedDate // $pr.createdAt) as $latestCommitDate |
    ($pr.commits.nodes[-1].commit.oid // "") as $latestCommitOid |
    ($pr.commits.nodes[-1].commit.messageHeadline // "") as $latestCommitMsg |
    ([$pr.reviews.nodes[]? | select(.author.login != $author and .state != "PENDING")] | sort_by(.submittedAt) | last) as $latestReview |
    ($latestReview.submittedAt // null) as $latestReviewDate |
    ($latestReview.state // null) as $latestReviewState |
    ($latestReview.author.login // null) as $latestReviewer |
    ([($pr.comments.nodes[]?), ($pr.reviewThreads.nodes[]?.comments.nodes[]?)] | select(.) | map(select(.author.login == $author)) | sort_by(.createdAt) | last.createdAt // null) as $latestAuthorCommentDate |
    ([($pr.comments.nodes[]?), ($pr.reviewThreads.nodes[]?.comments.nodes[]?)] | select(.) | map(select(.author.login != $author and (.author.login == $owner or $owner == ""))) | sort_by(.createdAt) | last.createdAt // null) as $latestOwnerCommentDate |
    ([$latestReviewDate, $latestOwnerCommentDate] | map(select(. != null)) | sort | last // null) as $latestOwnerActivityDate |
    ($latestReviewDate != null and $latestCommitDate > $latestReviewDate) as $commitsAfterReview |
    ($latestReviewDate != null and $latestCommitDate <= $latestReviewDate) as $noCommitsSinceReview |
    ($latestAuthorCommentDate != null and $latestAuthorCommentDate < $latestCommitDate) as $authorResponsePriorToCommit |
    (if $latestOwnerActivityDate != null then
      ($latestAuthorCommentDate == null or $latestAuthorCommentDate < $latestOwnerActivityDate)
    else false end) as $authorNotResponded |
    ($pr.reviewDecision == "APPROVED" or $latestReviewState == "APPROVED") as $isApproved |
    {
      number: $pr.number,
      title: $pr.title,
      url: $pr.url,
      isDraft: $pr.isDraft,
      author: $author,
      baseRef: $pr.baseRefName,
      headRef: $pr.headRefName,
      reviewDecision: $pr.reviewDecision,
      isApproved: $isApproved,
      hasReviews: ($latestReviewDate != null),
      latestReviewState: $latestReviewState,
      latestReviewer: $latestReviewer,
      latestReviewDate: $latestReviewDate,
      latestCommitOid: $latestCommitOid,
      latestCommitMsg: $latestCommitMsg,
      latestCommitDate: $latestCommitDate,
      latestAuthorCommentDate: $latestAuthorCommentDate,
      latestOwnerActivityDate: $latestOwnerActivityDate,
      commitsAfterReview: $commitsAfterReview,
      noCommitsSinceReview: $noCommitsSinceReview,
      authorResponsePriorToCommit: $authorResponsePriorToCommit,
      authorNotResponded: $authorNotResponded,
      waitingOnAuthor: (
        ($isApproved == false) and (
          ($noCommitsSinceReview and ($latestReviewState == "CHANGES_REQUESTED" or $latestReviewState == "COMMENTED")) or
          ($authorNotResponded and $latestOwnerActivityDate != null and $latestReviewState == "CHANGES_REQUESTED") or
          ($authorResponsePriorToCommit and $noCommitsSinceReview and $latestReviewDate != null)
        )
      )
    }
  ]
')

if [[ "$RAW_OUTPUT" == "true" ]]; then
    if [[ -n "$FILTER" && "$FILTER" != "all" ]]; then
        case "$FILTER" in
            approved)
                echo "$CLASSIFIED_JSON" | jq '[.[] | select(.isApproved == true)]'
                ;;
            commits_after_review)
                echo "$CLASSIFIED_JSON" | jq '[.[] | select(.commitsAfterReview == true)]'
                ;;
            no_commits_since_review)
                echo "$CLASSIFIED_JSON" | jq '[.[] | select(.noCommitsSinceReview == true)]'
                ;;
            author_response_prior_to_commit)
                echo "$CLASSIFIED_JSON" | jq '[.[] | select(.authorResponsePriorToCommit == true)]'
                ;;
            author_not_responded)
                echo "$CLASSIFIED_JSON" | jq '[.[] | select(.authorNotResponded == true)]'
                ;;
            waiting_on_author)
                echo "$CLASSIFIED_JSON" | jq '[.[] | select(.waitingOnAuthor == true)]'
                ;;
        esac
    else
        echo "$CLASSIFIED_JSON"
    fi
    exit 0
fi

# Token-efficient Markdown reporting
format_pr_list() {
    local filter_jq="$1"
    local empty_msg="$2"
    local items
    items=$(echo "$CLASSIFIED_JSON" | jq -r "
      [ .[] | select($filter_jq) ] |
      if length == 0 then
        \"  _($empty_msg)_\n\"
      else
        .[] |
        \"* **#\(.number)**: [\(.title)](\(.url))\n\" +
        \"  - **Author**: @\(.author) | **Branch**: \`\(.headRef)\`\n\" +
        \"  - **Review State**: \(.latestReviewState // .reviewDecision // \"NONE\")\" +
        (if .latestReviewDate != null then \" (on \(.latestReviewDate | sub(\"T.*\"; \"\")))\" else \"\" end) +
        \" | **Latest Commit**: \(.latestCommitDate | sub(\"T.*\"; \"\"))\n\" +
        (if .commitsAfterReview then \"  - ⚠️ *New commits pushed after last review*\n\" else \"\" end) +
        (if .authorNotResponded and .latestOwnerActivityDate != null then \"  - ⏳ *Author has not responded to owner activity*\n\" else \"\" end) +
        (if .authorResponsePriorToCommit then \"  - 📝 *Author response occurred prior to latest commit*\n\" else \"\" end)
      end
    ")
    echo "$items"
}

echo "## Pull Request Status: $OWNER/$REPO ($STATE)"
echo ""

case "$FILTER" in
    approved)
        echo "### ✅ Approved Pull Requests"
        format_pr_list ".isApproved == true" "No approved pull requests found"
        ;;
    commits_after_review)
        echo "### 🔄 Pull Requests with Commits After Review (Ready for Re-Review)"
        format_pr_list ".commitsAfterReview == true" "No pull requests with commits after review"
        ;;
    no_commits_since_review)
        echo "### ⏳ Pull Requests with No Commits Since Review"
        format_pr_list ".noCommitsSinceReview == true" "No pull requests waiting on commits"
        ;;
    author_response_prior_to_commit)
        echo "### 📝 Pull Requests with Author Response Prior to Latest Commit"
        format_pr_list ".authorResponsePriorToCommit == true" "No pull requests matching criteria"
        ;;
    author_not_responded)
        echo "### ⏳ Pull Requests where Author Has Not Responded to Owner"
        format_pr_list ".authorNotResponded == true and .latestOwnerActivityDate != null" "No unresponsive author pull requests found"
        ;;
    waiting_on_author)
        echo "### ⏳ Pull Requests Waiting on Author Action / Response"
        format_pr_list ".waitingOnAuthor == true" "No pull requests waiting on author action"
        ;;
    all|"")
        echo "### 1. ✅ Approved Pull Requests (Ready to Merge)"
        format_pr_list ".isApproved == true" "None"

        echo "### 2. 🔄 Commits Made After Review (Ready for Re-Review)"
        format_pr_list ".commitsAfterReview == true" "None"

        echo "### 3. ⏳ Waiting on Author / Review Pending Action"
        format_pr_list ".waitingOnAuthor == true" "None"

        echo "### 4. 🆕 Awaiting Initial Review"
        format_pr_list ".hasReviews == false and .isApproved == false" "None"
        ;;
esac
