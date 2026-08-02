---
description: Git commit workflow
---

## Procedure

- Load skill(git-expert) and read the `references/commit-standards.md` reference
- Generate commit message for staged files only
- Do not commit without the users approval of the commit message
- If the user requests changes, do not try to commit immediately, ask for approval again
- Write the commit message to a unique temporary file using the system temp directory
- If the user approves the commit, then commit using the approved commit message
