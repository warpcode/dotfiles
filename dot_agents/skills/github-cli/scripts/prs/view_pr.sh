#!/bin/bash
#
# Gather pull request details: metadata, comments, and diff.
# Fetches everything in structured temp files so the caller (LLM)
# can decide what to read directly vs delegate to a subagent.
#
# Usage: view_pr.sh [<pr_number>] [owner/repo]
#   If pr_number is omitted, detects the PR for the current branch.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common/client.sh"

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

#######################################
# Format a byte count into a human-readable size.
# Arguments:
#   $1 - Size in bytes.
# Outputs:
#   Human-readable size string (e.g. "1 KB", "3 MB").
#######################################
human_size() {
  local bytes="$1"
  if (( bytes < 1024 )); then
    echo "${bytes} B"
  elif (( bytes < 1048576 )); then
    echo "$(( bytes / 1024 )) KB"
  else
    echo "$(( bytes / 1048576 )) MB"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local pr="${1:-}"
  local repo="${2:-}"

  if [[ -z "$repo" ]]; then
      repo=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null) || true
  fi

  # ── Identify the PR ──────────────────────────────────────────────────

  if [[ -z "${pr}" ]]; then
    if [[ "$GITHUB_PROVIDER" == "gh" ]]; then
        pr="$(gh pr view --json number -q .number 2>/dev/null)" || true
    fi
    if [[ -z "${pr}" ]]; then
      echo "# PR View: FAILED"
      echo ""
      echo "**Error:** No PR number provided and no PR found for the current branch."
      exit 1
    fi
  fi

  if [[ -z "$repo" ]]; then
      echo "Error: Could not detect repository. Provide [owner/repo] as second argument." >&2
      exit 1
  fi

  # ── Create temp directory ────────────────────────────────────────────

  local tmpdir
  tmpdir="$(mktemp -d -t pr-view.XXXXXX)"

  local json_file="${tmpdir}/pr.json"
  local comments_file="${tmpdir}/comments.txt"
  local diff_file="${tmpdir}/changes.diff"

  # ── Fetch data ───────────────────────────────────────────────────────

  # Full JSON
  if ! github_api_request "GET" "repos/${repo}/pulls/${pr}" > "${json_file}" 2>/dev/null; then
    echo "# PR View: FAILED"
    echo ""
    echo "**Error:** Could not fetch PR \`#${pr}\` from \`${repo}\`. Check the number and your auth."
    rm -rf "${tmpdir}"
    exit 1
  fi

  # Comments (REST API)
  github_api_request "GET" "repos/${repo}/issues/${pr}/comments" > "${comments_file}.json" 2>/dev/null || true
  # Convert to simple text for convenience
  if [[ -f "${comments_file}.json" ]]; then
      jq -r '.[] | "--- @\(.user.login) at \(.created_at) ---\n\(.body)\n"' "${comments_file}.json" > "${comments_file}" 2>/dev/null || true
  fi

  # Diff
  github_api_request "GET" "repos/${repo}/pulls/${pr}" -H "Accept: application/vnd.github.v3.diff" > "${diff_file}" 2>/dev/null || true

  # ── Output ──────────────────────────────────────────────────────────

  local title=$(jq -r '.title' "$json_file")
  local state=$(jq -r '.state' "$json_file")
  local author=$(jq -r '.user.login' "$json_file")
  local head=$(jq -r '.head.ref' "$json_file")
  local base=$(jq -r '.base.ref' "$json_file")

  cat <<EOF
# PR #${pr}: ${title}

| Detail | Value |
|--------|-------|
| State | ${state} |
| Branch | ${head} → ${base} |
| Author | @${author} |
| URL | https://github.com/${repo}/pull/${pr} |

## Output Files

| File | Path | Lines | Size |
|------|------|------:|------|
| Full JSON | ${json_file} | — | $(human_size "$(wc -c < "${json_file}" | tr -d ' ')") |
| Comments | ${comments_file} | $(wc -l < "${comments_file}" | tr -d ' ') | $(human_size "$(wc -c < "${comments_file}" | tr -d ' ')") |
| Diff | ${diff_file} | $(wc -l < "${diff_file}" | tr -d ' ') | $(human_size "$(wc -c < "${diff_file}" | tr -d ' ')") |

_Files are in \`${tmpdir}/\` — clean up when done._
EOF
}

main "$@"
