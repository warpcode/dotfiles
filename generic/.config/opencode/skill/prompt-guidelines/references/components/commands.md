# PROTOCOLS: COMMANDS

## CONTEXT

### Core Function
- **Goal**: Encapsulate workflows -> Simple `/command` invocation
- **Scope**: Reusable templates, multi-step processes, ecosystem integration

### Dependencies
- Bash (shell), YAML (frontmatter), Markdown

### Threat Model
- Input -> Sanitize(shell_escapes) -> Validate(Safe) -> Execute
- Command injection via arguments -> Strip dangerous chars
- Destructive_Op -> Require User_Confirm

### Validation Layers (Apply in Order)
1. Input: Type check, schema validate, sanitize
2. Context: Verify permissions, check dependencies
3. Execution: Confirm intent, check for destructiveness
4. Output: Verify format, redact secrets

## SYNTAX & STRUCTURE
```markdown
---
description: >-
  [One-line purpose]
  Scope: [areas covered]
  agent: [Optional: @agent/name]
---

## User Input

**Default**: [Default behavior when no arguments provided]

**Input**: $ARGUMENTS

1. Step_1: Action
2. Step_2: Verify(Result)
3. Step_3: Error_Handle -> Fallback
```

### User Input Section (MANDATORY)
All commands MUST include a User Input section:
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

## CRITICAL VARIABLE USAGE RULES

### $ARGUMENTS Variable
- **Purpose**: Capture user input when command is invoked
- **MUST Appear ONLY**: In the User Input section (`**Input**: $ARGUMENTS`)
- **Forbidden Patterns**:
  - NEVER use $ARGUMENTS in ANY phase (Phase 1, 2, 3, or 4)
  - NEVER assign intermediate values to $ARGUMENTS
  - NEVER reference $ARGUMENTS in execution steps
  - NEVER use $ARGUMENTS for conditions or validation

### Referencing User Input
- To refer to user-provided data, use natural language references to "the user input section" or "provided context"
- Example: "Incorporate provided context if available" (correct)
- Example: "Use the date from user input" (correct)
- Example: `IF $ARGUMENTS.ambiguous != FALSE` (WRONG - uses $ARGUMENTS)

### Bash Variable Usage (TODAY, PRS, etc.)
- These ARE NOT $ARGUMENTS
- These capture command outputs for later processing
- Example: `TODAY=date +%Y-%m-%d`, `PRS=gh pr list ...` (correct - these are command outputs)

### Violations Check
- User Input section: MUST contain `**Input**: $ARGUMENTS`
- All phases: MUST NOT contain $ARGUMENTS anywhere
- Execution steps: MUST reference user input naturally, not via $ARGUMENTS
