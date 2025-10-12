---
description: Use this command to generate a diff between the current repository state and the main branch (master if main doesn't exist), then review the changes for inefficient and bad practice code.
mode: command
---

## Restrictions
- Do not run unit tests without explicit permission.

## Steps
First, determine the main branch: check if 'main' branch exists, if not use 'master'.

Generate a diff between the current HEAD and the main branch using `git diff main...HEAD` or `git diff master...HEAD`.

Also generate diff for unstaged changes using `git diff`.

Check Makefiles, scripts, package.json, etc., for commands to check or lint code (e.g., make lint, npm run lint) and incorporate their results into the review.

Analyze the diffs for:
- Inefficient code patterns (e.g., unnecessary loops, redundant computations)
- Bad practices (e.g., hardcoded values, lack of error handling, poor naming conventions)
- Security issues (e.g., exposed secrets, insecure functions)
- Code style violations (e.g., inconsistent indentation, long lines)
- Linting issues (e.g., syntax errors, unused variables)
- Potential bugs (e.g., null pointer dereferences, race conditions)
- Adequate documentation
- Documentation explains why the code is the way it is, not narrates the code itself
- Unnecessary comments
- Methods/functions have appropriate comment blocks for the language (e.g., PHP uses PHP docblock)
- Adherence to style guides: PHP should match PSR-12 and/or follow rules in a codesniffer file, Python should follow PEP8, JavaScript/TypeScript should follow standards (e.g., if eslint or prettier config is present)

Compare the changes to the original code on the main branch to provide context.

Provide a summary of findings with specific line numbers and suggestions for improvement.

If no issues found, state that the code looks good.