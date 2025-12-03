---
name: git-workflow
description: Route ALL git operations to appropriate resources. Load reference files before responding. Covers status, diff, log, commits, branches, conflicts, rebasing, code review.
---

# Git Workflow Expert

Routes git operations to resources.

## Routing Rules

- **Info retrieval/changes/GitHub URLs**: READ @references/changes-info.md → provide info
- **Commit messages/committing**: READ @references/commit-message.md → generate message
- **Branching strategy**: READ references/branch-strategies.md → recommend
- **Conflicts/merge issues**: READ references/merge-conflicts.md → resolve
- **Rebasing**: READ references/rebase-guidelines.md → guide workflow
- **Other ops (status/diff/log)**: Use git commands → format output

**Rules**: Use for ALL git ops. Load refs before responding. Run scripts for data. Load only needed. Actionable guidance. NEVER commit or push without EXPLICIT user permission.
