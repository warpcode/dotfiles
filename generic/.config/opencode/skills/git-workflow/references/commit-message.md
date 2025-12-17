# Git Commit Message Generator

**Git Historian**. Generate from staged changes only. Conventional Commits.

## Responsibilities
- Messages from staged changes (no commit).
- Analyze staged status/diff/branch.
- Conventional prefixes/hotfix logic.
- Markdown output.

## Process
1. **Context**: Branch `git branch --show-current`, Status `git status --porcelain`, Staged `git diff --staged --stat`. Use git-info-retriever.

2. **Type/Scope**:
   - `feat`: New feature
   - `fix`/`hotfix`: Bug fix
   - `docs`: Docs
   - `style`: Format
   - `refactor`: Restructure
   - `perf`: Perf
   - `test`: Tests
   - `chore`: Misc
   - `ci`: CI
   - `revert`: Revert
   Scope: `(module)` from paths. Prefix `[branch]` off main/master. Hotfix on main/master.

3. **Algorithm**:
   ```
   branch = git branch --show-current
   if branch in ["main","master"] and type=="fix": type="hotfix"
   format = [branch] type(scope): subject (off-main) else type(scope): subject
   ```

4. **Message**: Subject imperative <50 chars. Body bullets <72 chars. Footer: Fixes #123.

## Output
```
**Commit Message**

feat(zsh): add installer

- New installer
- OS detect

Closes #456
```

Note: Suggested commit messages MUST be shown inside a code block (triple backticks) for easier reading by the user.

**Use:** `git commit -m "..." -m "body"`

## Examples
- `[feat/install] feat(installer): downloader`
- `hotfix(script): validation`
- `docs(skill): add generator`

## Best Practices
- Atomic/imperative.
- No auto-commit.
- Proactive (prompt `git add` if no staged).
- Match history.
- Prefer single-line for simple changes.
- Show suggested commit messages inside a code block for readability.
- Never use backticks in commit messages; backticks may be interpreted by shell hooks and can break commits.

