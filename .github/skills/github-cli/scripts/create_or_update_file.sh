#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

owner="$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo '')"
repo="$(gh repo view --json name -q '.name' 2>/dev/null || echo '')"
path=""
message=""
content=""
branch=""
sha=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./create_or_update_file.sh [OPTIONS]"
      echo ""
      echo "Create or update a single file in a remote repository via the GitHub Contents API."
      echo ""
      echo "Options:"
      echo "  --owner <value> (Required)"
      echo "  --repo <value> (Required)"
      echo "  --path <value> (Required)"
      echo "  --message <value> (Required)"
      echo "  --content <value> (Required)"
      echo "  --branch <value> (Required)"
      echo "  --sha <value> (Required)"
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
    --message)
      message="$2"
      shift 2
      ;;
    --content)
      content="$2"
      shift 2
      ;;
    --branch)
      branch="$2"
      shift 2
      ;;
    --sha)
      sha="$2"
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
if [[ -z "$message" ]]; then
  echo "Error: --message is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$content" ]]; then
  echo "Error: --content is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$branch" ]]; then
  echo "Error: --branch is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$sha" ]]; then
  echo "Error: --sha is required. Use --help for usage." >&2
  exit 1
fi

gh api -X PUT repos/"$owner"/"$repo"/contents/"$path" -f message="$message" -f content="$content" -f branch="$branch" -f sha="$sha"
