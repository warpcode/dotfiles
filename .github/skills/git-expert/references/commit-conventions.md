# Commit Conventions

Reference for Conventional Commits formatting, atomic commit standards, message complexity selection, and safety constraints. Interactive commit preparation and approval workflows live in `.github/prompts/commit.prompt.md` and `.github/agents/git-specialist.agent.md`.

## Conventional Commit Format

```text
type(scope): subject
```

- `scope` is OPTIONAL.
- `subject`: imperative mood, under 50 characters, no trailing period.

If multiline:
- Blank line between subject and body.
- Body lines: imperative mood, under 72 characters, explain *why* rather than *what*. Must not repeat the subject.
- Footer: issue references only (`Closes #n`, `Fixes #n`, `Refs #n`). Omit if none.

## Full Type Table

| Type | Purpose |
|------|---------|
| `feat` | New feature |
| `fix` | Bug fix |
| `hotfix` | Emergency fix (`main`/`master` only) |
| `docs` | Documentation |
| `style` | Format / whitespace only |
| `refactor` | Restructure without behaviour change |
| `perf` | Performance improvement |
| `test` | Tests |
| `chore` | Maintenance, dependencies |
| `ci` | CI/CD pipeline |
| `revert` | Revert a prior commit |

### Hotfix Override for Main/Master Branches

If the target branch is `main` or `master` and the change type would be `fix`, use `hotfix` instead.

## Complexity Decision Matrix & Atomic Standards

Keep each commit focused on a single logical change so it can be reviewed, cherry-picked, or reverted cleanly without dragging unrelated edits along.

Determine single-line vs. multiline commit messages from the change shape:

| Change shape | Message format |
|---|---|
| Single file, single concern | Single line |
| Multiple files, one coherent change | Single line |
| Multiple files, multiple distinct concerns | Multiline (or split into atomic commits) |
| Non-obvious *why* (workaround, migration step, trade-off) | Multiline |
| Breaking change or issue reference needed | Multiline |

## Staged Diff Review & Push Delegation

- Review staged changes with `@scripts/git-diff-triage.py --threshold=40 -- --staged` (or `git diff --staged --stat` prior to inspecting hunks) to keep diff inspection token-efficient.
- Commit messages must be derived from staged diffs only (`git diff --staged`); never silently stage unstaged changes or invent details not present in the diff.
- Write draft commit messages to a temporary file (e.g. via `mktemp` and native file editing, not shell redirection) and commit with `git commit -F <file>` only after explicit user approval.
- Do not push automatically after committing; delegate pushes to `@scripts/push.sh` so preflight commit inspection and safety gates run.

## Hard Constraints

- NEVER run `git commit` without explicit user approval.
- Generate the message from the actual staged diff (`git diff --staged`), never from assumptions.
- Subject length MUST be under 50 characters.
- Body line length MUST be under 72 characters when included, and MUST NOT restate the subject.
- Mood MUST be imperative (`add`, not `added` or `adding`).
- Backticks MUST NOT appear anywhere in the commit message.
- Footer references must use valid keywords (`Closes`, `Fixes`, `Refs`).

## Examples

**Simple: single file, clear change**
```text
feat(auth): add OAuth login
```

**Simple: hotfix on main**
```text
hotfix(session): clear token on logout timeout
```

**Complex: multiple concerns + issue ref**
```text
refactor(api): split user and session handlers

- user handler was doing session management, violating SRP
- session state now lives in SessionStore, injected at startup

Closes #89
```
