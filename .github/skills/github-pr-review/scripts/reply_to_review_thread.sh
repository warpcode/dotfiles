#!/usr/bin/env bash
# Reply to an unresolved pull request review comment thread.
#
# Context: When triaging outdated review threads on pull requests, uncompleted
# or broken threads should be bumped with a contextual reply citing what remains
# outstanding, rather than resolved prematurely.
#
# Usage:
#   reply_to_review_thread.sh --pr N --comment-id ID --body "TEXT" [--owner OWNER] [--repo REPO]
#   reply_to_review_thread.sh --repo OWNER/REPO --pr N --comment-id ID --body "TEXT"
#
# Arguments:
#   --pr N             pull request number                                [required]
#   --comment-id ID    integer REST databaseId of initial comment        [required]
#   --body TEXT        reply comment body text                           [required]
#   --owner OWNER      repository owner                  [default: parsed from origin]
#   --repo REPO        repository name (or OWNER/REPO)   [default: parsed from origin]
#   --dry-run          preview the API request without posting
#   -h, --help         show this help text
#
# Notes:
#   --comment-id requires the integer REST databaseId (e.g. 4224737950) surfaced
#   in list_pull_request_review_threads.sh, NOT the GraphQL node id (PRRC_...).
#   Emits only the created comment's html_url to stdout to keep context token-efficient.
#
# Exit codes:
#   0: reply posted successfully (or previewed with --dry-run)
#   1: missing arguments or invalid inputs
#   2: API request failed

set -euo pipefail

die() { printf 'reply_to_review_thread: %s\n' "$*" >&2; exit 1; }

OWNER=""
REPO=""
PR=""
COMMENT_ID=""
BODY=""
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="${2:-}"; shift 2 ;;
    --repo)  REPO="${2:-}";  shift 2 ;;
    --pr|--pull-number) PR="${2:-}"; shift 2 ;;
    --comment-id) COMMENT_ID="${2:-}"; shift 2 ;;
    --body)  BODY="${2:-}";  shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help)
      sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -z "$PR" ]] && die "missing required --pr"
[[ -z "$COMMENT_ID" ]] && die "missing required --comment-id"
[[ -z "$BODY" ]] && die "missing required --body"

# Resolve owner/repo from argument or git remote
if [[ "$REPO" == *"/"* ]]; then
  OWNER="${REPO%%/*}"
  REPO="${REPO#*/}"
fi

if [[ -z "$OWNER" || -z "$REPO" ]]; then
  if remote_url="$(git config --get remote.origin.url 2>/dev/null)"; then
    slug="$(echo "$remote_url" | sed -E 's#(git@github\.com:|https://github\.com/)##; s#\.git$##')"
    [[ -z "$OWNER" ]] && OWNER="${slug%%/*}"
    [[ -z "$REPO" ]] && REPO="${slug#*/}"
  fi
fi

[[ -z "$OWNER" ]] && die "could not resolve repository owner (specify --owner)"
[[ -z "$REPO" ]] && die "could not resolve repository name (specify --repo)"

# Validate integer comment-id
if ! [[ "$COMMENT_ID" =~ ^[0-9]+$ ]]; then
  die "--comment-id must be an integer REST databaseId (got: '$COMMENT_ID')"
fi

ENDPOINT="repos/${OWNER}/${REPO}/pulls/${PR}/comments/${COMMENT_ID}/replies"

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf 'reply_to_review_thread: [dry-run] POST /%s\n' "$ENDPOINT"
  printf 'reply_to_review_thread: [dry-run] body: %s\n' "$BODY"
  exit 0
fi

if ! reply_url="$(gh api "$ENDPOINT" -f body="$BODY" --jq .html_url 2>&1)"; then
  printf 'reply_to_review_thread: failed to post reply:\n%s\n' "$reply_url" >&2
  exit 2
fi

printf '%s\n' "$reply_url"
