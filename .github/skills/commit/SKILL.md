---
name: commit
description: Prepare and execute a git commit after reviewing staged changes and receiving explicit approval. Use when the user asks to commit changes, draft a commit message, or review staged changes for commit.
user-invocable: true
---

# Git Commit

Use the canonical workflow and format rules in:

- `../git-expert/references/commit-workflow.md`
- `../git-expert/references/commit-message-format.md`

The commit workflow is staged-only. If there are no staged changes, stop and
ask the user to stage the intended files; do not silently include unstaged
changes or stage files on the user's behalf.

Review the staged diff, draft the message from that diff, and present both the
message and the exact commit command for explicit approval. Run `git commit`
only after the user approves that exact command. If the user requests changes,
revise and present the command again.

## Hard Constraints

- Never run `git commit` without explicit user approval
- Generate the message from the actual diff, never from assumptions
- No backticks in the commit message
