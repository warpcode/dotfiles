# PROTOCOLS: COMMANDS

## CORE FUNCTION
- **Goal**: Encapsulate workflows -> Simple `/command` invocation.
- **Scope**: Reusable templates, multi-step processes, ecosystem integration.

## OPERATIONAL PROCESS
### 1. Scan & Analyze
- **Action**: `list(~/.config/opencode/)` -> Identify(Skills, Agents, Tools).
- **Logic**: Workflow_Reqs + Available_Components -> Command_Plan.

### 2. Template Generation
- **Format**: Markdown with YAML frontmatter.
- **Input**: `$ARGUMENTS` == MANDATORY (Dynamic Input).
- **Ref**: Use exact names (`skills_[name]`, `@agent/name`).

### 3. Validation
- **Check**: Ref_Exists? && Tool_Perms? && Name_Unique?
- **Rule**: Never reference non-existent components.

## SYNTAX & STRUCTURE
```markdown
---
description: >-
  [Multi-line description for context].
  [Use >- for continuation].
agent: [Optional: @agent/name]
---

1. Step_1: Action($ARGUMENTS).
2. Step_2: Verify(Result).
3. Step_3: Error_Handle -> Fallback.
```

### Inline Command Execution
- **Syntax**: `!`command` for shell command output in command context
- **Usage**: Embed context from git, environment checks, or file operations
- **Preference**: Use inline execution where feasible to save AI tokens and direct calls
- **When to use**:
  - Static data retrieval (dates, branches, file existence)
  - Environment variable checks
  - Git status/info
  - Simple conditionals that return strings
  - Non-destructive commands
- **Error handling (MANDATORY)**:
   - **Handle inline**: All error handling must be within the command itself
   - **Simple error handling**: `command 2>/dev/null || fallback` (preferred, no `command -v` needed)
   - **Conditional checks**: `command -v tool && tool command` (only when you need to check existence BEFORE execution for conditional logic)
   - **Shell operators**: `||` for error fallbacks, `&&` for success chains
   - **Default values**: `${VAR:-default}` for missing environment variables
   - **Suppress errors**: `2>/dev/null` to hide error output
   - **PROHIBITED**: `2>&1` redirect syntax causes parser errors (use `2>/dev/null` instead)
- **Examples**:
   - Environment variables: `IS_WORK=!`echo ${IS_WORK:-0}`
   - Date/time: `Today:!`date +%Y-%m-%d`
   - Git status: !`git status --porcelain || echo "clean"`
   - Branch name: !`command -v git && git rev-parse --abbrev-ref HEAD || echo "not-in-git"`
   - File checks: !`test -f .env && echo "exists" || echo "not found"`
   - Command results: !`gh pr list --state merged --json title | jq '.[] | .title' 2>/dev/null || echo "none"`

#### Error Handling Patterns
```markdown
# Pattern 1: Simple error handling (no pre-check needed)
1. PRS=!`gh pr list --state merged --search "merged:$(date +%Y-%m-%d)" --json title,body 2>/dev/null || echo "none"`
2. IF $PRS == "none" → Report(No merged PRs today)

# Pattern 2: Check and execute inline (when pre-check is needed)
1. BRANCH=!`command -v git && git rev-parse --abbrev-ref HEAD || echo "no-git"`
2. IF $BRANCH == "no-git" → Error(Git not installed or not in repo) → EXIT

# Pattern 3: Validate with fallback
1. RESULT=!`cat data.json | jq '.key' 2>/dev/null || echo "default"`
2. IF $RESULT == "default" → Warning(Using default value)

# Pattern 4: Continue on non-critical failure
1. OPTS=!`test -f .options && cat .options || echo ""`
2. IF empty($OPTS) → Set(DEFAULT_OPTS)

# Pattern 5: External CLI with auth check
  1. PRS=!`gh pr list --state merged --search "merged:$(date +%Y-%m-%d)" --json title,body 2>/dev/null || echo "none"`
  2. IF $PRS == "none" → Report(No merged PRs or auth failed)
```
## SECURITY & VALIDATION (MANDATORY)
- **Prohibition**: Hardcoded credentials == FORBIDDEN.
- **Input Sanitization**: `$ARGUMENTS` -> Strip dangerous chars -> Validate schema.
- **Destructive Ops**: `rm`, `sudo`, `git push -f`, `chmod` -> Require `User_Confirm`.
- **Validation Pipeline**:
  1. Parse `$ARGUMENTS`
  2. Sanitize (remove shell escapes)
  3. Validate schema/type
  4. Confirm if destructive
  5. Execute safely
- **Error Handling**: Never expose secrets in error messages.

## EXAMPLES
### Basic
```markdown
---
description: Review code.
agent: quality/code-reviewer
---
1. Check: FILE_CHECK=!`test -f "$ARGUMENTS" && echo "exists" || echo "missing"`
2. IF $FILE_CHECK == "missing" → Error(File not found: $ARGUMENTS) → EXIT
3. Analyze: `$ARGUMENTS`.
4. Report: Issues + Fixes.
```

### Complex
```markdown
---
description: >-
  Deploy feature with comprehensive validation.
  Requires testing and git workflow integration.
---
1. Environment: IS_WORK=!`echo ${IS_WORK:-0}`
2. Current branch: BRANCH=!`git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-git"`
3. IF $BRANCH == "no-git" → Error(Git not installed or not in repo) → EXIT
4. IF $BRANCH == "main" → Error(Not allowed on main) → EXIT
5. Validate($ARGUMENTS).
6. IF success → Execute($ARGUMENTS) → ELSE Report(Error).
7. Branch(skills_git_workflow).
8. Merge_Request.
```

### With Commands & Routing
```markdown
---
description: >-
  Analyze git status and route to appropriate action.
  Uses inline commands for context.
---

1. Git status: STATUS=!`git status --porcelain 2>/dev/null || echo "not-in-git"`
2. IF $STATUS == "not-in-git" → Error(Git not installed or not in repo) → EXIT
3. Branch: BRANCH=!`git rev-parse --abbrev-ref HEAD`
4. Staged: STAGED=!`git diff --cached --name-only 2>/dev/null || echo ""`
5. IF empty($STAGED) → Exit(No changes to commit)
6. IF conflicts → Read(@references/merge-conflicts.md) → Resolve
7. skills_git_workflow(Commit with message: $ARGUMENTS)
```

### With External CLI Integration
```markdown
---
description: >-
  Fetch and summarise GitHub pull requests merged today.
  Uses gh CLI with inline error handling.
---

 1. Date: TODAY=!`date +%Y-%m-%d`
  2. PRs: PRS=!`gh pr list --state merged --search "merged:$(date +%Y-%m-%d)" --json title,body 2>/dev/null || echo "none"`
 3. IF $PRS == "none" → Report(No merged PRs today or auth failed) → EXIT
4. Transform: Each PR → Business-friendly summary
5. Output: Bullet list with emojis
```

## BEST PRACTICES

### When to use `command -v`:
- You need to check existence BEFORE execution for conditional logic (e.g., `IF installed → do X, ELSE do Y`)
- You're executing multiple commands that depend on the tool being installed

### When NOT to use `command -v`:
- Simple command execution with error fallback
- Single commands where the error handling covers both missing tool and execution failure
- Using `2>/dev/null || fallback` pattern is sufficient and cleaner

**Example of unnecessary check:**
```markdown
# ❌ Over-engineered
PRS=!`command -v gh && gh pr list --state merged 2>/dev/null || echo "none"`

# ✓ Simpler and clearer
PRS=!`gh pr list --state merged 2>/dev/null || echo "none"`
```

**Example where check is needed:**
```markdown
# ✓ Necessary: Conditional logic based on tool availability
HAS_GIT=!`command -v git && echo "yes" || echo "no"`
IF $HAS_GIT == "yes" → Execute_Git_Ops ELSE Warn(Git not installed)
```

