#!/usr/bin/env bash
# pr_review_queue.sh - Fast multi-repository PR review queue inspector
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: pr_review_queue.sh [--threads] [owner/repo ...]

Inspect open PRs, their review decisions, mergeability, and CI status across repositories.
Defaults to: warpcode/dotfiles warpcode/cloakenv

Options:
  --threads     Include slow per-PR comment thread counts (N+1 API queries)
  -h, --help    Show this help message
EOF
}

SHOW_THREADS=0
REPOS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --threads)
      SHOW_THREADS=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      REPOS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#REPOS[@]} -eq 0 ]]; then
  REPOS=("warpcode/dotfiles" "warpcode/cloakenv")
fi

if [[ $SHOW_THREADS -eq 1 ]]; then
  printf "%-20s %-5s %-20s %-18s %-12s %-8s %-10s %s\n" "REPO" "PR" "AUTHOR" "DECISION" "MERGEABLE" "CI" "THREADS" "TITLE"
  printf "%s\n" "------------------------------------------------------------------------------------------------------------------------"
else
  printf "%-20s %-5s %-20s %-18s %-12s %-8s %s\n" "REPO" "PR" "AUTHOR" "DECISION" "MERGEABLE" "CI" "TITLE"
  printf "%s\n" "----------------------------------------------------------------------------------------------------------------"
fi

for repo in "${REPOS[@]}"; do
  prs="$(gh pr list --repo "$repo" --state open --json number,title,author,reviewDecision,mergeable,statusCheckRollup --limit 30 2>/dev/null || true)"
  [[ -z "$prs" || "$prs" == "[]" ]] && continue

  while IFS=$'\t' read -r pr author dec mergeable ci title; do
    [[ -z "$pr" ]] && continue
    if [[ $SHOW_THREADS -eq 1 ]]; then
      threads="$(gh api "repos/${repo}/pulls/${pr}/comments" --jq 'map(select(.in_reply_to_id == null)) | length' 2>/dev/null || echo "-")"
      printf "%-20s #%-4s %-20s %-18s %-12s %-8s %-10s %s\n" "$repo" "$pr" "$author" "${dec:-NONE}" "$mergeable" "$ci" "${threads} open" "$title"
    else
      printf "%-20s #%-4s %-20s %-18s %-12s %-8s %s\n" "$repo" "$pr" "$author" "${dec:-NONE}" "$mergeable" "$ci" "$title"
    fi
  done < <(echo "$prs" | jq -r '.[] | [
    .number,
    .author.login,
    (.reviewDecision // "PENDING"),
    .mergeable,
    ((.statusCheckRollup // []) | map(select(.conclusion != "SUCCESS")) | if length == 0 then "PASS" else "FAIL" end),
    .title
  ] | @tsv')
done
