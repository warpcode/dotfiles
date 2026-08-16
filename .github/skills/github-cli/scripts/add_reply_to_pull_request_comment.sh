#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

owner="$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo '')"
repo="$(gh repo view --json name -q '.name' 2>/dev/null || echo '')"
pull_number=""
comment_id=""
body=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./add_reply_to_pull_request_comment.sh [OPTIONS]"
      echo ""
      echo "Reply to an existing inline review comment on a pull request."
      echo ""
      echo "Options:"
      echo "  --owner <value> (Required)"
      echo "  --repo <value> (Required)"
      echo "  --pull-number <value> (Required)"
      echo "  --comment-id <value> (Required)"
      echo "  --body <value> (Required)"
      echo "  -h, --help        Show this help message"
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
    --comment-id)
      comment_id="$2"
      shift 2
      ;;
    --body)
      body="$2"
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
if [[ -z "$comment_id" ]]; then
  echo "Error: --comment-id is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$body" ]]; then
  echo "Error: --body is required. Use --help for usage." >&2
  exit 1
fi

gh api -X POST repos/"$owner"/"$repo"/pulls/"$pull_number"/comments/"$comment_id"/replies -f body="$body"
