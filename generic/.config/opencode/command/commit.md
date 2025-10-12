---
description: Use this command to stage and commit changes in the current git repository. It performs a peer review, requires user confirmation, and generates a commit message with appropriate prefixes.
mode: command
---

## Restrictions

- Do not push to remote repositories.
- Do not modify files without user approval.
- Only stage changes that are approved after peer review.

## Steps

First, verify this is a git repository. If not, exit with an error.

Determine the current branch name using `git branch --show-current`.

Prefix the commit message with "[branch-name]" (in lowercase) if not main/master.

Determine if this is a hotfix: if specified as a hotfix, set a flag to prefix the commit message with "hotfix: " after the branch prefix.

Run the peer-review command steps:

- Determine the main branch (check if 'main' exists, else 'master').
- Generate diff between current HEAD and main branch using `git diff main...HEAD` or `git diff master...HEAD`.
- Generate diff for unstaged changes using `git diff`.
- Generate diff for staged changes using `git diff --staged`.
- Check Makefiles, scripts, package.json, etc., for lint commands (e.g., make lint, npm run lint) and run them if available.
- Analyze all diffs for inefficient code, bad practices, security issues, style violations, linting issues, bugs, documentation adequacy, unnecessary comments, and adherence to style guides.
- Compare changes to original code on main branch.
- Provide a summary of findings with line numbers and suggestions.

Present the peer-review findings to the user and ask for confirmation to proceed with staging and committing. If the user does not approve, stop and suggest fixes.

If approved, stage only the changes that were reviewed (typically all unstaged changes, but exclude any untracked files unless specified).

When a file is specified and it is untracked, it should add it to git. Otherwise, referenced files that are unstaged should be staged.

Generate a commit message:

- Follow the repository's commit message style from recent commits (e.g., run `git log --oneline -5`).
- Draft a concise message focusing on "why" not "what".
- Prefix with "[branch-name]" if not main/master.
- If hotfix, add "hotfix: " after the branch prefix.
- Ensure the message is clear, not generic, and reflects the changes accurately.

Commit the staged changes using `git commit -m "message"`.

Run `git status` to confirm the commit.

