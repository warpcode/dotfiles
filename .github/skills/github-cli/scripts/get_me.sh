#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat


while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./get_me.sh [OPTIONS]"
      echo ""
      echo "Retrieve profile and identity information for the currently authenticated GitHub user."
      echo ""
      echo "Options:"
      echo "  -h, --help        Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done


gh api user
