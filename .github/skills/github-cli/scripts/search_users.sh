#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

query=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./search_users.sh [OPTIONS]"
      echo ""
      echo "Search GitHub users and organizations by username, email, or full name."
      echo ""
      echo "Options:"
      echo "  --query <value> (Required)"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    --query)
      query="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$query" ]]; then
  echo "Error: --query is required. Use --help for usage." >&2
  exit 1
fi

gh search users "$query"
