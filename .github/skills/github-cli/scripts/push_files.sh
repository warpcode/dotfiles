#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

owner="$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo '')"
repo="$(gh repo view --json name -q '.name' 2>/dev/null || echo '')"
branch=""
message=""
additions=""
deletions=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./push_files.sh [OPTIONS]"
      echo ""
      echo "Create an atomic multi-file commit (additions and deletions) directly on a remote branch."
      echo ""
      echo "Options:"
      echo "  --owner <value> (Required)"
      echo "  --repo <value> (Required)"
      echo "  --branch <value> (Required)"
      echo "  --message <value> (Required)"
      echo "  --additions <value> (Required)"
      echo "  --deletions <value> (Required)"
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
    --branch)
      branch="$2"
      shift 2
      ;;
    --message)
      message="$2"
      shift 2
      ;;
    --additions)
      additions="$2"
      shift 2
      ;;
    --deletions)
      deletions="$2"
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
if [[ -z "$branch" ]]; then
  echo "Error: --branch is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$message" ]]; then
  echo "Error: --message is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$additions" ]]; then
  echo "Error: --additions is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$deletions" ]]; then
  echo "Error: --deletions is required. Use --help for usage." >&2
  exit 1
fi

echo 'Complex push_files not fully implemented in bash'; exit 1
