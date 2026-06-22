#!/usr/bin/env bash
# Retrieve staged git context and metadata for LLM commit message generation.
set -euo pipefail

# Ensure execution inside a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'Error: Not inside a git work tree.\n' >&2
  exit 1
fi

# Check if there are any staged changes
if git diff --cached --quiet; then
  printf 'STATUS: NO_STAGED_CHANGES\n'
  exit 0
fi

# Gather git metadata
branch=$(git branch --show-current)
username=$(git config user.name || printf 'Unknown')

printf '=== Git Context Report ===\n'
printf 'Branch: %s\n' "$branch"
printf 'User: %s\n' "$username"
printf '\n--- Staged Files ---\n'
git status --porcelain | grep -E '^[MADRC]' || true

printf '\n--- Diff Stats ---\n'
git diff --staged --stat

printf '\n--- Staged Diff ---\n'
git diff --staged
