#!/usr/bin/env bash
# Check the current status of the repository: user, branch, remotes, and
# staged/unstaged change summaries.
set -euo pipefail
PAGER=cat

# Check git is installed
if ! command -v git >/dev/null 2>&1; then
  printf 'Error: git is not installed or not in PATH.\n' >&2
  exit 1
fi

# Ensure execution inside a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'Error: Not inside a git work tree.\n' >&2
  exit 1
fi

printf "User: %s\n" "$(git config user.name || printf 'Unknown')"
current_branch=$(git branch --show-current)
if [ -z "$current_branch" ]; then
  printf "Current Branch: DETACHED HEAD\n"
  printf "WARNING: Detached HEAD state — operations like rebase or switch may lose commits\n"
else
  printf "Current Branch: %s\n" "$current_branch"
fi
printf "Remote URL: %s\n" "$(git remote get-url origin 2>/dev/null || printf 'None')"
upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || true)
printf "Upstream Branch: %s\n" "${upstream:-None}"
if [ -n "$upstream" ]; then
  printf "Commits to Push: %s\n" "$(git log "$upstream"..HEAD --oneline | wc -l)"
  printf "Commits to Pull: %s\n" "$(git log HEAD..$upstream --oneline | wc -l)"
else
  printf "Commits to Push: %s\n" "$(git log --branches --not --remotes --oneline | wc -l)"
  printf "Commits to Pull: 0\n"
fi

printf '\n--- Staged Files ---\n'
if git diff --staged --quiet; then
  printf 'NO_STAGED_CHANGES\n'
else
  git diff --staged --name-status
fi

printf '\n--- Changed Files ---\n'
if git diff --quiet; then
  printf 'NO_CHANGES\n'
else
  git diff --name-status
fi