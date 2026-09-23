#!/bin/bash
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

owner="$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo '')"
repo="$(gh repo view --json name -q '.name' 2>/dev/null || echo '')"
pull_number=""
input_file=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      echo "Usage: ./submit_pull_request_review_payload.sh [OPTIONS]"
      echo ""
      echo "Submit a structured review payload (with file/line comments) on a pull request."
      echo ""
      echo "Options:"
      echo "  --owner <value>        Repository owner (auto-detected if omitted)"
      echo "  --repo <value>         Repository name (auto-detected if omitted)"
      echo "  --pull-number <value>  Pull request number (Required)"
      echo "  --input <value>        Path to JSON review payload file (Required)"
      echo "  -h, --help             Show this help message"
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
    --input)
      input_file="$2"
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
if [[ -z "$input_file" ]]; then
  echo "Error: --input is required. Use --help for usage." >&2
  exit 1
fi
if [[ ! -f "$input_file" ]]; then
  echo "Error: input file '$input_file' not found." >&2
  exit 1
fi

tmp_out="$(mktemp /tmp/gh_review_out.XXXXXX.json)"
gh api "repos/${owner}/${repo}/pulls/${pull_number}/reviews" \
  --method POST \
  --input "$input_file" > "$tmp_out" 2>&1

status=$?
if [[ $status -ne 0 ]]; then
  cat "$tmp_out" >&2
  rm -f "$tmp_out"
  exit $status
fi

review_url="$(jq -r '.html_url // empty' "$tmp_out" 2>/dev/null || echo '')"
review_state="$(jq -r '.state // empty' "$tmp_out" 2>/dev/null || echo '')"
rm -f "$tmp_out"

if [[ -n "$review_url" ]]; then
  echo "Review submitted successfully (${review_state}): ${review_url}"
else
  echo "Review submitted successfully."
fi
