#!/bin/bash
# Fetch comprehensive pull request details: summary table, merge readiness checks, review stats, description, and comments.
# Usage: ./get_pull_request.sh [OPTIONS]

set -euo pipefail
export GH_PAGER=""
export PAGER=cat

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
QUERY_FILE="${SCRIPT_DIR}/../queries/pr_state.gql"

if [[ ! -f "$QUERY_FILE" ]]; then
  echo "Error: Query file not found at $QUERY_FILE" >&2
  exit 1
fi

owner="$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo '')"
repo="$(gh repo view --json name -q '.name' 2>/dev/null || echo '')"
pull_number=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./get_pull_request.sh [OPTIONS]"
      echo ""
      echo "Fetch comprehensive pull request status, merge readiness checks, reviews, comments, and stats."
      echo ""
      echo "Options:"
      echo "  --owner <value>        Repository owner (auto-detected by default)"
      echo "  --repo <value>         Repository name (auto-detected by default)"
      echo "  --pull-number <value>  Pull request number (Required)"
      echo "  -h, --help             Show this help message"
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
    --pull-number)
      pull_number="$2"
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
if [[ -z "$pull_number" ]]; then
  echo "Error: --pull-number is required. Use --help for usage." >&2
  exit 1
fi

STDERR_FILE=$(mktemp)
trap 'rm -f "$STDERR_FILE"' EXIT

GH_STATUS=0
STATE_RESPONSE=$(gh api graphql \
  -F query="@$QUERY_FILE" \
  -F owner="$owner" \
  -F repo="$repo" \
  -F pr="$pull_number" 2>"$STDERR_FILE") || GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
  echo "Error: Failed to fetch PR #$pull_number state (exit code: $GH_STATUS)." >&2
  cat "$STDERR_FILE" >&2
  exit 1
fi

# Check for GraphQL query level errors
if echo "$STATE_RESPONSE" | jq -e '.errors' >/dev/null 2>&1; then
  echo "Error: GraphQL query returned errors:" >&2
  echo "$STATE_RESPONSE" | jq -r '.errors[].message' >&2
  exit 1
fi

if echo "$STATE_RESPONSE" | jq -e '.data.repository.pullRequest == null' >/dev/null 2>&1; then
  echo "Error: Pull request #$pull_number not found in ${owner}/${repo}." >&2
  exit 1
fi

BRANCH_NAME=$(jq -r '.data.repository.pullRequest.headRefName // empty' <<< "$STATE_RESPONSE")
BASE_BRANCH=$(jq -r '.data.repository.pullRequest.baseRefName // empty' <<< "$STATE_RESPONSE")

# Local checks (Syntax / Interactive Safety / Scope Hygiene)
SYNTAX_ERRORS=()
SAFETY_VIOLATIONS=()
SCOPE_VIOLATIONS=()

if [[ -n "$BASE_BRANCH" && -n "$BRANCH_NAME" ]] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git fetch origin "$BASE_BRANCH" "$BRANCH_NAME" >/dev/null 2>&1 || true

  mapfile -t MODIFIED_FILES < <(git diff --name-only "origin/${BASE_BRANCH}...origin/${BRANCH_NAME}" 2>/dev/null || true)

  CANDIDATE_FILES=()

  for file in "${MODIFIED_FILES[@]}"; do
    [[ -z "$file" ]] && continue

    if [[ "$file" == *.zsh || "$file" == bin/df.* || "$file" == *.sh ]]; then
      CANDIDATE_FILES+=("$file")
    fi

    # Scope Hygiene / Obsolete directory check
    for dir in "coding/tmp" "legacy" "tmp"; do
      if [[ "$file" == "$dir/"* ]]; then
        SCOPE_VIOLATIONS+=("$file ($dir)")
      fi
    done
  done

  if [[ ${#CANDIDATE_FILES[@]} -gt 0 ]]; then
    TARGET_REF="origin/${BRANCH_NAME}"
    mapfile -t EXISTING_FILES < <(git ls-tree -r --name-only "$TARGET_REF" -- "${CANDIDATE_FILES[@]}" 2>/dev/null || true)

    if [[ ${#EXISTING_FILES[@]} -gt 0 ]]; then
      ARCHIVE_DIR=$(mktemp -d)
      if git archive "$TARGET_REF" -- "${EXISTING_FILES[@]}" 2>/dev/null | tar -x -C "$ARCHIVE_DIR" 2>/dev/null; then
        for file in "${CANDIDATE_FILES[@]}"; do
          TEMP_FILE="$ARCHIVE_DIR/$file"
          if [[ -f "$TEMP_FILE" ]]; then
            # Syntax check
            if [[ "$file" == *.sh ]]; then
              if ! bash -n "$TEMP_FILE" 2>/dev/null; then
                SYNTAX_ERRORS+=("$file")
              fi
            else
              if ! zsh -n "$TEMP_FILE" 2>/dev/null; then
                SYNTAX_ERRORS+=("$file")
              fi
            fi

            # Interactive safety: Zsh functions must use return, not exit
            if [[ "$file" == *.zsh || "$file" == bin/df.* ]]; then
              if grep -E '^\s*exit\s+' "$TEMP_FILE" >/dev/null 2>&1; then
                SAFETY_VIOLATIONS+=("$file")
              fi
            fi
          fi
        done
      fi
      rm -rf "$ARCHIVE_DIR"
    fi
  fi
fi

if [[ ${#SYNTAX_ERRORS[@]} -gt 0 ]]; then
  SYNTAX_JSON=$(printf '%s\n' "${SYNTAX_ERRORS[@]}" | jq -R . | jq -s .)
else
  SYNTAX_JSON="[]"
fi
if [[ ${#SAFETY_VIOLATIONS[@]} -gt 0 ]]; then
  SAFETY_JSON=$(printf '%s\n' "${SAFETY_VIOLATIONS[@]}" | jq -R . | jq -s .)
else
  SAFETY_JSON="[]"
fi
if [[ ${#SCOPE_VIOLATIONS[@]} -gt 0 ]]; then
  SCOPE_JSON=$(printf '%s\n' "${SCOPE_VIOLATIONS[@]}" | jq -R . | jq -s .)
else
  SCOPE_JSON="[]"
fi

LOCAL_CHECKS_JSON=$(jq -n \
  --argjson syntax "$SYNTAX_JSON" \
  --argjson safety "$SAFETY_JSON" \
  --argjson scope "$SCOPE_JSON" \
  '{syntax_errors: $syntax, safety_violations: $safety, scope_violations: $scope}')

# Token-efficient markdown summary of PR state, merge checks, description, and comments.
# ponytail: counts use fetched nodes (first:100 per collection); pagination is
# the upgrade path if a PR exceeds 100 comments/threads/commits.
echo "$STATE_RESPONSE" | jq -r --argjson local "$LOCAL_CHECKS_JSON" '
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
  ($pr.reviews.nodes | map(select(.state == "APPROVED")) | length) as $reviews_approved |
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
  ($author_requested_review or ($reviews_total == 0)) as $review_requested |
  ([$pr.assignees.nodes[].login] | if length > 0 then map("@" + .) | join(", ") else "None" end) as $assignees |
  ([$pr.labels.nodes[].name] | if length > 0 then join(", ") else "None" end) as $labels |
  ($pr.milestone.title // "None") as $milestone |

  # Merge status checks
  ($pr.reviewDecision == "APPROVED") as $approved |
  ($threads_unresolved == 0) as $threads_ok |
  ($pr.mergeable == "MERGEABLE") as $merge_clean |
  ($pr.commits.nodes[-1].commit.statusCheckRollup.state // "NONE") as $ci_state |
  ($ci_state == "SUCCESS" or $ci_state == "NONE") as $ci_ok |
  (($local.syntax_errors | length) == 0 and ($local.safety_violations | length) == 0 and ($local.scope_violations | length) == 0) as $local_ok |

  (if ($approved and $threads_ok and $merge_clean and $ci_ok and $local_ok) then "PASSED"
   elif ($pr.mergeable == "CONFLICTING" or ($local_ok | not) or ($threads_ok | not) or ($approved | not)) then "FAILED"
   elif ($ci_state == "FAILURE" or $ci_state == "ERROR") then "FAILED"
   else "PASSED WITH WARNINGS" end) as $overall_status |

  def format_comment($c; $idx):
    "### Comment #\($idx + 1) by @\($c.author.login // "ghost") on \($c.createdAt)\n\n" +
    ($c.body // "_(No content)_") + "\n";

  ($pr.comments.nodes) as $c_nodes |
  (if ($c_nodes | length) == 0 then
    "_No comments on this pull request._"
  elif ($c_nodes | length) <= 10 then
    ([range(0; $c_nodes | length) as $i | format_comment($c_nodes[$i]; $i)] | join("\n---\n\n"))
  else
    (
      [range(0; 5) as $i | format_comment($c_nodes[$i]; $i)] +
      ["_... [\($c_nodes | length - 10) comments omitted] ..._\n"] +
      [range(($c_nodes | length - 5); $c_nodes | length) as $i | format_comment($c_nodes[$i]; $i)]
    ) | join("\n---\n\n")
  end) as $comments_section |

  [
      "# PR #\($pr.number): \($pr.title)",
      "",
      "| Detail | Value |",
      "|---|---|",
      "| **State** | \($pr.state)\(if $pr.isDraft then " (draft)" else "" end) |",
      "| **Review Decision** | \($pr.reviewDecision // "NONE") |",
      "| **Mergeable** | \($pr.mergeable // "UNKNOWN")\(if $pr.mergeStateStatus then " (\($pr.mergeStateStatus))" else "" end) |",
      "| **Branch** | `\($pr.headRefName)` → `\($pr.baseRefName)` |",
      "| **HEAD OID** | `\($pr.headRefOid)` |",
      "| **Author** | @\($author) (repo owner: @\($owner)) |",
      "| **Changes** | +\($pr.additions) -\($pr.deletions) across \($pr.changedFiles) file(s) |",
      "| **Assignees** | \($assignees) |",
      "| **Labels** | \($labels) |",
      "| **Milestone** | \($milestone) |",
      "| **URL** | \($pr.url) |",
      "| **Created** | \($pr.createdAt) |",
      "| **Updated** | \($pr.updatedAt) |",
      "",
      "## Merge Readiness & Status Checks",
      "- **Review Decision**: \(icon($approved)) \($pr.reviewDecision // "NONE")\(if $approved then "" else " (Requires approval)" end)",
      "- **Review Threads**: \(icon($threads_ok)) \(if $threads_ok then "All requested changes / threads resolved" else "\($threads_unresolved) unresolved review thread(s)" end)",
      "- **Merge Conflicts**: \(if $merge_clean then "✅ Clean (MERGEABLE)" elif $pr.mergeable == "CONFLICTING" then "❌ Branch has conflicts (CONFLICTING)" else "⚠ Unknown or pending (\($pr.mergeable // "UNKNOWN"))" end)",
      "- **Status Checks**: \(if $ci_state == "SUCCESS" then "✅ All status checks completed successfully" elif $ci_state == "NONE" then "✅ No status checks reported on branch" elif $ci_state == "PENDING" then "⏳ Status checks pending" else "❌ Status checks \($ci_state)" end)",
      "- **Local Checks**: \(if $local_ok then "✅ Syntax, interactive safety, and scope hygiene passed" else "❌ Issues detected: " + ([(if ($local.syntax_errors | length) > 0 then "syntax errors (\($local.syntax_errors | join(", ")))" else empty end), (if ($local.safety_violations | length) > 0 then "safety violations (\($local.safety_violations | join(", ")))" else empty end), (if ($local.scope_violations | length) > 0 then "scope violations (\($local.scope_violations | join(", ")))" else empty end)] | join("; ")) end)",
      "- **Overall Status**: \($overall_status)",
      "",
      "## Review & Thread Stats",
      "- **Comments**: \($total_comments) (\($issue_comments) issue + \($inline_comments) inline) | By author: \($author_comments) | By owner: \($owner_comments)",
      "- **Reviews**: \($reviews_total) total | Approved: \($reviews_approved) | Changes requested: \($changes_requested) | Commits after last CR: \(if $changes_requested > 0 then $commits_after_cr else "n/a" end)",
      "- **Review Threads**: \($threads_total) total | Resolved: \($threads_resolved) (\($author_resolved) by author) | Unresolved: \($threads_unresolved) | Outdated: \($threads_outdated) | Current: \($threads_current) (author last: \($author_last_current), reviewer last: \($reviewer_last_current))",
      "- **Author Requested Review**: \(icon($review_requested))",
      "",
      "## Description (Original Comment by @\($author))",
      "",
      (if ($pr.body | length) > 0 then $pr.body else "_No description provided._" end),
      "",
      "## Comments (\($issue_comments))",
      "",
      $comments_section
  ] | join("\n")
'
