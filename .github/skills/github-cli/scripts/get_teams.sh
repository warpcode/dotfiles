#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

org=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./get_teams.sh [OPTIONS]"
      echo ""
      echo "List all teams and their slugs within a specified GitHub organization."
      echo ""
      echo "Options:"
      echo "  --org <value> (Required)"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    --org)
      org="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$org" ]]; then
  echo "Error: --org is required. Use --help for usage." >&2
  exit 1
fi

gh api orgs/"$org"/teams
