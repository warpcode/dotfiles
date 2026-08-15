#!/usr/bin/env bash
#
# One-shot repository overview: remotes, current branch, recent commits, tags,
# worktrees, stashes, and config. Bundles many git calls into a single
# token-efficient report for "give me the lay of the land".
#
# Usage: ./repo_overview.sh [--commits N] [--raw|--raw-output]

set -euo pipefail
export PAGER=cat

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

readonly DEFAULT_COMMIT_COUNT=10

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
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
# Get the HEAD commit summary.
# Outputs:
#   "short-hash subject", or "no commits".
#######################################
get_head_commit() {
  git log -1 --format='%h %s' 2>/dev/null || echo "no commits"
}

#######################################
# Print compact key/value porcelain repo overview.
#######################################
print_raw() {
  local branch head_sha
  branch="$(git branch --show-current 2>/dev/null || true)"
  head_sha="$(git rev-parse HEAD 2>/dev/null || echo 'no-commits')"

  echo "branch=${branch:-DETACHED}"
  echo "head=${head_sha}"

  if git remote >/dev/null 2>&1; then
    while IFS= read -r remote; do
      [[ -z "${remote}" ]] && continue
      local url
      url="$(git remote get-url "${remote}" 2>/dev/null || echo 'none')"
      echo "remote.${remote}=${url}"
    done < <(git remote)
  fi

  echo "status="
  git status --porcelain=v2 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

#######################################
# Entry point. Prints the repository overview report.
# Arguments:
#   Optional --commits N to override the recent-commit count.
#   Optional --raw / --raw-output for compact machine-readable overview.
#######################################
main() {
  local commit_count="${DEFAULT_COMMIT_COUNT}"
  local raw_output=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --raw|--raw-output)
        raw_output=true
        shift
        ;;
      --commits)
        if [[ -n "${2:-}" ]]; then
          commit_count="$2"
          shift 2
        else
          shift
        fi
        ;;
      -h|--help)
        echo "Usage: $0 [--commits N] [--raw|--raw-output]"
        exit 0
        ;;
      *)
        shift
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

  if [[ "${raw_output}" == "true" ]]; then
    print_raw
    return 0
  fi

  echo "# Repository Overview"
  echo ""
  echo "| Detail | Value |"
  echo "|--------|-------|"
  echo "| Root | $(git rev-parse --show-toplevel 2>/dev/null || echo 'not a git repo') |"
  echo "| Current branch | $(get_current_branch) |"
  echo "| HEAD | $(get_head_commit) |"
  echo "| User | $(git config user.name 2>/dev/null || echo Unknown) <$(git config user.email 2>/dev/null || echo unknown)> |"
  echo ""

  # ── Remotes ───────────────────────────────────────────────────────────
  echo "## Remotes"
  echo ""
  if [[ -n "$(git remote -v 2>/dev/null)" ]]; then
    echo "| Name | URL |"
    echo "|------|-----|"
    git remote -v | awk '{print "| " $1 " | " $2 " |"}' | sort -u
  else
    echo "No remotes configured."
  fi
  echo ""

  # ── Recent commits ────────────────────────────────────────────────────
  echo "## Recent commits (${commit_count})"
  echo ""
  git log --oneline -"${commit_count}" 2>/dev/null || echo "No commits yet."
  echo ""

  # ── Tags ──────────────────────────────────────────────────────────────
  echo "## Tags"
  echo ""
  local tag_count
  tag_count="$(git tag 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "${tag_count}" == "0" ]]; then
    echo "No tags."
  else
    git tag --sort=-creatordate 2>/dev/null | head -10
  fi
  echo ""

  # ── Worktrees ─────────────────────────────────────────────────────────
  echo "## Worktrees"
  echo ""
  if git worktree list >/dev/null 2>&1; then
    git worktree list
  else
    echo "None."
  fi
  echo ""

  # ── Stashes ───────────────────────────────────────────────────────────
  echo "## Stashes"
  echo ""
  local stash_count
  stash_count="$(git stash list 2>/dev/null | wc -l | tr -d ' ')"
  echo "${stash_count} stash(es)."
  echo ""

  # ── Working tree ──────────────────────────────────────────────────────
  echo "## Working tree"
  echo ""
  if git diff --quiet 2>/dev/null; then
    echo "Clean (no unstaged changes)."
  else
    git diff --stat 2>/dev/null | tail -5
  fi
  echo ""
  if git diff --staged --quiet 2>/dev/null; then
    echo "Nothing staged."
  else
    echo "Staged:"
    git diff --staged --name-status 2>/dev/null || true
  fi
}

main "$@"