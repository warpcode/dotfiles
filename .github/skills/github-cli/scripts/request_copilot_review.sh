#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

owner="$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo '')"
repo="$(gh repo view --json name -q '.name' 2>/dev/null || echo '')"
pull_number=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./request_copilot_review.sh [OPTIONS]"
      echo ""
      echo "Request an automated code review from GitHub Copilot on a pull request."
      echo ""
      echo "Options:"
      echo "  --owner <value> (Required)"
      echo "  --repo <value> (Required)"
      echo "  --pull-number <value> (Required)"
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

gh api -X POST repos/"$owner"/"$repo"/pulls/"$pull_number"/requested_reviewers -f 'reviewers[]=github-copilot[bot]'
