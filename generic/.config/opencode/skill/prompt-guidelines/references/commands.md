---
description: >-
  Command definition schema and execution protocols.
  Reference for creating, validating, and optimising OpenCode commands.
---

## PHASES

### Phase 1: Clarification (Ask)
Check overall context ambiguity by default -> IF ambiguous != FALSE -> List(Questions) -> Wait(User_Input)

### Phase 2: Planning (Think)
Plan: Analyze command requirements -> Identify dependencies -> Generate template -> Validate

### Phase 3: Execution (Do)
Generate command following schema -> Validate references -> Test execution

### Phase 4: Validation (Check)
Final_Checklist: Schema valid? Dependencies exist? Security checks present?

**CRITICAL VARIABLE USAGE RULES**

**$ARGUMENTS Variable**:
- **Purpose**: Capture user input when command is invoked
- **MUST Appear ONLY**: In the User Input section (`**Input**: $ARGUMENTS`)
- **Forbidden Patterns**:
  - NEVER use $ARGUMENTS in ANY phase (Phase 1, 2, 3, or 4)
  - NEVER assign intermediate values to $ARGUMENTS
  - NEVER reference $ARGUMENTS in execution steps
  - NEVER use $ARGUMENTS for conditions or validation

**Referencing User Input**:
- To refer to user-provided data, use natural language references to "the user input section" or "provided context"
- Example: "Incorporate provided context if available" (correct)
- Example: "Use the date from user input" (correct)
- Example: `IF $ARGUMENTS.ambiguous != FALSE` (WRONG - uses $ARGUMENTS)

**Bash Variable Usage** (TODAY, PRS, etc.):
- These ARE NOT $ARGUMENTS
- These capture command outputs for later processing
- Example: `TODAY=date +%Y-%m-%d`, `PRS=gh pr list ...` (correct - these are command outputs)

**Violations Check**:
- User Input section: MUST contain `**Input**: $ARGUMENTS`
- All phases: MUST NOT contain $ARGUMENTS anywhere
- Execution steps: MUST reference user input naturally, not via $ARGUMENTS

## CONTEXT

**Dependencies**: Bash (shell), YAML (frontmatter), Markdown

**Threat Model**:
- Input -> Sanitize(shell_escapes) -> Validate(Safe) -> Execute
- Command injection via arguments -> Strip dangerous chars
- Destructive_Op -> Require User_Confirm

**Validation Layers (Apply in Order)**:
1. Input: Type check, schema validate, sanitize
2. Context: Verify permissions, check dependencies
3. Execution: Confirm intent, check for destructiveness
4. Output: Verify format, redact secrets

## CORE FUNCTION
- **Goal**: Encapsulate workflows -> Simple `/command` invocation
- **Scope**: Reusable templates, multi-step processes, ecosystem integration

## OPERATIONAL PROCESS
### 1. Scan & Analyze
- **Action**: `list(~/.config/opencode/)` -> Identify(Skills, Agents, Tools)
- **Logic**: Workflow_Reqs + Available_Components -> Command_Plan

### 2. Template Generation
- **Format**: Markdown with YAML frontmatter
- **Input**: User Input section with Default and Input subsections == MANDATORY
- **Constraint**: Input subsection MUST contain `$ARGUMENTS` placeholder for command parser
- **Ref**: Use exact names (`skill(skill_id)`, `@agent/name`)

### 3. Validation
- **Check**: Ref_Exists? && Tool_Perms? && Name_Unique?
- **Rule**: Never reference non-existent components

## SYNTAX & STRUCTURE
```markdown
---
description: >-
  [Multi-line description for context]
  [Use >- for continuation]
agent: [Optional: @agent/name]
---

## User Input

**Default**: [Default behavior when no arguments provided]

**Input**: $ARGUMENTS

1. Step_1: Action
2. Step_2: Verify(Result)
3. Step_3: Error_Handle -> Fallback
```

**User Input Section (MANDATORY)**: All commands MUST include a User Input section
- **Default**: Document behavior when no arguments provided
- **Input**: MUST contain `$ARGUMENTS` placeholder for command parser substitution
- Do NOT reference $ARGUMENTS inline in execution steps
- Reference user intent naturally in execution (e.g., "Incorporate provided context if available")

## INLINE COMMAND EXECUTION
- **Syntax**: `!`command` for shell output in command context
- **Usage**: Embed context from git, environment, file operations
- **Preference**: Use inline execution where feasible (save tokens, direct calls)
- **When to use**:
  - Static data retrieval (dates, branches, file existence)
  - Environment variable checks
  - Git status/info
  - Simple conditionals returning strings
  - Non-destructive commands

### Error Handling (MANDATORY)
- **Handle inline**: All error handling within command itself
- **Simple**: `command 2>/dev/null || fallback` (preferred, no `command -v` needed)
- **Conditional**: `command -v tool && tool command` (only when pre-check needed)
- **Operators**: `||` for fallbacks, `&&` for chains
- **Defaults**: `${VAR:-default}` for missing variables
- **Suppress**: `2>/dev/null` to hide errors
- **PROHIBITED**: `2>&1` redirect causes parser errors (use `2>/dev/null`)

### Examples
- Environment: `IS_WORK=!`echo ${IS_WORK:-0}`
- Date/time: `TODAY=!`date +%Y-%m-%d`
- Git status: `STATUS=!`git status --porcelain || echo "clean"`
- Branch name: `BRANCH=!`command -v git && git rev-parse --abbrev-ref HEAD || echo "not-in-git"`
- File checks: `EXIST=!`test -f .env && echo "exists" || echo "not found"`
- Command results: `PRS=!`gh pr list --state merged --json title | jq '.[] | .title' 2>/dev/null || echo "none"`

## ERROR HANDLING PATTERNS

```markdown
# Pattern 1: Simple error handling (no pre-check needed)
1. PRS=!`gh pr list --state merged --search "merged:$(date +%Y-%m-%d)" --json title,body 2>/dev/null || echo "none"`
2. IF $PRS == "none" -> Report(No merged PRs today)

# Pattern 2: Check and execute inline (when pre-check needed)
1. BRANCH=!`command -v git && git rev-parse --abbrev-ref HEAD || echo "no-git"`
2. IF $BRANCH == "no-git" -> Error(Git not installed) -> EXIT

# Pattern 3: Validate with fallback
1. RESULT=!`cat data.json | jq '.key' 2>/dev/null || echo "default"`
2. IF $RESULT == "default" -> Warning(Using default value)

# Pattern 4: Continue on non-critical failure
1. OPTS=!`test -f .options && cat .options || echo ""`
2. IF empty($OPTS) -> Set(DEFAULT_OPTS)

# Pattern 5: External CLI with auth check
1. PRS=!`gh pr list --state merged --search "merged:$(date +%Y-%m-%d)" --json title,body 2>/dev/null || echo "none"`
2. IF $PRS == "none" -> Report(No merged PRs or auth failed) -> EXIT
```

## COMPLEX COMMANDS
- **Issue**: Commands with pipes (`|`), subshells `()`, complex conditionals, multiple redirections (`2>/dev/null`) may fail during interpolation
- **Solution**: Wrap complex commands in `sh -c '...'` to ensure proper shell parsing
- **When to use**:
  - Pipes: `command1 | command2`
  - Subshells: `(command1 && command2) || command3`
  - Multiple redirections: `command 2>&1 | command`
  - Complex conditionals with nested operations

### Complex Command Examples

```markdown
# Simple command (no sh -c needed)
BRANCH=!`git rev-parse --abbrev-ref HEAD`

# Complex command with pipe and redirection (sh -c required)
RESULT=!`sh -c 'git diff --staged | grep -Ei "password|secret|key|token|api_key" 2>/dev/null || echo "safe"'`

# Complex command with subshell (sh -c required)
DEFAULT=!`sh -c 'git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed "s|^origin/||" || { git rev-parse --verify main >/dev/null 2>/dev/null && echo main; } || echo master'`

# Multiple pipes and operators (sh -c required)
DATA=!`sh -c 'cat file.json | jq -r ".items[].value" 2>/dev/null | head -5 || echo "none"'`
```

## SECURITY & VALIDATION (MANDATORY)
- **Prohibition**: Hardcoded credentials == FORBIDDEN
- **Input Sanitization**: $ARGUMENTS -> Strip dangerous chars -> Validate schema
- **Destructive Ops**: `rm`, `sudo`, `git push -f`, `chmod` -> Require `User_Confirm`
- **Validation Pipeline**:
  1. Parse $ARGUMENTS
  2. Sanitize (remove shell escapes)
  3. Validate schema/type
  4. Confirm if destructive
  5. Execute safely
- **Error Handling**: Never expose secrets in error messages

## EXAMPLES

### Basic Command

```markdown
---
description: >-
  Review code
agent: quality/code-reviewer
---

## User Input

**Default**: No file specified

**Input**: $ARGUMENTS

1. Check: FILE_CHECK=!`test -f "$ARGUMENTS" && echo "exists" || echo "missing"`
2. IF $FILE_CHECK == "missing" -> Error(File not found) -> EXIT
3. Analyze: Provided file
4. Report: Issues + Fixes
```

### Complex Command

```markdown
---
description: >-
  Deploy feature with comprehensive validation
  Requires testing and git workflow integration
---

## User Input

**Default**: Deploy current branch

**Input**: $ARGUMENTS

1. Environment: IS_WORK=!`echo ${IS_WORK:-0}`
2. Current branch: BRANCH=!`git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "no-git"`
3. IF $BRANCH == "no-git" -> Error(Git not installed) -> EXIT
4. IF $BRANCH == "main" -> Error(Not allowed on main) -> EXIT
5. Validate(provided deployment target)
6. IF success -> Execute(deployment) -> ELSE Report(Error)
7. skill(git-workflow)
8. Merge_Request
```

### Command with Routing

```markdown
---
description: >-
  Analyze git status and route to appropriate action
  Uses inline commands for context
---

## User Input

**Default**: Auto-generate commit message

**Input**: $ARGUMENTS

## Execution

1. Git status: STATUS=!`git status --porcelain 2>/dev/null || echo "not-in-git"`
2. IF $STATUS == "not-in-git" -> Error(Git not installed) -> EXIT
3. Branch: BRANCH=!`git rev-parse --abbrev-ref HEAD`
4. Staged: STAGED=!`git diff --cached --name-only 2>/dev/null || echo ""`
5. IF empty($STAGED) -> Exit(No changes to commit)
6. IF conflicts -> Read(@references/merge-conflicts.md) -> Resolve
7. skill(git-workflow)
```

### External CLI Integration

```markdown
---
description: >-
  Fetch and summarise GitHub pull requests merged today
  Uses gh CLI with inline error handling
---

1. Date: TODAY=!`date +%Y-%m-%d`
2. PRs: PRS=!`gh pr list --state merged --search "merged:$(date +%Y-%m-%d)" --json title,body 2>/dev/null || echo "none"`
3. IF $PRS == "none" -> Report(No merged PRs today) -> EXIT
4. Transform: Each PR -> Business-friendly summary
5. Output: Bullet list with emojis
```


## BEST PRACTICES

### When to use `command -v`:
- Check existence BEFORE execution for conditional logic
- Execute multiple commands dependent on tool availability

### When NOT to use `command -v`:
- Simple command execution with error fallback
- Single commands where error handling covers missing tool + execution failure

```markdown
❌ Over-engineered:
PRS=!`command -v gh && gh pr list --state merged 2>/dev/null || echo "none"`

✓ Simpler:
PRS=!`gh pr list --state merged 2>/dev/null || echo "none"`
```

```markdown
✓ Necessary (conditional logic):
HAS_GIT=!`command -v git && echo "yes" || echo "no"`
IF $HAS_GIT == "yes" -> Execute_Git_Ops ELSE Warn(Git not installed)
```
