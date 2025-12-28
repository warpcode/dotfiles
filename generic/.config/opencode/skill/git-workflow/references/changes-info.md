# Git Info Retrieval

<rules>
## Phase 1: Clarification
IF query.ambiguous -> List(Missing: local/remote, specific operation) -> Wait(User_Input)

## Phase 2: Planning
Route: gh (GitHub) OR git (local). IF auth_missing -> Suggest(`gh auth login`)

## Phase 3: Execution
Parse -> Execute -> Format(MD/bullets/KV)

## Phase 4: Validation
Output == Expected_Format? Auth_Valid? IF Fail -> Suggest/Fallback
</rules>

<context>
**Dependencies**: git (CLI), gh (GitHub CLI - optional)

**Threat Model**:
- Input -> Sanitize(shell_escapes) -> Validate(path_exists) -> Execute
- Private repos: Verify auth before operations
</context>

## Routing Logic

```
IF target == "GitHub" (PRs/issues/releases/URLs):
  -> Use gh CLI
  
ELSE IF target == "local" (status/branches/commits):
  -> Use git CLI
```

## Operations Matrix

| Category | Operation | Command | Format |
|----------|-----------|---------|--------|
| PRs | View | `gh pr view <num>` | Key-value metadata |
| PRs | Diff | `gh pr diff <num>` | MD diff |
| PRs | Comments | `gh pr view <num> --comments` | Bullets |
| PRs | List | `gh pr list` | Table |
| Local | Status | `git status` | Bullets |
| Local | Unstaged | `git diff` | MD diff |
| Local | Staged | `git diff --staged` | MD diff |
| Local | Unpushed | `git log --oneline origin/main..HEAD` | Bullets |
| Commits | History | `git log --oneline -10` | Bullets |
| Commits | Details | `git show <hash>` | MD + stat |
| Commits | Stat | `git show --stat <hash>` | Table |
| Branches | List | `git branch -a` | Bullets |
| Branches | Compare | `git diff <b1>..<b2>` | MD diff |
| Repo | GitHub | `gh repo view` | Key-value |
| Repo | Remotes | `git remote -v` | Table |
| Repo | Contributors | `gh repo view --contributors` | Table |

## Execution Standards

1. **Parse**: Extract intent -> Select operation -> Validate params
2. **Execute**: Run command -> Capture output -> Handle errors
3. **Format**: 
   - Diffs -> MD code blocks
   - Logs -> Bullet lists
   - Metadata -> Key-value pairs
4. **Error Handling**:
   - Auth required -> Suggest `gh auth login`
   - gh unavailable -> Fallback to git
   - Large output -> Summarize/limit

## Constraints

- git: Available locally
- gh: Optional, requires auth for private repos
- Network: Required for remote operations

## Examples

<example>
User: "Show PR status"
Route: gh PR view -> Format metadata
Result: PR #123 open, 3 files changed, 2 reviews
</example>

<example>
User: "What's changed?"
Route: git status + diff -> Format bullets + MD diff
Result: 2 modified files, 1 new feature
</example>
