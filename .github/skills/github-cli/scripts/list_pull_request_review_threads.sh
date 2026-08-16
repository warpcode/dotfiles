#!/bin/bash
# Fetch review threads for a single pull request using GraphQL.
# Usage: ./list_pull_request_review_threads.sh [OPTIONS]

set -euo pipefail
export GH_PAGER=""
export PAGER=cat

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
QUERY_FILE="${SCRIPT_DIR}/../queries/review_threads.gql"

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
      echo "Usage: ./list_pull_request_review_threads.sh [OPTIONS]"
      echo ""
      echo "List inline review comment threads, resolution status, and comments for a pull request."
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

JSON_RESPONSE=$(gh api graphql \
  -F query="@$QUERY_FILE" \
  -F owner="$owner" \
  -F repo="$repo" \
  -F pr="$pull_number" 2>"$STDERR_FILE")
GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
  echo "Error: Failed to query GitHub API (exit code: $GH_STATUS)." >&2
  cat "$STDERR_FILE" >&2
  exit 1
fi

# Hierarchical, token-efficient Markdown summary for review threads and all replies
echo "$JSON_RESPONSE" | jq -r --arg pr_num "$pull_number" --arg owner "$owner" --arg repo "$repo" '
  .data.repository.pullRequest as $pr |
  if ($pr == null) then
    "Error: Pull request #\($pr_num) not found in \($owner)/\($repo)."
  elif (($pr.reviewThreads.nodes | length) == 0) then
    "No review threads found for PR #\($pr.number): \($pr.title)"
  else
    ($pr.reviewThreads.nodes) as $threads |
    ($threads | length) as $total |
    ($threads | map(select(.isResolved)) | length) as $resolved |
    ($threads | map(select(.isResolved | not)) | length) as $unresolved |

    "# Review Threads: PR #\($pr.number) — \($pr.title)\n\n" +
    "**Total Threads**: \($total) (\($resolved) resolved, \($unresolved) unresolved)\n\n" +
    (
      $threads | map(
        . as $t |
        ($t.comments.nodes) as $comments |
        ($comments[0]) as $first |
        ($comments[1:]) as $replies |
        (if $t.isResolved then "🟢 Resolved" else "🔴 Unresolved" end) as $status_badge |
        (if $t.isOutdated then " *(Outdated)*" else "" end) as $outdated_tag |
        (if $t.line != null then ":L\($t.line)" elif $t.originalLine != null then ":L\($t.originalLine) (original)" else "" end) as $line_info |
        (if $t.isResolved and $t.resolvedBy != null then "Resolved by @\($t.resolvedBy.login)" elif $t.isResolved then "Resolved" else "Unresolved" end) as $resolved_status |

        "## Thread `\($t.id)` — \($status_badge)\($outdated_tag)\n" +
        "- **Location**: `\($t.path)\($line_info)`\n" +
        "- **Resolution**: \($resolved_status)\n\n" +
        (if $first != null then
          "### Initial Comment — @\($first.author.login // "ghost") (\($first.createdAt))\n\n" +
          ($first.body | split("\n") | map("> " + .) | join("\n")) + "\n\n"
        else
          "_(No initial comment recorded)_\n\n"
        end) +
        (if ($replies | length) > 0 then
          "### Replies (\($replies | length))\n\n" +
          (
            $replies | map(
              "#### ↳ Reply by @\(.author.login // "ghost") (\(.createdAt))\n\n" +
              (.body | split("\n") | map("> " + .) | join("\n")) + "\n"
            ) | join("\n")
          ) + "\n"
        else
          ""
        end)
      ) | join("---\n\n")
    )
  end
'
