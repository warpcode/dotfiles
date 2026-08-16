#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
QUERY_FILE="${SCRIPT_DIR}/../queries/find_prs.gql"

if [[ ! -f "$QUERY_FILE" ]]; then
  echo "Error: Query file not found at $QUERY_FILE" >&2
  exit 1
fi

owner="$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo '')"
repo="$(gh repo view --json name -q '.name' 2>/dev/null || echo '')"
filter=""
state="OPEN"
limit=50
direction="DESC"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./list_pull_requests.sh [OPTIONS]"
      echo ""
      echo "List and filter pull requests with triage statuses (e.g. approved, awaiting author, new commits)."
      echo ""
      echo "Options:"
      echo "  --owner <value>                    Repository owner (default: auto-detected)"
      echo "  --repo <value>                     Repository name (default: auto-detected)"
      echo "  --approved                         Find all approved pull requests"
      echo "  --commits-after-review             Find PRs where commits were made after a review"
      echo "  --no-commits-since-review          Find PRs where reviews were submitted but no commits made since"
      echo "  --author-response-prior-to-commit  Find PRs where author's last comment was prior to latest commit"
      echo "  --author-not-responded             Find PRs where author has not responded to repo owner / reviewer"
      echo "  --waiting-on-author                Find PRs needing author action (unresponsive, no commits, or prior response)"
      echo "  --all                              Show comprehensive categorized status summary of all PRs"
      echo "  --state <value>                    PR state: OPEN, CLOSED, MERGED, ALL (default: OPEN)"
      echo "  --limit <value>                    Max PRs to fetch (default: 50)"
      echo "  --direction <value>                Order direction: ASC, DESC (default: DESC)"
      echo "  -h, --help                         Show this help message"
      exit 0
      ;;
    --owner)
      owner="$2"
      shift 2
      ;;
    --repo)
      repo="$2"
      shift 2
      ;;
    --approved)
      filter="approved"
      shift
      ;;
    --commits-after-review)
      filter="commits_after_review"
      shift
      ;;
    --no-commits-since-review|--no-commits)
      filter="no_commits_since_review"
      shift
      ;;
    --author-response-prior-to-commit)
      filter="author_response_prior_to_commit"
      shift
      ;;
    --author-not-responded|--unresponsive-author)
      filter="author_not_responded"
      shift
      ;;
    --waiting-on-author)
      filter="waiting_on_author"
      shift
      ;;
    --all|--overview)
      filter="all"
      shift
      ;;
    --state)
      state="$2"
      shift 2
      ;;
    --limit)
      limit="$2"
      shift 2
      ;;
    --direction)
      direction="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$owner" ]]; then
  echo "Error: --owner is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$repo" ]]; then
  echo "Error: --repo is required. Use --help for usage." >&2
  exit 1
fi

state="${state^^}"
direction="${direction^^}"

states_flags=()
case "$state" in
  OPEN)
    states_flags=("-F" "states[]=OPEN")
    ;;
  CLOSED)
    states_flags=("-F" "states[]=CLOSED")
    ;;
  MERGED)
    states_flags=("-F" "states[]=MERGED")
    ;;
  ALL)
    states_flags=("-F" "states[]=OPEN" "-F" "states[]=CLOSED" "-F" "states[]=MERGED")
    ;;
  *)
    echo "Error: Invalid state '$state'. Valid values: OPEN, CLOSED, MERGED, ALL" >&2
    exit 1
    ;;
esac

# JQ classification definition (evaluated using gh CLI's built-in jq engine)
# shellcheck disable=SC2016
classify_defs='
def classify_prs:
  .data.repository as $repo |
  ($repo.owner.login // "") as $owner |
  ($repo.name // "") as $repoName |
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
  ];
'

# shellcheck disable=SC2016
format_helpers='
def format_item:
  "* **#\(.number)**: [\(.title)](\(.url))\n" +
  "  - **Author**: @\(.author) | **Branch**: `\(.headRef)`\n" +
  "  - **Review State**: \(.latestReviewState // .reviewDecision // "NONE")" +
  (if .latestReviewDate != null then " (on \(.latestReviewDate | sub("T.*"; ""))" else "" end) +
  " | **Latest Commit**: \(.latestCommitDate | sub("T.*"; ""))\n" +
  (if .commitsAfterReview then "  - ⚠️ *New commits pushed after last review*\n" else "" end) +
  (if .authorNotResponded and .latestOwnerActivityDate != null then "  - ⏳ *Author has not responded to owner activity*\n" else "" end) +
  (if .authorResponsePriorToCommit then "  - 📝 *Author response occurred prior to latest commit*\n" else "" end);

def format_section(title; empty_msg):
  "### " + title + "\n" +
  (if length == 0 then "  _(" + empty_msg + ")_\n\n" else (map(format_item) | join("")) + "\n" end);
'

header="(\"## Pull Request Status: \" + (.data.repository.owner.login // \"$owner\") + \"/\" + (.data.repository.name // \"$repo\") + \" ($state)\\n\\n\")"

case "$filter" in
  approved)
    jq_query="${classify_defs} ${format_helpers} ${header} as \$hdr | classify_prs as \$prs | \$hdr + (\$prs | map(select(.isApproved == true)) | format_section(\"✅ Approved Pull Requests\"; \"No approved pull requests found\"))"
    ;;
  commits_after_review)
    jq_query="${classify_defs} ${format_helpers} ${header} as \$hdr | classify_prs as \$prs | \$hdr + (\$prs | map(select(.commitsAfterReview == true)) | format_section(\"🔄 Pull Requests with Commits After Review (Ready for Re-Review)\"; \"No pull requests with commits after review\"))"
    ;;
  no_commits_since_review)
    jq_query="${classify_defs} ${format_helpers} ${header} as \$hdr | classify_prs as \$prs | \$hdr + (\$prs | map(select(.noCommitsSinceReview == true)) | format_section(\"⏳ Pull Requests with No Commits Since Review\"; \"No pull requests waiting on commits\"))"
    ;;
  author_response_prior_to_commit)
    jq_query="${classify_defs} ${format_helpers} ${header} as \$hdr | classify_prs as \$prs | \$hdr + (\$prs | map(select(.authorResponsePriorToCommit == true)) | format_section(\"📝 Pull Requests with Author Response Prior to Latest Commit\"; \"No pull requests matching criteria\"))"
    ;;
  author_not_responded)
    jq_query="${classify_defs} ${format_helpers} ${header} as \$hdr | classify_prs as \$prs | \$hdr + (\$prs | map(select(.authorNotResponded == true and .latestOwnerActivityDate != null)) | format_section(\"⏳ Pull Requests where Author Has Not Responded to Owner\"; \"No unresponsive author pull requests found\"))"
    ;;
  waiting_on_author)
    jq_query="${classify_defs} ${format_helpers} ${header} as \$hdr | classify_prs as \$prs | \$hdr + (\$prs | map(select(.waitingOnAuthor == true)) | format_section(\"⏳ Pull Requests Waiting on Author Action / Response\"; \"No pull requests waiting on author action\"))"
    ;;
  all|"")
    jq_query="${classify_defs} ${format_helpers} ${header} as \$hdr | classify_prs as \$prs | \$hdr + (\$prs | map(select(.isApproved == true)) | format_section(\"1. ✅ Approved Pull Requests (Ready to Merge)\"; \"None\")) + (\$prs | map(select(.commitsAfterReview == true)) | format_section(\"2. 🔄 Commits Made After Review (Ready for Re-Review)\"; \"None\")) + (\$prs | map(select(.waitingOnAuthor == true)) | format_section(\"3. ⏳ Waiting on Author / Review Pending Action\"; \"None\")) + (\$prs | map(select(.hasReviews == false and .isApproved == false)) | format_section(\"4. 🆕 Awaiting Initial Review\"; \"None\"))"
    ;;
esac

gh api graphql \
  -F query="@$QUERY_FILE" \
  -F owner="$owner" \
  -F repo="$repo" \
  -F limit="$limit" \
  -F direction="$direction" \
  "${states_flags[@]}" \
  -q "$jq_query"
