---
description: "Run the git-expert commit workflow: preflight, diff triage, and draft a Conventional Commit message"
argument-hint: "Run the git-expert commit workflow"
agent: "frugal"
tools: [execute/getTerminalOutput, execute/killTerminal, execute/createAndRunTask, execute/runInTerminal, read/readFile, search]
---

Run the git-expert commit workflow to prepare a commit:

1. **Collect context** — Execute the preflight script:
   ```bash
   bash .github/skills/git-expert/scripts/preflight.sh
   ```

2. **Check staged changes** — If `NO_STAGED_CHANGES`, check for unstaged changes. If no changes at all, halt and inform the user.

3. **Filename checks** — Analyse filenames for issues or concerns.

4. **File diffs** — Execute the git-diff-triage script:
   ```bash
   python3 .github/skills/git-expert/scripts/git-diff-triage.py --threshold=40 -- --staged
   ```

5. **Assess complexity** — Determine single-line vs multiline based on the diff.

6. **Draft message** — Apply Conventional Commit format rules from `.github/skills/git-expert/references/commit-message-format.md`.

7. **Write to file** — Write the draft commit message to a temp file using `mktemp`.

8. **Present to user** — Show the draft commit message and the full `git commit -F` command. Wait for explicit user approval before committing.

**Hard constraints:**
- Never run `git commit` without user instruction
- Generate from `git diff --staged`, never from working tree
- Write message to a file via the file-writing tool (never shell redirection)
- Pull subject/body content from the staged diff — never invent details
- No backticks in the commit message
- Subject < 50 chars, body lines < 72 chars, imperative mood
