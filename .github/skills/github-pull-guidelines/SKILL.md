---
name: github-pull-guidelines
description: Guidelines for pulling repository updates, performing git rebases, and handling merge conflicts interactively with the user. Use this skill whenever a git pull, rebase, or repository sync is requested, or when conflicts are encountered during a pull.
---

# Git Pull & Sync Guidelines

Ensure the local repository is updated cleanly and safely using rebase-centric workflows, while maintaining explicit user control over conflict resolution.

## 🔄 Pulling Strategy

### 1. Primary Rebase
- **Command**: Always prefer pulling with rebase:
  ```bash
  git pull --rebase
  ```
- **Rationale**: Keeps a clean, linear history and avoids unnecessary merge commits.

### 2. Handling Conflicts & Failures
- **No Auto-Resolution**: Do not attempt to force or auto-resolve conflicts without user visibility.
- **Interactive Proposal**: Should a rebase fail due to conflicts:
  1. Retrieve the merge diff and status (`git status`, `git diff`).
  2. Propose the conflicting changes clearly to the user.
  3. Provide explicit, detailed recommendations for how each conflict should be resolved (e.g., keep local changes, keep remote changes, or a specific manual merge).
  4. Wait for explicit user confirmation before applying resolutions or continuing the rebase (`git rebase --continue`).
