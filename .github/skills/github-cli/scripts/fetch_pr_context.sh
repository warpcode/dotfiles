#!/bin/bash
# Fetch comprehensive PR state for review context.
# Primary source of a PR's state: comments, reviews, threads, and readiness.
# Usage: ./fetch_pr_context.sh <owner> <repo> <pr_number> [--raw]

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
PR_NUMBER=${ARGS[2]}

if [[ -z "$OWNER" || -z "$REPO" || -z "$PR_NUMBER" ]]; then
    echo "Usage: $0 <owner> <repo> <pr_number> [--raw]" >&2
    exit 1
fi

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
QUERY_FILE="${SCRIPT_DIR}/../queries/pr_state.gql"

if [[ ! -f "$QUERY_FILE" ]]; then
    echo "Error: Query file not found at $QUERY_FILE" >&2
    exit 1
fi

# Fetch comprehensive PR state via GraphQL
STDERR_FILE=$(mktemp)
STATE_RESPONSE=$(gh api graphql \
  -F query="@$QUERY_FILE" \
  -F owner="$OWNER" \
  -F repo="$REPO" \
  -F pr="$PR_NUMBER" 2>"$STDERR_FILE")
GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
    echo "Error: Failed to fetch PR #$PR_NUMBER state (exit code: $GH_STATUS)." >&2
    cat "$STDERR_FILE" >&2
    rm -f "$STDERR_FILE"
    exit 1
fi
rm -f "$STDERR_FILE"

# Check for GraphQL query level errors
if echo "$STATE_RESPONSE" | jq -e '.errors' >/dev/null 2>&1; then
    echo "Error: GraphQL query returned errors:" >&2
    echo "$STATE_RESPONSE" | jq -r '.errors[].message' >&2
    exit 1
fi

if [[ "$RAW_OUTPUT" == "true" ]]; then
    # Full state JSON + diff.
    # State is piped via stdin and diff read via --rawfile to avoid the
    # OS "Argument list too long" limit on large PRs.
    STDERR_FILE=$(mktemp)
    DIFF_FILE=$(mktemp)
    if ! gh pr diff "$PR_NUMBER" --repo "${OWNER}/${REPO}" > "$DIFF_FILE" 2>"$STDERR_FILE"; then
        echo "Error: Failed to fetch diff for PR #$PR_NUMBER." >&2
        cat "$STDERR_FILE" >&2
        rm -f "$STDERR_FILE" "$DIFF_FILE"
        exit 1
    fi
    rm -f "$STDERR_FILE"
    echo "$STATE_RESPONSE" | jq --rawfile diff "$DIFF_FILE" \
        '{headRefOid: .data.repository.pullRequest.headRefOid, state: ., diff: $diff}'
    rm -f "$DIFF_FILE"
else
    # Token-efficient markdown summary of PR state.
    # ponytail: counts use fetched nodes (first:100 per collection); pagination is
    # the upgrade path if a PR exceeds 100 comments/threads/commits.
    echo "$STATE_RESPONSE" | jq -r '
        def icon($b): if $b then "✅" else "❌" end;

        .data.repository.pullRequest as $pr |
        .data.repository.owner.login as $owner |
        $pr.author.login as $author |

        ($pr.comments.nodes | length) as $issue_comments |
        ([$pr.reviewThreads.nodes[].comments.nodes[]] | length) as $inline_comments |
        ($issue_comments + $inline_comments) as $total_comments |
        ([$pr.comments.nodes[].author.login] + [$pr.reviewThreads.nodes[].comments.nodes[].author.login]) as $all_authors |
        ($all_authors | map(select(. == $author)) | length) as $author_comments |
        ($all_authors | map(select(. == $owner)) | length) as $owner_comments |

        ($pr.reviews.nodes | length) as $reviews_total |
        ($pr.reviews.nodes | map(select(.state == "CHANGES_REQUESTED")) | length) as $changes_requested |
        ($pr.reviews.nodes | map(select(.state == "CHANGES_REQUESTED")) | map(.submittedAt) | max) as $last_cr_at |
        (if $changes_requested > 0 then
            ($pr.commits.nodes | map(select(.commit.committedDate > $last_cr_at)) | length)
        else 0 end) as $commits_after_cr |

        ($pr.reviewThreads.nodes | length) as $threads_total |
        ($pr.reviewThreads.nodes | map(select(.isResolved)) | length) as $threads_resolved |
        ($pr.reviewThreads.nodes | map(select(.isResolved | not)) | length) as $threads_unresolved |
        ($pr.reviewThreads.nodes | map(select(.isOutdated)) | length) as $threads_outdated |
        ($pr.reviewThreads.nodes | map(select(.isOutdated | not)) | length) as $threads_current |
        ($pr.reviewThreads.nodes | map(select(.isResolved and .resolvedBy.login == $author)) | length) as $author_resolved |
        ($pr.reviewThreads.nodes | map(select((.isOutdated | not) and (.comments.nodes[-1].author.login == $author))) | length) as $author_last_current |
        ($pr.reviewThreads.nodes | map(select((.isOutdated | not) and (.comments.nodes[-1].author.login != $author))) | length) as $reviewer_last_current |

        ($pr.reviewRequests.totalCount > 0) as $author_requested_review |
        ($pr.isDraft | not) as $not_draft |
        ($threads_total > 0 and $threads_outdated == $threads_total) as $all_threads_outdated |
        ($reviewer_last_current == 0) as $no_reviewer_waiting |
        (($changes_requested == 0) or ($commits_after_cr > 0)) as $responded_to_review |
        ($author_requested_review or ($reviews_total == 0)) as $review_requested |
        ($not_draft and $no_reviewer_waiting and $responded_to_review and $review_requested) as $ready |
        (if $ready then "" else
            ([
                (if $not_draft then "" else "PR is a draft" end),
                (if $no_reviewer_waiting then "" else "\($reviewer_last_current) current thread(s) awaiting author response" end),
                (if $responded_to_review then "" else "no commits since last CHANGES_REQUESTED" end),
                (if $review_requested then "" else "author has not requested a review" end)
            ] | map(select(. != "")) | join("; "))
        end) as $blockers |

        [
            "# PR #\($pr.number): \($pr.title)",
            "",
            "HEAD_OID: \($pr.headRefOid)",
            "Branch: \($pr.headRefName) → \($pr.baseRefName)",
            "Author: @\($author) (repo owner: @\($owner))",
            "State: \($pr.state)\(if $pr.isDraft then " (draft)" else "" end) | Review decision: \($pr.reviewDecision // "NONE")",
            "Stats: \($pr.changedFiles) files changed, +\($pr.additions) -\($pr.deletions) lines",
            "",
            "## Comments",
            "- Total: \($total_comments) (\($issue_comments) issue + \($inline_comments) inline)",
            "- By author: \($author_comments)",
            "- By repo owner: \($owner_comments)",
            "",
            "## Reviews",
            "- Total: \($reviews_total)",
            "- Changes requested: \($changes_requested)",
            "- Commits after last CHANGES_REQUESTED: \(if $changes_requested > 0 then $commits_after_cr else "n/a" end)",
            "",
            "## Review Threads",
            "- Total: \($threads_total)",
            "- Resolved: \($threads_resolved) (\($author_resolved) by author)",
            "- Unresolved: \($threads_unresolved)",
            "- Outdated: \($threads_outdated)",
            "- Current: \($threads_current) (author last: \($author_last_current), reviewer last: \($reviewer_last_current))",
            "",
            "## Ready for Review?",
            "- Not a draft: \(icon($not_draft))",
            "- All threads outdated: \(if $threads_total == 0 then "n/a (no threads)" else "\(icon($all_threads_outdated)) (\($threads_outdated)/\($threads_total))" end)",
            "- No reviewer waiting on current threads: \(icon($no_reviewer_waiting)) (\($reviewer_last_current) current thread(s) with reviewer last)",
            "- Responded to CHANGES_REQUESTED: \(icon($responded_to_review)) (\(if $changes_requested > 0 then "\($commits_after_cr) commit(s) after" else "no changes requested" end))",
            "- Author requested review: \(icon($review_requested))",
            "- **Verdict: \(if $ready then "READY FOR REVIEW" else "NOT READY" end)**\(if $ready then "" else " — \($blockers)" end)"
        ] | join("\n")
    '
fi
