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
#   --list, -l        Print all valid added line anchors (`<path>:<line>: <text>`) and exit.
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
list_mode=0
declare -a paths=()
declare -a lines=()
cur_path=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    --diff)    diff_file="$2"; shift 2 ;;
    --list|-l) list_mode=1; shift ;;
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
if [[ $list_mode -eq 1 ]]; then
  awk '
    /^diff --git /   { p = $4; sub(/^b\//, "", p); next }
    /^@@/           { split($3, r, ","); cur = substr(r[1], 2) + 0; next }
    /^\+\+\+|^---/  { next }
    /^\+/           { print p ":" cur ": " substr($0, 2); cur++; next }
    /^ /            { cur++; next }
  ' "$diff_file"
  exit 0
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

# `git show` fails when the path is absent from the ref: a deleted or renamed
# file, a payload path that does not exist, or simply the wrong ref. Without a
# guard that failure propagates under `set -euo pipefail`, kills the loop
# mid-iteration, and the script exits 128 having printed no VERDICT -- so the
# caller cannot distinguish a bad anchor from a broken ref lookup. Ask git
# directly instead, and report the outcome explicitly.
#
# NOTE: an added line may legitimately be blank, so "empty text" is not proof
# of a failed lookup. Absence is decided by `git cat-file`/`wc`, and both are
# cached per path so a payload of N anchors over the same file costs one
# `git show`, not N.
declare -A _ref_present=()
declare -A _ref_lines=()
declare -A _ref_blob=()

# Cache the head blob per path, ONCE, in a temp file. Deliberately not a
# command substitution: that would run in a subshell and discard the cache,
# turning N anchors over one file back into N `git show` calls. The temp file
# (rather than a shell variable) also preserves the trailing newline, so the
# line count is exact -- a body captured by `$(...)` silently loses it and
# reports the last line of every file as "beyond EOF".
_REFTMP="$(mktemp -d)"
trap 'rm -rf "$_REFTMP"' EXIT

_N=0
load_ref_file() {
  local p="$1"
  if [[ -z "${_ref_lines[$p]+x}" ]]; then
    _ref_blob["$p"]="$_REFTMP/$(printf '%s' "$p" | tr '/' '_')"
    if git show "${head_ref}:$p" > "${_ref_blob[$p]}" 2>/dev/null; then
      _ref_present["$p"]=1
      _ref_lines["$p"]="$(sed -n '$=' < "${_ref_blob[$p]}" | tr -d ' ')"
      [[ "${_ref_lines[$p]}" == "0" ]] && _ref_lines["$p"]=1
    else
      _ref_present["$p"]=0
      _ref_lines["$p"]=0
    fi
  fi
  _N="${_ref_lines[$p]}"
}

# $2 is 1-indexed within the cached blob.
head_text() {
  sed -n "$2p" < "${_ref_blob[$1]}"
}

# Resolve one anchor against the head ref. Sets REASON when the cross-check
# could not be completed, which is a distinct failure from a bad anchor: it
# means the diff and the ref came from different fetches.
REASON=""
resolve_against_head() {
  local p="$1" l="$2"
  REASON=""
  load_ref_file "$p"
  if [[ "${_ref_present[$p]:-0}" != "1" ]]; then
    REASON="<absent from $head_ref -- deleted, renamed, or wrong ref>"
  elif [[ "$l" -gt "$_N" ]]; then
    REASON="<beyond EOF of $head_ref:$p>"
  fi
}

fail=0
unresolved=0
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
    resolve_against_head "$p" "$l"
    if [[ -n "$REASON" ]]; then
      # The anchor cannot be cross-checked, so it cannot be trusted either way.
      unresolved=$((unresolved + 1))
      if [[ "$status" == "OK" ]]; then
        status="FAIL"
        fail=$((fail + 1))
      fi
      txt="$REASON"
    else
      txt="$(head_text "$p" "$l" 2>/dev/null || true)"
    fi
    txt="${txt//$'\t'/}"
    txt="${txt:0:60}"
    if [[ $quiet -eq 0 ]]; then
      printf '%-4s %s:%s  %s\n' "$status" "$p" "$l" "$txt"
    fi
  elif [[ $quiet -eq 0 ]]; then
    printf '%-4s %s:%s\n' "$status" "$p" "$l"
  fi
done

if [[ $unresolved -gt 0 ]]; then
  echo "VERDICT: FAIL - $unresolved anchor(s) could not be resolved against $head_ref." >&2
  echo "         The diff and $head_ref were not captured from the same fetch," >&2
  echo "         or the path was deleted/renamed. Do NOT submit." >&2
  exit 1
fi
if [[ $fail -gt 0 ]]; then
  echo "VERDICT: FAIL - $fail of $checked anchor(s) are not added lines. Do NOT submit."
  exit 1
fi
echo "VERDICT: PASS - all $checked anchor(s) are added lines in $diff_file."
