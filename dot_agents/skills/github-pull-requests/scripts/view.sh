#!/bin/bash
#
# Gather pull request details: metadata, comments, and diff.
# Fetches everything in structured temp files so the caller (LLM)
# can decide what to read directly vs delegate to a subagent.
#
# Usage: view.sh [<pr_number>]
#   If pr_number is omitted, detects the PR for the current branch.

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
# Constants
# ---------------------------------------------------------------------------

readonly PR_JSON_FIELDS="number,title,url,body,state,isDraft,author,assignees,labels,milestone,baseRefName,headRefName,reviewRequests,reviews,comments,statusCheckRollup,mergeable,mergeStateStatus,additions,deletions,changedFiles,createdAt,updatedAt"

# Go template for the summary report.
# Outputs a markdown table with key fields + sections for reviews and CI.
read -r -d '' SUMMARY_TEMPLATE << 'GOTEMPLATE' || true
# PR #{{.number}}: {{.title}}

| Detail | Value |
|--------|-------|
| State | {{if .isDraft}}Draft{{else}}{{.state}}{{end}} |
| Branch | {{.headRefName}} → {{.baseRefName}} |
| Author | @{{.author.login}} |
{{- if .assignees}}
| Assignees | {{range $i, $a := .assignees}}{{if $i}}, {{end}}@{{$a.login}}{{end}} |
{{- end}}
{{- if .labels}}
| Labels | {{range $i, $l := .labels}}{{if $i}}, {{end}}{{$l.name}}{{end}} |
{{- end}}
{{- if .milestone}}
| Milestone | {{.milestone.title}} |
{{- end}}
| Changes | +{{.additions}} -{{.deletions}} across {{.changedFiles}} files |
| Mergeable | {{.mergeable}} |
| Merge state | {{.mergeStateStatus}} |
| URL | {{.url}} |
| Created | {{timeago .createdAt}} |
| Updated | {{timeago .updatedAt}} |
{{if .reviews}}
## Reviews
{{range .reviews}}
{{- if eq .state "APPROVED"}}✅{{else if eq .state "CHANGES_REQUESTED"}}🔄{{else if eq .state "COMMENTED"}}💬{{else if eq .state "DISMISSED"}}🚫{{else}}⏳{{end}} @{{.author.login}} — {{.state}}
{{end}}
{{- end}}
{{- if .reviewRequests}}
## Pending Review Requests
{{range .reviewRequests}}
{{- if .login}}⏳ @{{.login}}{{else if .name}}⏳ {{.name}} (team){{end}}
{{end}}
{{- end}}
{{- if .statusCheckRollup}}
## CI Status
{{range .statusCheckRollup}}
{{- if eq .conclusion "SUCCESS"}}✅{{else if eq .conclusion "FAILURE"}}❌{{else if eq .conclusion "NEUTRAL"}}➖{{else if eq .conclusion "SKIPPED"}}⏭️{{else}}⏳{{end}} {{.name}} — {{if .conclusion}}{{.conclusion}}{{else}}{{.status}}{{end}}
{{end}}
{{- end}}
GOTEMPLATE

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local pr="${1:-}"

  # ── Identify the PR ──────────────────────────────────────────────────

  if [[ -z "${pr}" ]]; then
    pr="$(gh pr view --json number -q .number 2>/dev/null)" || true
    if [[ -z "${pr}" ]]; then
      echo "# PR View: FAILED"
      echo ""
      echo "**Error:** No PR number provided and no PR found for the current branch."
      exit 1
    fi
  fi

  # ── Create temp directory ────────────────────────────────────────────

  local tmpdir
  tmpdir="$(mktemp -d -t pr-view.XXXXXX)"

  local json_file="${tmpdir}/pr.json"
  local comments_file="${tmpdir}/comments.txt"
  local diff_file="${tmpdir}/changes.diff"

  # ── Fetch data ───────────────────────────────────────────────────────

  # Full JSON (for deep-dive by LLM)
  if ! gh pr view "${pr}" --json "${PR_JSON_FIELDS}" > "${json_file}" 2>/dev/null; then
    echo "# PR View: FAILED"
    echo ""
    echo "**Error:** Could not fetch PR \`#${pr}\`. Check the number and your \`gh\` auth."
    rm -rf "${tmpdir}"
    exit 1
  fi

  # Comments (plain text, may be empty)
  gh pr view "${pr}" --comments > "${comments_file}" 2>/dev/null || true

  # Diff (may be large)
  gh pr diff "${pr}" > "${diff_file}" 2>/dev/null || true

  # ── Format summary ──────────────────────────────────────────────────

  local summary
  summary="$(gh pr view "${pr}" --json "${PR_JSON_FIELDS}" --template "${SUMMARY_TEMPLATE}" 2>/dev/null)" || true

  # ── Compute sizes ───────────────────────────────────────────────────

  local json_size comments_lines comments_size diff_lines diff_size
  json_size="$(human_size "$(wc -c < "${json_file}" | tr -d ' ')")"
  comments_lines="$(wc -l < "${comments_file}" | tr -d ' ')"
  comments_size="$(human_size "$(wc -c < "${comments_file}" | tr -d ' ')")"
  diff_lines="$(wc -l < "${diff_file}" | tr -d ' ')"
  diff_size="$(human_size "$(wc -c < "${diff_file}" | tr -d ' ')")"

  # ── Output ──────────────────────────────────────────────────────────

  if [[ -n "${summary}" ]]; then
    echo "${summary}"
  else
    echo "# PR #${pr}"
    echo ""
    echo "_Summary formatting failed. Read the raw JSON file below._"
  fi

  cat <<EOF

## Output Files

| File | Path | Lines | Size |
|------|------|------:|------|
| Full JSON | ${json_file} | — | ${json_size} |
| Comments | ${comments_file} | ${comments_lines} | ${comments_size} |
| Diff | ${diff_file} | ${diff_lines} | ${diff_size} |

_Files are in \`${tmpdir}/\` — clean up when done._
EOF
}

main "$@"
