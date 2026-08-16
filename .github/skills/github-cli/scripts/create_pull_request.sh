#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

owner="$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo '')"
repo="$(gh repo view --json name -q '.name' 2>/dev/null || echo '')"
title=""
body=""
head=""
base=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./create_pull_request.sh [OPTIONS]"
      echo ""
      echo "Create a new pull request comparing a head branch against a base branch."
      echo ""
      echo "Options:"
      echo "  --owner <value> (Required)"
      echo "  --repo <value> (Required)"
      echo "  --title <value> (Required)"
      echo "  --body <value> (Required)"
      echo "  --head <value> (Required)"
      echo "  --base <value> (Required)"
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
    --title)
      title="$2"
      shift 2
      ;;
    --body)
      body="$2"
      shift 2
      ;;
    --head)
      head="$2"
      shift 2
      ;;
    --base)
      base="$2"
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
if [[ -z "$title" ]]; then
  echo "Error: --title is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$body" ]]; then
  echo "Error: --body is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$head" ]]; then
  echo "Error: --head is required. Use --help for usage." >&2
  exit 1
fi
if [[ -z "$base" ]]; then
  echo "Error: --base is required. Use --help for usage." >&2
  exit 1
fi

gh pr create --repo "$owner"/"$repo" --title "$title" --body "$body" --head "$head" --base "$base" --draft
