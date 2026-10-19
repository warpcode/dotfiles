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

## Pillar 1: Commit Workflow

### Step 1: Collect Context
Check for staged files. You must abort if there are no staged changes.
Do not silently include unstaged changes or stage files on the user's behalf.
Collect status with `git status --porcelain`.

### Step 2: Filename & Safety Checks
Analyse the filenames for review and raise any issues or concerns to the user. Halt if there are sensitive files or naming rule violations.

### Step 3: Staged Diff Triage
Perform a token-efficient diff review of the staged changes using the explicit command: `python3 ~/.gemini/config/skills/git-expert/scripts/git-diff-triage.py --threshold=40 -- --staged`. This limits the context budget by hiding large diff contents.

### Step 4: Assess Complexity
Determine whether the commit message should be a single line or multiline based on the decision matrix below:
- Single file, single concern → Single line
- Multiple files, one coherent change → Single line
- Multiple files, multiple distinct concerns → Multiline
- Non-obvious why (not what) — workaround, migration step → Multiline
- Breaking change or issue reference needed → Multiline

### Step 5: Draft Commit Message
Draft the commit message adhering to the message guidelines in Pillar 2.

### Step 6: Write Draft Message to a Temporary File
Write the commit message to a temporary file in the system tmp directory using `mktemp`.
You MUST use the native edit file tool available to write the draft commit message.
Never use shell redirection (`>`).

### Step 7: Present Command for Approval
Present the exact command `git commit -F /tmp/... && rm /tmp/...` to the user and await explicit approval.

### Hard Operational Constraints
- Never run `git commit` without explicit user approval.
- Generate the message from the actual diff, never from assumptions.
- Must generate from staged diffs only (`git diff --staged`).
- No backticks in the commit message.

## Pillar 2: Commit Message Guidelines

### Conventional Commit Format
`type(scope): subject`

- `scope` is OPTIONAL.
- `subject`: imperative, < 50 chars, no trailing period.

If multiline:
- Body lines: imperative, < 72 chars, explain *why* not *what*. Must not repeat the subject.
- Footer: issue references only (`Closes`, `Fixes`, `Refs`). Omit if none.

### Full Type Table
| Type | Purpose |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `hotfix` | Emergency fix (main/master only) |
| `docs` | Documentation |
| `style` | Format / whitespace only |
| `refactor` | Restructure without behaviour change |
| `perf` | Performance improvement |
| `test` | Tests |
| `chore` | Maintenance, dependencies |
| `ci` | CI/CD pipeline |
| `revert` | Revert a prior commit |

### Hotfix Override for Main/Master Branches
IF branch is `main` OR `master` AND type would be `fix` → use `hotfix` instead.

### Hard Constraints
- Subject length MUST be < 50 chars.
- Body line length MUST be < 72 chars if included.
- Mood MUST use imperative ("add", not "added" or "adding").
- Backticks MUST NOT appear anywhere in the message.
- Body restatement MUST NOT write body bullets that repeat what the subject already states.
- Footer references must be valid (`Closes`, `Fixes`, `Refs`).

### Examples

**Simple: single file, clear change**
```
feat(auth): add OAuth login
```

**Simple: hotfix on main**
```
hotfix(session): clear token on logout timeout
```

**Complex: multiple concerns + issue ref**
```
refactor(api): split user and session handlers

- user handler was doing session management, violating SRP
- session state now lives in SessionStore, injected at startup

Closes #89
```