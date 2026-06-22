---
name: git-commit-message
description: >
  Generate git commit messages and commit staged changes. Use this skill
  whenever the user asks to commit, write a commit message, stage and commit,
  or says anything like "commit this", "write a commit", "make a commit",
  "commit my changes", or "help me commit". Also trigger when the user
  asks to review staged changes with the intent to commit. Generates
  conventional or work-based commit messages, writes them to a temp file,
  and provides the exact git command to run — never commits automatically.
---

# Git Commit Message Skill

Generate the right commit message for the change — simple when the change is
simple, detailed only when complexity demands it.

---

## Workflow

```
1. Collect context   → branch, user, staged diff
2. Select strategy   → Conventional or Work-Based
3. Assess complexity → single-line or multiline?
4. Draft message     → apply format rules
5. Write to file     → use write_file tool
6. Present to user   → show message + git commit command
```

### Step 1 — Collect context

Run the bundled context retriever script to gather all staged metadata in a single call:

```bash
./scripts/get_git_context.sh
```

IF no staged changes or the output indicates `STATUS: NO_STAGED_CHANGES` → stop, tell user to `git add` files first.

### Step 2 — Select strategy

```
IF git config user.name != "Warpcode" AND $IS_WORK == 1:
    strategy = Work-Based
ELSE:
    strategy = Conventional
```

### Step 3 — Assess complexity

**Default to simple.** Use multiline only when the diff genuinely cannot be
summarised in one line without losing important context.

| Signal | → Format |
|--------|----------|
| Single file, single concern | Single line |
| Multiple files, one coherent change | Single line |
| Multiple files, multiple distinct concerns | Multiline |
| Non-obvious why (not what) — e.g. workaround, migration step | Multiline |
| Breaking change or issue reference needed | Multiline |

**When in doubt → single line.**

MUST NOT add a body that merely restates the subject in different words.
Body lines exist to explain *why*, not to repeat *what*.

### Step 4 — Draft message

See **Conventional Format** or **Work-Based Format** below.

### Step 5 — Write to file

Use the `write_file` tool to save the generated message to `/tmp/COMMIT_MSG`.

**NEVER** write the commit message file using shell commands (e.g., `cat`, `echo`, or heredocs). Always use the provided `write_file` tool for file creation.

### Step 6 — Present to user

Display the message in a code block, then show:

```bash
git commit -F /tmp/COMMIT_MSG
```

MUST NOT run `git commit` automatically. Show the command; let the user run it.

---

## Conventional Format

**Used when**: strategy = Conventional (personal projects, Warpcode's own repos)

### Single-line

```
type(scope): subject
```

- `scope` is OPTIONAL — omit when obvious from subject or when change spans
  unrelated paths
- `subject`: imperative, < 50 chars, no trailing period

### Multiline

```
type(scope): subject

- why or non-obvious detail
- second distinct concern (if any)

Closes #123
```

- Body lines: imperative, < 72 chars, explain *why* not *what*
- Footer: issue references only (`Closes`, `Fixes`, `Refs`) — omit if none

### Type table

| Type | Purpose |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `hotfix` | Emergency fix (main/master only — see override below) |
| `docs` | Documentation |
| `style` | Format / whitespace only |
| `refactor` | Restructure without behaviour change |
| `perf` | Performance improvement |
| `test` | Tests |
| `chore` | Maintenance, dependencies |
| `ci` | CI/CD pipeline |
| `revert` | Revert a prior commit |

**Hotfix override**: IF branch is `main` OR `master` AND type would be `fix`
→ use `hotfix` instead.

---

## Work-Based Format

**Used when**: `git config user.name` != `Warpcode` AND `$IS_WORK == 1`

Does NOT use conventional type/scope format.

### On a feature/fix branch (not main/master)

```
[branch-name] subject
```

### On main/master

```
subject
```

### Single-line example

```
[tic-3456-tic3457] add OAuth login
```

### Multiline example

```
[new-admin-page-tic-4567] add admin dashboard

- behind feature flag pending QA sign-off
- requires DB migration 0042 to run first

Closes TIC-4567
```

Body and footer rules are identical to Conventional.

---

## Hard Constraints

| Rule | Requirement |
|------|-------------|
| Subject length | MUST be < 50 chars |
| Body line length | MUST be < 72 chars |
| Mood | MUST use imperative ("add", not "added" or "adding") |
| Backticks | MUST NOT appear anywhere in the message — they break shell hooks |
| Auto-commit | MUST NOT run `git commit` without user instruction |
| Staged only | MUST generate from `git diff --staged`, never from working tree |
| Commit file | MUST write message to `/tmp/COMMIT_MSG` via `write_file` tool (NEVER shell) |
| Body restatement | MUST NOT write body bullets that repeat what the subject already states |

---

## Examples

### Simple: single file, clear change
```
feat(auth): add OAuth login
```
`git commit -F /tmp/COMMIT_MSG_a1b2c3 && rm /tmp/COMMIT_MSG_a1b2c3`

### Simple: hotfix on main
```
hotfix(session): clear token on logout timeout
```

### Complex: multiple concerns + issue ref
```
refactor(api): split user and session handlers

- user handler was doing session management, violating SRP
- session state now lives in SessionStore, injected at startup

Closes #89
```

### Work-Based: feature branch
```
[tic-3456] add OAuth login
```

### Work-Based: multiline with context
```
[hotfix-login-bug] validate input before auth check

- nil user object caused panic on malformed JWT
- adds guard clause, existing tests updated

Fixes TIC-9901
```
 user object caused panic on malformed JWT
- adds guard clause, existing tests updated

Fixes TIC-9901
```
