#!/usr/bin/env bash
#
# Branch overview: current branch, local and remote branches with last commit,
# upstream tracking, ahead/behind counts, and merged status vs the default
# branch. Optionally prunes stale remote refs and deletes merged local branches.
#
# Usage: ./branches.sh [--prune] [--delete-merged] [--raw|--raw-output]

set -euo pipefail
export PAGER=cat

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

print_usage() {
  cat <<'USAGE_EOF'
Usage: ./branches.sh [options]

Options:
  --prune            Prune stale remote-tracking refs (git fetch --prune) before reporting
  --delete-merged    Safely delete local branches already merged into default (git branch -d)
  --raw, --raw-output Output raw branch listing (git branch -a -vv)
  -h, --help         Show this help message
USAGE_EOF
}

#######################################
# Get the default branch name from origin/HEAD, falling back to main/master.
# Outputs:
#   Default branch name, or empty string if unknown.
#######################################
get_default_branch() {
  local branch
  branch="$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null \
    | sed 's#^origin/##' || true)"
  if [[ -n "${branch}" ]]; then
    echo "${branch}"
    return 0
  fi
  if git rev-parse --verify main >/dev/null 2>&1; then
    echo "main"
  elif git rev-parse --verify master >/dev/null 2>&1; then
    echo "master"
  fi
}

#######################################
# Get the current branch name.
# Outputs:
#   Current branch name, or "DETACHED".
#######################################
get_current_branch() {
  local branch
  branch="$(git branch --show-current 2>/dev/null || true)"
  echo "${branch:-DETACHED}"
}

#######################################
# Build a pipe-delimited set of branches merged into the default branch.
# Each branch is wrapped in '|' so substring checks can't false-positive.
# Arguments:
#   $1 - Default branch name.
# Outputs:
#   Branches wrapped in '|' and joined, or empty string.
#######################################
get_merged_branches() {
  local default_branch="$1"
  git branch --merged "${default_branch}" 2>/dev/null \
    | sed 's/^[* ] //' \
    | awk '{printf "|%s", $0} END {print "|"}'
}

#######################################
# Build a pipe-delimited set of remote branches merged into the default branch.
# Arguments:
#   $1 - Default branch name.
# Outputs:
#   Remote branches wrapped in '|' and joined, or empty string.
#######################################
get_merged_remote_branches() {
  local default_branch="$1"
  git branch -r --merged "${default_branch}" 2>/dev/null \
    | sed 's/^[* ] //' \
    | awk '{printf "|%s", $0} END {print "|"}'
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local raw_output=false
  local prune=false
  local delete_merged=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --raw|--raw-output)
        raw_output=true
        shift
        ;;
      --prune)
        prune=true
        shift
        ;;
      --delete-merged|--delete)
        delete_merged=true
        shift
        ;;
      -h|--help)
        print_usage
        exit 0
        ;;
      *)
        err "Unknown argument: $1"
        print_usage >&2
        exit 1
        ;;
    esac
  done

  # Check git is installed
  if ! command -v git >/dev/null 2>&1; then
    err "git is not installed or not in PATH."
    exit 1
  fi

  # Ensure execution inside a git repository
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    err "Not inside a git work tree."
    exit 1
  fi

  if [[ "${prune}" == "true" ]]; then
    git fetch --prune >/dev/null 2>&1 || true
  fi

  if [[ "${raw_output}" == "true" ]]; then
    git branch -a -vv
    return 0
  fi

  local default_branch current_branch merged_branches merged_remote_branches
  default_branch="$(get_default_branch)"
  current_branch="$(get_current_branch)"
  merged_branches=""
  merged_remote_branches=""
  if [[ -n "${default_branch}" ]]; then
    merged_branches="$(get_merged_branches "${default_branch}")"
    merged_remote_branches="$(get_merged_remote_branches "${default_branch}")"
  fi

  echo "# Branches"
  echo ""
  echo "Current: ${current_branch}"
  echo "Default: ${default_branch:-Unknown}"
  echo ""

  # ── Local branches ────────────────────────────────────────────────────
  echo "## Local (sorted by last commit)"
  echo ""
  echo "| Branch | Last commit | Upstream | Ahead/Behind | Merged into ${default_branch:-default} |"
  echo "|--------|-------------|----------|--------------|----------------------------------------|"

  local branch date upstream track merged
  local merged_candidates=()
  while IFS='|' read -r branch date _ upstream track; do
    [[ -z "${branch}" ]] && continue
    merged="No"
    if [[ -n "${merged_branches}" && "${merged_branches}" == *"|${branch}|"* ]]; then
      merged="Yes"
      if [[ "${branch}" != "${default_branch}" && "${branch}" != "${current_branch}" ]]; then
        merged_candidates+=("${branch}")
      fi
    fi
    if [[ -z "${upstream}" ]]; then
      upstream="—"
    fi
    echo "| ${branch} | ${date} | ${upstream} | ${track:-—} | ${merged} |"
  done < <(git for-each-ref --sort=-committerdate refs/heads \
      --format='%(refname:short)|%(committerdate:relative)|%(subject)|%(upstream:short)|%(upstream:trackshort)' 2>/dev/null || true)

  # ── Remote branches ───────────────────────────────────────────────────
  echo ""
  echo "## Remote (excluding origin/HEAD)"
  echo ""
  echo "| Branch | Last commit | Merged into ${default_branch:-default} |"
  echo "|--------|-------------|----------------------------------------|"
  while IFS='|' read -r branch date _; do
    [[ -z "${branch}" ]] && continue
    merged="No"
    if [[ -n "${merged_remote_branches}" && "${merged_remote_branches}" == *"|${branch}|"* ]]; then
      merged="Yes"
    fi
    echo "| ${branch} | ${date} | ${merged} |"
  done < <(git for-each-ref --sort=-committerdate refs/remotes \
      --format='%(refname:short)|%(committerdate:relative)|%(subject)' 2>/dev/null \
      | (grep -v '^origin/HEAD' || true))

  # ── Deletion (if requested) ──────────────────────────────────────────
  if [[ "${delete_merged}" == "true" ]]; then
    echo ""
    echo "## Deleting merged local branches"
    echo ""
    if (( ${#merged_candidates[@]} == 0 )); then
      echo "No merged local branches to delete."
    else
      for branch in "${merged_candidates[@]}"; do
        git branch -d "${branch}" 2>&1 | sed 's/^/  /' || true
      done
    fi
  fi
}

main "$@"
