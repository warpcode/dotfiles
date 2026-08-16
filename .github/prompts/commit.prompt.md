---
name: commit
description: "Workflow for preparing a git commit message"
argument-hint: "What to commit? (e.g exact files, all staged, or all unstaged)"
agent: "git-specialist"
model: OpenCode Zen / Big Pickle (opencodezen)
tools: [execute, read, edit, search, agent]
---

Workflow for the git-specialist to prepare and commit changes:

1. **Determine what to commit** — Inspect the repository state. If the user named specific files, use those. Otherwise use staged changes if any exist, else unstaged changes. If there is nothing to commit, halt and inform the user.

2. **Review the changes** — Read the diffs of the files to be committed. Note any filename issues or concerns.

3. **Generate the commit message** — Write a Conventional Commit message (imperative mood, subject under 50 chars, body lines under 72 chars) that accurately summarises the changes. Never invent details not present in the diff.

4. **Present for approval** — Show the user:
   - the proposed commit message, and
   - a summary of the files to be committed.
   Wait for explicit approval before proceeding.

5. **Commit on approval** — Once the user approves, commit the changes using the approved commit message. If the user requested changes, revise and re-present before committing.

**Hard constraints:**
- Never run `git commit` without explicit user approval
- Generate the message from the actual diff, never from assumptions
- No backticks in the commit message
