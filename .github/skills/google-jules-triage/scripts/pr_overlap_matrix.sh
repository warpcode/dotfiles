#!/usr/bin/env bash
# pr_overlap_matrix.sh: Build a file x PR matrix across one or more repositories
# and flag duplicate-PR clusters.
#
# Triage for "which of these 19 open PRs are actually the same change?" is fully
# mechanical: list open PRs, fetch each one's touched files, group by overlap. Doing
# it by hand is a `gh pr view --json files` loop costing 20+ calls per repository.
#
# Usage:
#   pr_overlap_matrix.sh --repos <owner/repo>[,<owner/repo>...] [options]
#
# Options:
#   --repos <list>   Comma-separated owner/repo list (required)
#   --state <state>  open|closed|all|merged (default: open)
#   --min-shared <n> Shared-file count that constitutes a duplicate cluster
#                    (default: 2)
#   --include-files  Also print the full file x PR matrix
#   --count-journals  Count .jules/*.md agent-journal files toward overlap.
#                    OFF by default: every Sentinel/Bolt PR appends to the same
#                    journal, so counting it makes every pair look like a duplicate.
#   --json           Emit JSON instead of Markdown
#   -h, --help       Show this help
#
# Examples:
#   pr_overlap_matrix.sh --repos warpcode/cloakenv,warpcode/cloakai
#   pr_overlap_matrix.sh --repos warpcode/homelab --include-files
#   pr_overlap_matrix.sh --repos warpcode/cloakai --json > matrix.json
#
# Exit codes:
#   0  matrix built (clusters may or may not exist)
#   1  usage error, or `gh` unavailable/not authenticated
#
# Notes:
#   - Requires the `gh` CLI, authenticated with read access to each repository.
#   - A cluster is a STRONG hint of duplication, not proof. Three PRs touching the
#     same file may be legitimately sequential work. Always read the diffs before
#     closing anything as a duplicate.
#   - Raise --min-shared to 3 when a repository's PRs all touch a common file.

set -euo pipefail

SCRIPT_NAME=$(basename "$0")

usage() {
  sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//; $d'
  exit "${1:-0}"
}

die() {
  echo "${SCRIPT_NAME}: $*" >&2
  exit 1
}

REPOS=""
STATE="open"
MIN_SHARED=2
INCLUDE_FILES=false
COUNT_JOURNALS=false
AS_JSON=false

while [ $# -gt 0 ]; do
  case "$1" in
    --repos)          [ $# -ge 2 ] || die "--repos requires a value"; REPOS=$2; shift 2 ;;
    --state)          [ $# -ge 2 ] || die "--state requires a value"; STATE=$2; shift 2 ;;
    --min-shared)     [ $# -ge 2 ] || die "--min-shared requires a value"; MIN_SHARED=$2; shift 2 ;;
    --include-files)  INCLUDE_FILES=true; shift ;;
    --count-journals) COUNT_JOURNALS=true; shift ;;
    --json)           AS_JSON=true; shift ;;
    -h|--help)        usage 0 ;;
    *) die "unknown option: $1 (try --help)" ;;
  esac
done

[ -n "$REPOS" ] || die "--repos is required (try --help)"
command -v gh >/dev/null 2>&1 || die "gh CLI not found on PATH"
gh auth status >/dev/null 2>&1 || die "gh not authenticated; run: gh auth login"

IFS=',' read -r -a REPO_LIST <<< "$REPOS"

# Collect "<repo>\t<pr>\t<file>" rows.
ROWS=""
for repo in "${REPO_LIST[@]}"; do
  repo=$(echo "$repo" | tr -d '[:space:]')
  [ -n "$repo" ] || continue

  prs=$(gh pr list --repo "$repo" --state "$STATE" --limit 100 \
        --json number,title 2>/dev/null) \
    || die "failed to list PRs for $repo"

  count=$(jq 'length' <<< "$prs")
  echo "$repo: $count PR(s) in state '$STATE'" >&2

  while read -r num; do
    [ -n "$num" ] || continue
    files=$(gh pr view "$num" --repo "$repo" --json files \
              -q '.files[].path' 2>/dev/null || true)
    while read -r f; do
      [ -n "$f" ] || continue
      ROWS+="${repo}"$'\t'"${num}"$'\t'"${f}"$'\n'
    done <<< "$files"
  done < <(jq -r '.[].number' <<< "$prs")
done

[ -n "$ROWS" ] || die "no open PRs found in: $REPOS"

if [ "$AS_JSON" = true ]; then
  jq -Rn --arg state "$STATE" --argjson min "$MIN_SHARED" \
         --argjson journals "$COUNT_JOURNALS" '
    split("\n") | map(select(length > 0))
    | map(split("\t")) | map({repo: .[0], pr: (.[1] | tonumber), file: .[2]})
    | (if $journals then . else map(select(.file | test("(^|/)\\.jules/") | not)) end) as $rows
    | {state: $state, min_shared: $min, count_journals: $journals,
       prs: ($rows | group_by(.repo + "#" + (.pr|tostring))
             | map({key: (.[0].repo + "#" + (.[0].pr|tostring)),
                    repo: .[0].repo, pr: .[0].pr, files: (map(.file) | unique)})),
       clusters: (
         [$rows | group_by(.repo)[] | . as $r
          | [range(0; length) as $i | range($i+1; length) as $j
            | ($r[$i] as $a | $r[$j] as $b
               | (([$a.file] + [$b.file]) | unique) as $shared
               | select(($shared | length) >= $min)
               | {a: ($a.repo + "#" + ($a.pr|tostring)),
                  b: ($b.repo + "#" + ($b.pr|tostring)),
                  shared_files: $shared})])]
         | flatten)
       }' <<< "$ROWS"
  exit 0
fi

if [ "$INCLUDE_FILES" = true ]; then
  echo "## File x PR matrix"
  echo
  for repo in "${REPO_LIST[@]}"; do
    repo=$(echo "$repo" | tr -d '[:space:]')
    prs=$(cut -f1,2 <<< "$ROWS" | grep "^${repo}"$'\t' | cut -f2 | sort -un)
    [ -n "$prs" ] || continue
    echo "### $repo"
    echo
    while read -r num; do
      [ -n "$num" ] || continue
      title=$(gh pr view "$num" --repo "$repo" --json title -q .title 2>/dev/null || echo "?")
      echo "- **#$num** $title"
      while read -r f; do
        [ -n "$f" ] || continue
        echo "  - \`$f\`"
      done < <(awk -F'\t' -v r="$repo" -v p="$num" '$1==r && $2==p {print $3}' <<< "$ROWS")
    done <<< "$prs"
    echo
  done
else
  echo "_Matrix suppressed. Pass --include-files for the full file x PR listing._"
  echo
fi

echo "## Duplicate-PR clusters (>= $MIN_SHARED shared files)"
echo
found=false
for repo in "${REPO_LIST[@]}"; do
  repo=$(echo "$repo" | tr -d '[:space:]')
  repo_rows=$(awk -F'\t' -v r="$repo" '$1==r' <<< "$ROWS")
  [ -n "$repo_rows" ] || continue

  # Agent journals are appended to by every PR from the same agent, so they match
  # universally and drown out the real signal. Excluded unless --count-journals.
  if [ "$COUNT_JOURNALS" = false ]; then
    repo_rows=$(awk -F'\t' '$3 !~ /(^|\/)\.jules\//' <<< "$repo_rows")
  fi
  [ -n "$repo_rows" ] || continue

  mapfile -t pr_ids < <(cut -f2 <<< "$repo_rows" | sort -un)
  n=${#pr_ids[@]}
  for ((i = 0; i < n; i++)); do
    for ((j = i + 1; j < n; j++)); do
      a=${pr_ids[i]}
      b=${pr_ids[j]}
      fa=$(awk -F'\t' -v p="$a" '$2==p {print $3}' <<< "$repo_rows" | sort -u)
      fb=$(awk -F'\t' -v p="$b" '$2==p {print $3}' <<< "$repo_rows" | sort -u)
      shared=$(comm -12 <(echo "$fa") <(echo "$fb"))
      count=$(grep -c . <<< "$shared" || true)
      if [ "$count" -ge "$MIN_SHARED" ]; then
        found=true
        ta=$(gh pr view "$a" --repo "$repo" --json title -q .title 2>/dev/null || echo "?")
        tb=$(gh pr view "$b" --repo "$repo" --json title -q .title 2>/dev/null || echo "?")
        echo "### $repo #$a <-> #$b ($count shared files)"
        echo "- #$a: $ta"
        echo "- #$b: $tb"
        while read -r f; do
          [ -n "$f" ] || continue
          echo "  - \`$f\`"
        done <<< "$shared"
        echo
      fi
    done
  done
done

if [ "$found" = false ]; then
  echo "_No clusters found at threshold >= $MIN_SHARED shared files._"
  echo
  echo "Reminder: a shared file is not proof of duplication. Sequential PRs legitimately"
  echo "touch the same file; read the diffs before closing anything."
fi