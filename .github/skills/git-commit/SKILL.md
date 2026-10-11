---
name: git-commit
description: >
  Prepare and execute git commits with strict Conventional Commit formatting and
  interactive safety gates: inspect staged diffs, triage changes, draft commit messages
  following format guidelines, and present exact commands for approval. Use when asked
  to commit changes, draft commit messages, or review staged changes.
user-invocable: true
---

# Git Commit

Use this skill whenever asked to commit changes, draft commit messages, or review staged changes for commit.

This skill provides a safe, interactive step-by-step commit procedure and formatting rules.

## Pillar 1: Commit Workflow

Execute this workflow step-by-step when preparing and creating a git commit.

### Step 1: Collect Context
Check repository status using `git status --porcelain` (or running the helper script `<skills-dir>/git-expert/scripts/status.sh`).
Verify staged vs. unstaged changes.
- **If staged changes exist**: Proceed to Step 2.
- **If no staged changes exist**: Stop immediately and ask the user to stage the intended files using `git add`. Do NOT automatically stage files or proceed without staged changes.

### Step 2: Filename & Safety Checks
Analyze staged filenames:
- Check for naming convention rules or unintended files.
- Inspect for sensitive files or secrets (e.g., credentials, `.env` files, private keys).
- Raise any concerns or warnings to the user before proceeding.

### Step 3: Staged Diff Triage
Review the staged diff efficiently:
- Run `python3 <skills-dir>/git-expert/scripts/git-diff-triage.py --threshold=40 -- --staged` or inspect `git diff --staged`.
- Token-efficient review: for small diffs (≤ 40 lines), review full content; for large diffs, inspect structural headers/hunks.

### Step 4: Assess Complexity
Determine whether the commit message should be single-line or multiline:
- **Default to simple single-line.**
- Use **single-line** for single files, single concerns, or multiple files representing one coherent change.
- Use **multiline** for multiple distinct concerns, non-obvious workarounds/migrations explaining *why*, breaking changes, or issue references (`Closes #123`).

### Step 5: Draft Commit Message
Draft the commit message adhering strictly to Pillar 2 (Commit Message Guidelines).
- Ensure subject < 50 characters, imperative mood, no period, no backticks.
- If multiline, body lines < 72 characters explaining *why* (not restating *what*).

### Step 6: Write Message to Temporary File
Create a temporary file using `mktemp` (yielding e.g. `<msg-file>`) and write the draft commit message to it.
- **MUST** use native file writing tools (e.g. `write_file`).
- **NEVER** use shell redirection (`>`) or inline echo to create or write the file.

### Step 7: Present Command & Await Explicit Approval
Present the exact commit command to the user for explicit approval:
```bash
git commit -F <msg-file>
```
- Display the drafted message content clearly.
- **Await explicit user approval** before running `git commit`.
- After successful commit execution and approval, clean up the temporary file (`rm <msg-file>`).

### Operational Hard Constraints
- **Explicit Approval Gate**: NEVER run `git commit` without explicit user permission.
- **Staged Only**: MUST generate commit message from `git diff --staged`, never from unstaged working tree changes.
- **No Backticks**: MUST NOT use backticks anywhere in the commit message (they break shell hooks and tools).
- **Native File Write**: MUST write draft commit messages via file tools, never shell redirection.


## Pillar 2: Commit Message Guidelines

### Format Rules

#### Single-line
```
type(scope): subject
```
- `scope`: OPTIONAL — omit when obvious from subject or when change spans unrelated paths.
- `subject`: imperative mood ("add", not "added" or "adding"), < 50 chars, no trailing period.

#### Multiline
```
type(scope): subject

- why or non-obvious detail
- second distinct concern (if any)

Closes #123
```
- **Subject**: Inherits single-line rules.
- **Body lines**: Imperative mood, < 72 chars per line, explain *why* not *what*. Never repeat what the subject states.
- **Footer**: Issue references (`Closes #123`, `Fixes #456`, `Refs #789`) — omit if none.

### Type Table

| Type | Purpose |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `hotfix` | Emergency fix (main/master branch override) |
| `docs` | Documentation |
| `style` | Formatting / whitespace only |
| `refactor` | Code restructuring without behaviour change |
| `perf` | Performance improvement |
| `test` | Tests |
| `chore` | Maintenance, dependencies, build tasks |
| `ci` | CI/CD pipeline |
| `revert` | Revert a prior commit |

#### Main/Master Branch Hotfix Override
IF current branch is `main` OR `master` AND commit type would be `fix` → use `hotfix` instead.

### Format Hard Constraints
- **Subject length**: MUST be < 50 chars.
- **Body line length**: MUST be < 72 chars per line.
- **Imperative mood**: MUST use imperative ("add", "fix", "refactor").
- **No trailing period**: Subject MUST NOT end with a period.
- **No backticks**: MUST NOT contain backticks anywhere.
- **No body restatement**: Body bullets MUST NOT merely repeat the subject line.

### Examples

#### Simple: Single File / Clear Change
```
feat(auth): add OAuth login
```

#### Simple: Hotfix on Main Branch
```
hotfix(session): clear token on logout timeout
```

#### Complex: Multiple Concerns + Issue Reference
```
refactor(api): split user and session handlers

- user handler was doing session management, violating SRP
- session state now lives in SessionStore, injected at startup

Closes #89
```
