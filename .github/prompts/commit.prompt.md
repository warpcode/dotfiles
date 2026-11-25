---
name: commit
description: "Workflow for preparing a git commit message"
argument-hint: "What to commit? (e.g exact files, all staged, or all unstaged)"
agent: "git-specialist"
model: Auto (copilot)
tools: [execute, read, edit, search, agent]
---

Workflow for the git-specialist to prepare and commit changes (applying `git-expert` rules in `.github/skills/git-expert/references/commit-conventions.md`):

1. **Determine what to commit** — Inspect the repository state (`git status --porcelain`). If the user named specific files, use those. Otherwise, if the user gave no direction and there are staged changes, use staged changes only. Otherwise use unstaged changes. If there is nothing to commit, halt and inform the user.

2. **Review the changes** — Triage staged changes with `.github/skills/git-expert/scripts/git-diff-triage.py --threshold=40 -- --staged` (or inspect diffs directly for unstaged files). Note any filename or secret-hygiene issues.

3. **Generate the commit message** — Write a Conventional Commit message following `git-expert/references/commit-conventions.md` (imperative mood, subject under 50 chars, body lines under 72 chars) that accurately summarises the changes. Never invent details not present in the diff.

4. **Present for approval** — Show the user:
   - the proposed commit message, and
   - a summary of the files to be committed.
   Wait for explicit approval before proceeding.

5. **Commit on approval** — Once the user approves, commit the changes using the approved commit message. If the user requested changes, revise and re-present before committing.

**Hard constraints:**
- Never run `git commit` without explicit user approval
- Generate the message from the actual diff, never from assumptions
- No backticks in the commit message
