#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

owner="$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo '')"
repo="$(gh repo view --json name -q '.name' 2>/dev/null || echo '')"
issue_number=""
body=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./add_issue_comment.sh [OPTIONS]"
      echo ""
      echo "Add a comment to a specified GitHub issue."
      echo ""
      echo "Options:"
      echo "  --owner <value> (Required)"
      echo "  --repo <value> (Required)"
      echo "  --issue-number <value> (Required)"
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
    --issue-number)
      issue_number="$2"
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
if [[ -z "$issue_number" ]]; then
  echo "Error: --issue-number is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$body" ]]; then
  echo "Error: --body is required. Use --help for usage." >&2
  exit 1
fi

gh issue comment "$issue_number" --repo "$owner"/"$repo" --body "$body"
