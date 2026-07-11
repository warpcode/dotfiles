---
name: git-cli
description: >
  Local git operations and context gathering. Use this skill for purely local git tasks
  like branch comparison, diffing, log analysis, and workspace state verification
  that do not require GitHub API interaction.
---

# Git CLI

Local git operations and context gathering.

## 📝 Operations

### Gather PR Context
Use `scripts/context.sh <base> <head>` to collect commits, diffstat, and full diff into temporary files. This is useful when preparing to create a pull request or when you need a deep dive into the changes between two branches.

| Operation | Script | Purpose |
|-----------|--------|---------|
| **PR Context** | `scripts/context.sh` | Gather commits, diffstat, and diff to temp files |

## 🧠 Constraints
- **Never from main**: Never create PRs or perform risky operations directly from `main` or `master`.
- **Symlink Safety**: Verify if a target is a symlink before destructive operations.
- **Verification**: Always verify the current state before taking proactive actions.
