#!/usr/bin/env bash
# pr_review_queue.sh - One-shot multi-repository PR review queue inspector
set -euo pipefail
export GH_PAGER=""
export PAGER=cat

usage() {
  cat <<'EOF'
Usage: pr_review_queue.sh [owner/repo ...]

Inspect open PRs and their review states across repositories in one table.
Defaults to: warpcode/dotfiles warpcode/cloakenv

Options:
  -h, --help    Show this help message
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 0 ]]; then
  REPOS=("$@")
else
  REPOS=("warpcode/dotfiles" "warpcode/cloakenv")
fi

printf "%-20s %-5s %-20s %-18s %-10s %s\n" "REPO" "PR" "AUTHOR" "DECISION" "THREADS" "TITLE"
printf "%s\n" "------------------------------------------------------------------------------------------------------"

for repo in "${REPOS[@]}"; do
  prs="$(gh pr list --repo "$repo" --state open --json number,title,author,reviewDecision,updatedAt --limit 20 2>/dev/null || true)"
  [[ -z "$prs" || "$prs" == "[]" ]] && continue

  while IFS=$'\t' read -r pr author dec title; do
    [[ -z "$pr" ]] && continue
    # Count unresolved / top-level review comments
    threads="$(gh api "repos/${repo}/pulls/${pr}/comments" --jq 'map(select(.in_reply_to_id == null)) | length' 2>/dev/null || echo "-")"
    printf "%-20s #%-4s %-20s %-18s %-10s %s\n" "$repo" "$pr" "$author" "${dec:-NONE}" "${threads} open" "$title"
  done < <(echo "$prs" | jq -r '.[] | "\(.number)\t\(.author.login)\t\(.reviewDecision // "PENDING")\t\(.title)"')
done
