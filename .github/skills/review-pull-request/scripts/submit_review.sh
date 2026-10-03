#!/usr/bin/env bash
# Build, gate and submit a pull request review payload in one call.
#
# Enforces the ordering that is easy to get wrong by hand:
#   1. build the REST payload from a findings spec
#   2. verify every inline anchor resolves to an added line  <-- hard gate
#   3. submit only if step 2 passed
#
# `verify_review_anchors.sh` MUST run against a diff and a head ref captured in
# the same fetch. A stale ref makes the verifier print line text that no longer
# matches, which looks like a valid cross-check while proving nothing.
#
# Usage:
#   submit_review.sh --spec findings.json --owner o --repo r --pr N [options]
#
#   --spec FILE        findings spec (path/line/severity/title/description/
#                      impact/solution)                  [required]
#   --owner OWNER      repository owner                  [default: from origin]
#   --repo NAME        repository name                   [default: from origin]
#   --pr N             pull request number               [required]
#   --event EVENT      REQUEST_CHANGES | COMMENT | APPROVE
#                                                      [default: REQUEST_CHANGES]
#   --body TEXT        review body; omit for the neutral default
#   --diff FILE        saved diff for anchor verification (default: fetch)
#   --head REF         head ref for verification          [default: fetch]
#   --dry-run          build + verify only, never POST
#
# Exit codes: 0 submitted (or verified, with --dry-run), 1 usage/build failure,
# 2 anchor verification FAILED (nothing was submitted), 3 submit failed.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$(dirname -- "$(dirname -- "$SCRIPT_DIR")")"
GITHUB_CLI_SCRIPTS="$SKILLS_DIR/github-cli/scripts"

BUILD="$SCRIPT_DIR/build_review_payload.py"
VERIFY="$SCRIPT_DIR/verify_review_anchors.sh"
SUBMIT="$GITHUB_CLI_SCRIPTS/submit_pull_request_review_payload.sh"

die() { printf 'submit_review: %s\n' "$*" >&2; exit 1; }

SPEC=""; OWNER=""; REPO=""; PR=""; EVENT="REQUEST_CHANGES"; BODY=""
DIFF=""; HEAD=""; DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --spec)  SPEC="${2:-}";  shift 2 ;;
    --owner) OWNER="${2:-}"; shift 2 ;;
    --repo)  REPO="${2:-}";  shift 2 ;;
    --pr)    PR="${2:-}";    shift 2 ;;
    --event) EVENT="${2:-}"; shift 2 ;;
    --body)  BODY="${2:-}";  shift 2 ;;
    --diff)  DIFF="${2:-}";  shift 2 ;;
    --head)  HEAD="${2:-}";  shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[[ -n "$SPEC" ]] || die "--spec is required"
[[ -n "$PR"   ]] || die "--pr is required"
[[ -f "$BUILD" ]] || die "missing $BUILD"
[[ -f "$VERIFY" ]] || die "missing $VERIFY"
[[ -f "$SUBMIT" ]] || die "missing $SUBMIT (expected $SUBMIT)"
[[ -f "$SPEC" ]] || die "spec file not found: $SPEC"

# Resolve owner/repo from the remote rather than trusting a remembered value or
# the directory name.
if [[ -z "$OWNER" || -z "$REPO" ]]; then
  url="$(git remote get-url origin 2>/dev/null || true)"
  [[ -n "$url" ]] || die "cannot read origin remote; pass --owner and --repo"
  if [[ "$url" =~ github\.com[:/]([^/]+)/([^/]+?)(\.git)?$ ]]; then
    OWNER="${OWNER:-${BASH_REMATCH[1]}}"
    REPO="${REPO:-${BASH_REMATCH[2]}}"
  else
    die "cannot parse owner/repo from remote URL: $url"
  fi
fi

case "$EVENT" in
  REQUEST_CHANGES|COMMENT|APPROVE) ;;
  *) die "invalid --event '$EVENT' (REQUEST_CHANGES|COMMENT|APPROVE)" ;;
esac

TMPDIR_REVIEW="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_REVIEW"' EXIT
PAYLOAD="$TMPDIR_REVIEW/payload.json"

# --- capture diff and head ref in ONE step ---------------------------------
# Verification is only meaningful when both come from the same fetch.
if [[ -z "$DIFF" ]]; then
  DIFF="$TMPDIR_REVIEW/pr.diff"
  gh pr diff "$PR" --repo "$OWNER/$REPO" > "$DIFF" 2>&1 \
    || die "could not fetch diff for #$PR"
fi
if [[ -z "$HEAD" ]]; then
  HEAD="origin/pr-$PR"
  git fetch -q origin "+refs/pull/$PR/head:$HEAD" --force \
    || die "could not fetch head ref $HEAD"
fi

# --- 1. build ---------------------------------------------------------------
build_args=("$SPEC" --out "$PAYLOAD" --event "$EVENT")
[[ -n "$BODY" ]] && build_args+=(--body "$BODY")
python3 "$BUILD" "${build_args[@]}" >/dev/null || die "payload build failed"

echo "submit_review: event=$EVENT  comments=$(jq '.comments | length' "$PAYLOAD")"

# --- 2. anchor gate ---------------------------------------------------------
# With zero inline comments there is nothing to anchor (APPROVE, or a
# body-only COMMENT). verify_review_anchors.sh exits non-zero on an empty
# anchor list, which would fail a legitimate comment-free review.
if [[ "$(jq '.comments | length' "$PAYLOAD")" -eq 0 ]]; then
  echo "submit_review: no inline comments -- anchor gate not applicable"
else
  if ! bash "$VERIFY" --diff "$DIFF" --payload "$PAYLOAD" --head "$HEAD" --quiet; then
    echo "submit_review: anchor verification FAILED -- nothing submitted" >&2
    exit 2
  fi
  echo "submit_review: anchors verified"
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "submit_review: --dry-run, not submitting"
  jq -r '.comments[]? | "  \(.path):\(.line) [\(.side)]"' "$PAYLOAD"
  exit 0
fi

# --- 3. submit --------------------------------------------------------------
bash "$SUBMIT" --owner "$OWNER" --repo "$REPO" --pull-number "$PR" --input "$PAYLOAD" \
  || exit 3