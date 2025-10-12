---
description: Use this command to generate diffs between the current repository state and the main branch, then check for spelling and grammatical mistakes in the changes.
---

## Restrictions

- Do not modify files or run commands that change the repository state.

## Steps

First, determine the main branch: check if 'main' branch exists, if not use 'master'.

Generate a diff between the current HEAD and the main branch using `git diff main...HEAD` or `git diff master...HEAD`.

Also generate diff for unstaged changes using `git diff`.

Also generate diff for staged changes using `git diff --staged`.

Analyze the diffs for:

- Spelling mistakes
- Grammatical errors
- Typos in comments, strings, documentation, and code identifiers

Compare the changes to the original code on the main branch to provide context.

Provide a summary of findings with specific line numbers and suggestions for correction.

If no issues found, state that the text looks good.

