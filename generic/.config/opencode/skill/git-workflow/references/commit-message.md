# Git Commit Message Generator

<rules>
## Phase 1: Clarification
IF no_staged_changes -> Prompt(`git add` files) -> Wait(User_Input)

## Phase 2: Planning
Gather: Branch, Status, Staged Diff -> Analyze -> Generate(Conventional)

## Phase 3: Execution
Format: type(scope): subject -> Body bullets -> Footer

## Phase 4: Validation
Subject < 50 chars? Imperative? No backticks? IF Fail -> Rewrite
</rules>

<context>
**Dependencies**: git (CLI), @references/changes-info.md, @references/branch-strategies.md

**Threat Model**:
- Input -> Sanitize(shell_escapes) -> Validate(staged_only) -> Execute
- Rule: NEVER commit automatically
</context>

## Conventional Types

| Type | Purpose | Example |
|------|---------|---------|
| feat | New feature | feat(auth): add OAuth |
| fix | Bug fix | fix(ui): button alignment |
| docs | Documentation | docs(api): update endpoints |
| style | Format/whitespace | style(python): PEP8 |
| refactor | Restructure | refactor(db): schema |
| perf | Performance | perf(query): index |
| test | Tests | test(unit): coverage |
| chore | Misc | chore(deps): update |
| ci | CI/CD | ci(github): workflow |
| revert | Revert | revert: feat(xyz) |
| hotfix | Emergency fix | hotfix(login): timeout |

## Algorithm

```
# Context Collection
branch = git branch --show-current
user = git config user.name
status = git status --porcelain
diff = git diff --staged --stat

# Type Selection
IF branch in ["main", "master"] AND type == "fix":
  type = "hotfix"

# Format Logic
IF branch NOT in ["main", "master"]:
  format = "[{branch}] {type}({scope}): {subject}"
ELSE:
  format = "{type}({scope}): {subject}"

# Scope Extraction
scope = first_common_path(diff_files)

# Message Structure
subject: Imperative, <50 chars, NO periods
body: Bullets, <72 chars per line, imperative
footer: Closes #123, Fixes #456
```

## Work-Based Strategy Format

**Note**: "user" refers to `git config user.name` (git username)

**Condition**: When user != Warpcode && $IS_WORK == 1

**Rule**: Prefix commit messages with branch name when NOT on main/master

**Format**: `[branch-name] message`

**Note**: Work-Based Strategy does NOT use conventional commit type/scope format

**Examples**:
- `[tic-3456-tic3457] add OAuth login`
- `[new-admin-page-tic-4567] fix button alignment`
- `[hotfix-login-bug] validate input`

**Reference**: See @references/branch-strategies.md for full Work-Based Strategy details

**Workflow**:
1. Check: When user != Warpcode && `$IS_WORK == 1`
2. Get branch: `git branch --show-current`
3. IF branch NOT in ["main", "master"]: Prefix with `[branch-name]`

## Output Format

```markdown
**Commit Message**

```
feat(zsh): add installer

- New installer logic
- OS detection support

Closes #456
```

**Usage**: `git commit -m "subject" -m "body"`
```

## Constraints

1. **Atomic**: One logical change per commit
2. **Imperative**: Subject uses "Add feature" NOT "Added feature"
3. **Length**: Subject < 50 chars, Body lines < 72 chars
4. **No Backticks**: Backticks break shell hooks - NEVER use in messages
5. **No Auto-commit**: Show message, let user commit
6. **Staged Only**: Generate from `git diff --staged`
7. **Code Block**: Display in triple backticks for readability

## Examples

<example>
Branch: feature/add-login
Files: src/auth/login.py
Result: `feat(auth): add OAuth login`
</example>

<example>
Branch: main
Files: src/utils/helpers.py
Result: `hotfix(utils): validate input`
</example>

<example>
Branch: refactor/api
Files: src/api/*.py
Result: `[refactor/api] refactor(endpoint structure)`
</example>

<example>
Context: Work-Based Strategy (when user != Warpcode && $IS_WORK == 1)
Branch: new-admin-page-tic-4567
Files: src/admin/pages.py
Result: `[new-admin-page-tic-4567] add new page`
</example>
