#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

owner="$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo '')"
repo="$(gh repo view --json name -q '.name' 2>/dev/null || echo '')"
name=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./get_label.sh [OPTIONS]"
      echo ""
      echo "Retrieve metadata, description, and color settings for a repository label."
      echo ""
      echo "Options:"
      echo "  --owner <value> (Required)"
      echo "  --repo <value> (Required)"
      echo "  --name <value> (Required)"
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
    --name)
      name="$2"
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
if [[ -z "$name" ]]; then
  echo "Error: --name is required. Use --help for usage." >&2
  exit 1
fi

gh label view "$name" --repo "$owner"/"$repo"
