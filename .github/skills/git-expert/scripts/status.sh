#!/usr/bin/env bash
#
# Check the current status of the repository: user, branch, remotes,
# staged/unstaged change summaries, untracked files, and push/pull counts.
#
# Usage: ./status.sh [--raw|--raw-output]

set -euo pipefail
export PAGER=cat

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  local raw_output=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --raw|--raw-output)
        raw_output=true
        shift
        ;;
      -h|--help)
        echo "Usage: $0 [--raw|--raw-output]"
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
    git status --porcelain=v2 --branch
    return 0
  fi

  printf "User: %s\n" "$(git config user.name 2>/dev/null || printf 'Unknown')"
  local current_branch
  current_branch="$(git branch --show-current 2>/dev/null || true)"
  if [ -z "$current_branch" ]; then
    printf "Current Branch: DETACHED HEAD\n"
    printf "WARNING: Detached HEAD state — operations like rebase or switch may lose commits\n"
  else
    printf "Current Branch: %s\n" "$current_branch"
  fi
  printf "Remote URL: %s\n" "$(git remote get-url origin 2>/dev/null || printf 'None')"
  local upstream
  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || true)"
  printf "Upstream Branch: %s\n" "${upstream:-None}"
  if [ -n "$upstream" ]; then
    printf "Commits to Push: %s\n" "$(git log "$upstream"..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')"
    printf "Commits to Pull: %s\n" "$(git log HEAD.."$upstream" --oneline 2>/dev/null | wc -l | tr -d ' ')"
  else
    printf "Commits to Push: %s\n" "$(git log HEAD --not --remotes --oneline 2>/dev/null | wc -l | tr -d ' ')"
    printf "Commits to Pull: 0\n"
  fi

  printf '\n--- Staged Files ---\n'
  if git diff --staged --quiet 2>/dev/null; then
    printf 'NO_STAGED_CHANGES\n'
  else
    git diff --staged --name-status 2>/dev/null || true
  fi

  printf '\n--- Changed Files ---\n'
  if git diff --quiet 2>/dev/null; then
    printf 'NO_CHANGES\n'
  else
    git diff --name-status 2>/dev/null || true
  fi

  printf '\n--- Untracked Files ---\n'
  local untracked
  untracked="$(git ls-files --others --exclude-standard 2>/dev/null || true)"
  if [ -z "$untracked" ]; then
    printf 'NO_UNTRACKED_FILES\n'
  else
    printf '%s\n' "$untracked"
  fi
}

main "$@"
