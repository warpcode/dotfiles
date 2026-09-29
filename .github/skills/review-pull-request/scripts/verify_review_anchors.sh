#!/bin/bash
# Verify that every inline comment anchor in a PR review payload resolves to a
# real ADDED line ("+") of the PR diff. Posting an anchor that is a context or
# removed line fails the GitHub REST API with "Line could not be resolved" (422).
#
# Usage:
#   verify_review_anchors.sh --diff <pr.diff> --payload <payload.json>
#   verify_review_anchors.sh --diff <pr.diff> --path <file> --line <n> [--line <n> ...]
#   verify_review_anchors.sh --diff <pr.diff> --payload <payload.json> --head origin/pr-<n>
#
# Options:
#   --diff <path>     Required. Saved `gh pr diff` output.
#   --payload <path>  REST review payload JSON (reads .comments[].path/.line).
#   --path <path>     Diff path to check against (repeat --line for each anchor).
#   --line <n>        1-indexed line number in the POST-change target file.
#   --head <ref>      Optional git ref. When given, each anchor's text is
#                     cross-checked against `git show <ref>:<path>`.
#   --quiet           Only print failures and the final verdict.
#   -h, --help        Show this help.
#
# Output: one line per anchor (OK / FAIL), then a verdict. Exit 0 = all anchors
# are added lines, exit 1 = at least one anchor is not (do NOT submit).
set -euo pipefail

diff_file=""
payload_file=""
head_ref=""
quiet=0
declare -a paths=()
declare -a lines=()
cur_path=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    --diff)    diff_file="$2"; shift 2 ;;
    --payload) payload_file="$2"; shift 2 ;;
    --path)    cur_path="$2"; shift 2 ;;
    # Each --line pairs with the most recent --path, so
    # `--path P --line 1 --line 2` checks both anchors against P.
    --line)    paths+=("$cur_path"); lines+=("$2"); shift 2 ;;
    --head)    head_ref="$2"; shift 2 ;;
    --quiet)   quiet=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$diff_file" ]]; then
  echo "Error: --diff is required." >&2; exit 2
fi
if [[ ! -f "$diff_file" ]]; then
  echo "Error: diff file '$diff_file' not found." >&2; exit 2
fi
if [[ -n "$payload_file" ]]; then
  if [[ ! -f "$payload_file" ]]; then
    echo "Error: payload file '$payload_file' not found." >&2; exit 2
  fi
  while IFS=$'\t' read -r p l; do
    [[ -n "$p" ]] || continue
    paths+=("$p"); lines+=("$l")
  done < <(jq -r '.comments[]? | "\(.path)\t\(.line)"' "$payload_file")
fi
if [[ ${#paths[@]} -eq 0 ]]; then
  echo "Error: no anchors supplied (use --payload or --path/--line)." >&2; exit 2
fi
for i in "${!paths[@]}"; do
  if [[ -z "${paths[$i]}" ]]; then
    echo "Error: --line ${lines[$i]} has no preceding --path." >&2; exit 2
  fi
done

# Correct hunk-header parsing: `@@ -old,len +NEW,len @@` puts the POST-change
# start line in field $3. Reading $2 silently yields the pre-change number and
# makes every anchor look invalid.
is_added_line() {
  local target_path="$1" target_line="$2"
  awk -v TP="$target_path" -v TL="$target_line" '
    /^diff --git /   { p = $4; sub(/^b\//, "", p); next }
    /^@@/           { split($3, r, ","); cur = substr(r[1], 2) + 0; next }
    /^\+\+\+|^---/  { next }
    /^\+/           { if (p == TP && cur == TL) { found = 1 } cur++; next }
    /^ /            { cur++; next }
    END             { exit(found ? 0 : 1) }
  ' "$diff_file"
}

head_text() {
  git show "${head_ref}:$1" 2>/dev/null | sed -n "$2p"
}

fail=0
checked=0
for i in "${!paths[@]}"; do
  p="${paths[$i]}"
  l="${lines[$i]}"
  checked=$((checked + 1))
  if is_added_line "$p" "$l"; then
    status="OK"
  else
    status="FAIL"
    fail=$((fail + 1))
  fi
  if [[ -n "$head_ref" ]]; then
    txt="$(head_text "$p" "$l" | tr -d '\t' | cut -c1-60)"
    if [[ $quiet -eq 0 ]]; then
      printf '%-4s %s:%s  %s\n' "$status" "$p" "$l" "$txt"
    fi
  elif [[ $quiet -eq 0 ]]; then
    printf '%-4s %s:%s\n' "$status" "$p" "$l"
  fi
done

if [[ $fail -gt 0 ]]; then
  echo "VERDICT: FAIL - $fail of $checked anchor(s) are not added lines. Do NOT submit."
  exit 1
fi
echo "VERDICT: PASS - all $checked anchor(s) are added lines in $diff_file."
