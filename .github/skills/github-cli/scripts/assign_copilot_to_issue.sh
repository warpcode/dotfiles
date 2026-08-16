#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

owner="$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo '')"
repo="$(gh repo view --json name -q '.name' 2>/dev/null || echo '')"
issue_number=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./assign_copilot_to_issue.sh [OPTIONS]"
      echo ""
      echo "Assign GitHub Copilot to an issue to generate an implementation plan and pull request."
      echo ""
      echo "Options:"
      echo "  --owner <value> (Required)"
      echo "  --repo <value> (Required)"
      echo "  --issue-number <value> (Required)"
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

gh issue edit "$issue_number" --repo "$owner"/"$repo" --add-assignee github-copilot[bot]
