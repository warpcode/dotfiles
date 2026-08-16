#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

owner="$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo '')"
repo="$(gh repo view --json name -q '.name' 2>/dev/null || echo '')"
path=""
branch=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./get_file_contents.sh [OPTIONS]"
      echo ""
      echo "Fetch the file contents or directory listing for a path on a specific branch."
      echo ""
      echo "Options:"
      echo "  --owner <value> (Required)"
      echo "  --repo <value> (Required)"
      echo "  --path <value> (Required)"
      echo "  --branch <value> (Required)"
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
    --path)
      path="$2"
      shift 2
      ;;
    --branch)
      branch="$2"
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
if [[ -z "$path" ]]; then
  echo "Error: --path is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$branch" ]]; then
  echo "Error: --branch is required. Use --help for usage." >&2
  exit 1
fi

RESPONSE=$(gh api "repos/${owner}/${repo}/contents/${path}?ref=${branch}" 2>&1)
GH_STATUS=$?

if [[ $GH_STATUS -ne 0 ]]; then
    echo "Error: Failed to fetch file from GitHub (exit code: $GH_STATUS)." >&2
    echo "Details: $RESPONSE" >&2
    exit 1
fi

CONTENT=$(echo "$RESPONSE" | jq -r '.content // empty')
if [[ -n "$CONTENT" ]]; then
    printf '%s' "$CONTENT" | base64 -d
else
    # Fall back to raw media type for large files
    gh api -H "Accept: application/vnd.github.raw+json" "repos/${owner}/${repo}/contents/${path}?ref=${branch}"
fi
