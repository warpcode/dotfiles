# Commit Message Format

Reference for the format and syntax of a git commit message. This file covers
ONLY how a message is shaped — the format rules for subjects, bodies, footers,
and the two allowed formats. It does NOT cover how to gather context, branches,
or staged metadata; that is handled in `@references/commit-workflow.md`. 
Read this file whenever you need to draft a commit message.

## Complexity Assessment

**Default to simple.** Use multiline only when the change genuinely cannot be
summarised in one line without losing important context.

| Signal | → Format |
|--------|----------|
| Single file, single concern | Single line |
| Multiple files, one coherent change | Single line |
| Multiple files, multiple distinct concerns | Multiline |
| Non-obvious why (not what) — workaround, migration step | Multiline |
| Breaking change or issue reference needed | Multiline |

**When in doubt → single line.**

MUST NOT add a body that merely restates the subject in different words. Body
lines exist to explain *why*, not to repeat *what*.

## Conventional Format

### Single-line

```
type(scope): subject
```

- `scope` is OPTIONAL — omit when obvious from subject or when the change spans
  unrelated paths
- `subject`: imperative, < 50 chars, no trailing period

### Multiline

```
type(scope): subject

- why or non-obvious detail
- second distinct concern (if any)

Closes #123
```

- Single line: Inherit single line rules
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

### On main/master branch

```
subject
```

Body and footer rules are identical to Conventional.

```
[tic-3456] add OAuth login
[new-admin-page-tic-4567] add admin dashboard

- behind feature flag pending QA sign-off
- requires DB migration 0042 to run first

Closes TIC-4567
```

## Hard Constraints

| Rule | Requirement |
|------|-------------|
| Subject length | MUST be < 50 chars |
| Body line length | MUST be < 72 chars if included |
| Mood | MUST use imperative ("add", not "added" or "adding") |
| Backticks | MUST NOT appear anywhere in the message — they break shell hooks |
| Body restatement | MUST NOT write body bullets that repeat what the subject already states |

## Examples

### Simple: single file, clear change
```
feat(auth): add OAuth login
```

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