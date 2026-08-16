#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

name=""
description=""
public=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./create_repository.sh [OPTIONS]"
      echo ""
      echo "Create a new GitHub repository with optional description and visibility settings."
      echo ""
      echo "Options:"
      echo "  --name <value> (Required)"
      echo "  --description <value> (Optional)"
      echo "  --public <value> (Optional)"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    --name)
      name="$2"
      shift 2
      ;;
    --description)
      description="$2"
      shift 2
      ;;
    --public)
      public="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$name" ]]; then
  echo "Error: --name is required. Use --help for usage." >&2
  exit 1
fi

gh repo create "$name" --description "$description" --public="$public"
