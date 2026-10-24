#!/usr/bin/env bash
# Plan, validate and apply a batch of PR review dispositions in one call.
#
# Replaces the per-PR sequence of spec validation, review submission, approval and
# closure (about 45 tool calls for 29 PRs). Approvals use an empty body, as
# required by the Silent Approvals Invariant. Closures never delete branches.
#
# SAFETY: the default run is a DRY RUN. It validates every REQUEST_CHANGES spec
# against the PR diff (via submit_review.sh --validate-only) and prints the plan,
# writing nothing to GitHub. Nothing is posted until `--execute` is passed, and
# execution is strictly sequential and stops at the first failure. Pass
# `--execute` only after the user has approved the exact list printed by the
# dry run.
#
# Usage:
#   batch_disposition.sh --repo owner/name [selectors] [options]
#
#   --repo OWNER/NAME           repository (combined form)             [required]
#   --approve LIST              comma-separated PR numbers to approve (empty body)
#   --request-changes-dir DIR   directory of pr<N>.json findings specs; every
#                               matching file becomes a REQUEST_CHANGES review
#   --rc-body TEXT              review body for REQUEST_CHANGES
#                               [default: "Findings are listed as inline comments."]
#   --close N=COMMENT           close PR N with COMMENT (repeatable; no branch delete)
#   --execute                   apply the plan (default: dry run)
#
# Exit codes: 0 dry run clean / all applied, 1 usage error, 2 a spec failed
# validation (nothing executed), 3 an action failed (remaining actions skipped).

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SUBMIT="$SCRIPT_DIR/submit_review.sh"

die() { printf 'batch_disposition: %s\n' "$*" >&2; exit 1; }

REPO=""; APPROVE=""; RC_DIR=""; RC_BODY="Findings are listed as inline comments."
EXECUTE=0
declare -a CLOSE_NUMS=() CLOSE_MSGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)                 REPO="${2:-}";    shift 2 ;;
    --approve)              APPROVE="${2:-}"; shift 2 ;;
    --request-changes-dir)  RC_DIR="${2:-}";  shift 2 ;;
    --rc-body)              RC_BODY="${2:-}"; shift 2 ;;
    --close)
      [[ "${2:-}" == *=* ]] || die "--close expects N=COMMENT"
      CLOSE_NUMS+=("${2%%=*}"); CLOSE_MSGS+=("${2#*=}"); shift 2 ;;
    --execute)              EXECUTE=1;        shift ;;
    -h|--help) sed -n '2,31p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$REPO" && "$REPO" == */* ]] || die "--repo owner/name is required"
OWNER="${REPO%%/*}"; NAME="${REPO#*/}"
[[ -f "$SUBMIT" ]] || die "missing $SUBMIT"

declare -a APPROVE_LIST=() RC_PRS=()
if [[ -n "$APPROVE" ]]; then IFS=',' read -r -a APPROVE_LIST <<<"$APPROVE"; fi
if [[ -n "$RC_DIR" ]]; then
  [[ -d "$RC_DIR" ]] || die "--request-changes-dir is not a directory: $RC_DIR"
  for f in "$RC_DIR"/pr*.json; do
    [[ -e "$f" ]] || continue
    n="${f##*/pr}"; RC_PRS+=("${n%.json}")
  done
fi
for n in "${APPROVE_LIST[@]}" "${RC_PRS[@]}" "${CLOSE_NUMS[@]}"; do
  [[ "$n" =~ ^[0-9]+$ ]] || die "invalid PR number: $n"
done
total=$(( ${#APPROVE_LIST[@]} + ${#RC_PRS[@]} + ${#CLOSE_NUMS[@]} ))
[[ "$total" -gt 0 ]] || die "nothing to do: pass --approve, --request-changes-dir or --close"

# A PR must not appear in more than one selector.
seen=" "
for n in "${APPROVE_LIST[@]}" "${RC_PRS[@]}" "${CLOSE_NUMS[@]}"; do
  [[ "$seen" == *" $n "* ]] && die "PR #$n appears in more than one selector"
  seen+="$n "
done

# Phase 1: validate every REQUEST_CHANGES spec before anything is written.
bad=0
for n in "${RC_PRS[@]}"; do
  if out="$(bash "$SUBMIT" --spec "$RC_DIR/pr$n.json" --owner "$OWNER" --repo "$NAME" \
        --pr "$n" --validate-only 2>&1)"; then
    printf 'VALID    request-changes #%s\n' "$n"
  else
    printf 'INVALID  request-changes #%s\n%s\n' "$n" "$out" >&2
    bad=1
  fi
done
[[ "$bad" -eq 0 ]] || { echo "batch_disposition: validation failed; nothing executed" >&2; exit 2; }

printf '\nPlan for %s:\n' "$REPO"
for n in "${APPROVE_LIST[@]}"; do printf '  approve          #%s (empty body)\n' "$n"; done
for n in "${RC_PRS[@]}";      do printf '  request-changes  #%s\n' "$n"; done
for i in "${!CLOSE_NUMS[@]}"; do printf '  close            #%s (branch kept)\n' "${CLOSE_NUMS[$i]}"; done

if [[ "$EXECUTE" -eq 0 ]]; then
  printf '\nDRY RUN: nothing posted. Re-run with --execute after approval.\n'
  exit 0
fi

# Phase 2: sequential, stop at the first failure.
fail() { printf 'batch_disposition: FAILED %s; remaining actions skipped\n' "$*" >&2; exit 3; }

for n in "${APPROVE_LIST[@]}"; do
  gh pr review "$n" --repo "$REPO" --approve >/dev/null || fail "approve #$n"
  printf 'approved          #%s\n' "$n"
done
for n in "${RC_PRS[@]}"; do
  url="$(bash "$SUBMIT" --spec "$RC_DIR/pr$n.json" --owner "$OWNER" --repo "$NAME" \
        --pr "$n" --event REQUEST_CHANGES --body "$RC_BODY" | tail -n 1)" \
    || fail "request-changes #$n"
  printf 'changes-requested #%s  %s\n' "$n" "$url"
done
for i in "${!CLOSE_NUMS[@]}"; do
  n="${CLOSE_NUMS[$i]}"
  gh pr close "$n" --repo "$REPO" --comment "${CLOSE_MSGS[$i]}" >/dev/null || fail "close #$n"
  printf 'closed            #%s\n' "$n"
done
