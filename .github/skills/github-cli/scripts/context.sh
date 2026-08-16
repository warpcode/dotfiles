#!/bin/bash
#
# Gather pull request context: commits, changed files, and diff
# between a base branch and the current branch.
# Writes full output to temp files so the caller (LLM) can decide
# whether to load them directly or delegate to a subagent.

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

usage() {
  err "Usage: $(basename "$0") <base_branch> <head_branch>"
  err ""
  err "Arguments:"
  err "  base_branch  The branch the PR will merge into (e.g. main, develop)"
  err "  head_branch  The branch being merged (e.g. feat/dark-mode)"
}

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

#######################################
# Verify a branch exists on origin.
# Arguments:
#   $1 - Branch name.
# Returns:
#   0 if exists, 1 otherwise.
#######################################
branch_exists_on_origin() {
  local branch="$1"
  git ls-remote --heads origin "${branch}" 2>/dev/null | grep -q "${branch}"
}

#######################################
# Verify a branch exists locally.
# Arguments:
#   $1 - Branch name.
# Returns:
#   0 if exists, 1 otherwise.
#######################################
branch_exists_locally() {
  local branch="$1"
  git rev-parse --verify "${branch}" &>/dev/null
}

# ---------------------------------------------------------------------------
# Context collection
# ---------------------------------------------------------------------------

#######################################
# Write commit log to a temp file.
# Arguments:
#   $1 - Base branch.
#   $2 - Head branch.
#   $3 - Output file path.
# Outputs:
#   Commit count to stdout.
#######################################
write_commit_log() {
  local base="$1"
  local head="$2"
  local outfile="$3"

  git log "${base}..${head}" \
    --oneline \
    --no-decorate \
    > "${outfile}" 2>/dev/null || true

  wc -l < "${outfile}" | tr -d ' '
}

#######################################
# Write diffstat to a temp file.
# Arguments:
#   $1 - Base branch.
#   $2 - Head branch.
#   $3 - Output file path.
# Outputs:
#   Number of files changed to stdout.
#######################################
write_diffstat() {
  local base="$1"
  local head="$2"
  local outfile="$3"

  git diff "${base}...${head}" --stat > "${outfile}" 2>/dev/null || true

  # File count is total lines minus the summary line
  local total_lines
  total_lines="$(wc -l < "${outfile}" | tr -d ' ')"
  if (( total_lines > 1 )); then
    echo "$(( total_lines - 1 ))"
  else
    echo "0"
  fi
}

#######################################
# Write full diff to a temp file.
# Arguments:
#   $1 - Base branch.
#   $2 - Head branch.
#   $3 - Output file path.
# Outputs:
#   Line count of the diff to stdout.
#######################################
write_diff() {
  local base="$1"
  local head="$2"
  local outfile="$3"

  git diff "${base}...${head}" > "${outfile}" 2>/dev/null || true

  wc -l < "${outfile}" | tr -d ' '
}

#######################################
# Format a byte count into a human-readable size.
# Arguments:
#   $1 - Size in bytes.
# Outputs:
#   Human-readable size string (e.g. "1.2 KB", "3.4 MB").
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

#######################################
# Entry point. Validates branches and outputs context report.
# Arguments:
#   $1 - Base branch.
#   $2 - Head branch.
# Outputs:
#   Structured markdown report with temp file paths to stdout.
#######################################
main() {
  if [[ $# -lt 2 ]]; then
    echo "# PR Context: FAILED"
    echo ""
    echo "**Error:** Missing required arguments."
    echo ""
    usage >&2
    exit 1
  fi

  local base_branch="$1"
  local head_branch="$2"

  # ── Validate branches ──────────────────────────────────────────────────

  local base_local="No"
  local base_remote="No"
  local head_local="No"
  local head_remote="No"

  if branch_exists_locally "${base_branch}"; then
    base_local="Yes"
  fi
  if branch_exists_on_origin "${base_branch}"; then
    base_remote="Yes"
  fi
  if branch_exists_locally "${head_branch}"; then
    head_local="Yes"
  fi
  if branch_exists_on_origin "${head_branch}"; then
    head_remote="Yes"
  fi

  # Fail if we can't compare the branches
  if [[ "${base_local}" == "No" && "${base_remote}" == "No" ]]; then
    echo "# PR Context: FAILED"
    echo ""
    echo "**Error:** Base branch \`${base_branch}\` not found locally or on origin."
    exit 1
  fi

  if [[ "${head_local}" == "No" ]]; then
    echo "# PR Context: FAILED"
    echo ""
    echo "**Error:** Head branch \`${head_branch}\` not found locally."
    exit 1
  fi

  # Fetch base from origin if only available remotely
  if [[ "${base_local}" == "No" && "${base_remote}" == "Yes" ]]; then
    git fetch origin "${base_branch}" &>/dev/null
    base_branch="origin/${base_branch}"
  fi

  # ── Create temp files ──────────────────────────────────────────────────

  local tmpdir
  tmpdir="$(mktemp -d -t pr-context.XXXXXX)"

  local log_file="${tmpdir}/commits.log"
  local stat_file="${tmpdir}/diffstat.txt"
  local diff_file="${tmpdir}/changes.diff"

  # ── Collect context ────────────────────────────────────────────────────

  local commit_count
  commit_count="$(write_commit_log "${base_branch}" "${head_branch}" "${log_file}")"

  local file_count
  file_count="$(write_diffstat "${base_branch}" "${head_branch}" "${stat_file}")"

  local diff_lines
  diff_lines="$(write_diff "${base_branch}" "${head_branch}" "${diff_file}")"

  local log_size stat_size diff_size
  log_size="$(human_size "$(wc -c < "${log_file}" | tr -d ' ')")"
  stat_size="$(human_size "$(wc -c < "${stat_file}" | tr -d ' ')")"
  diff_size="$(human_size "$(wc -c < "${diff_file}" | tr -d ' ')")"

  # ── Output report ──────────────────────────────────────────────────────

  cat <<EOF
# PR Context

| Detail         | Value |
|----------------|-------|
| Base branch    | ${base_branch} |
| Head branch    | ${head_branch} |
| Base on origin | ${base_remote} |
| Head on origin | ${head_remote} |

## Output Files

| File | Path | Lines | Size |
|------|------|------:|------|
| Commit log | ${log_file} | ${commit_count} | ${log_size} |
| Diffstat | ${stat_file} | $((file_count + 1)) | ${stat_size} |
| Full diff | ${diff_file} | ${diff_lines} | ${diff_size} |

_Files are in \`${tmpdir}/\` — clean up when done._
EOF
}

main "$@"
