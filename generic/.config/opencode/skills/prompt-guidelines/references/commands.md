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
- **Example**: `!git status --porcelain` for working directory status

## DECISION GUIDELINES
- **Git**: Ref `skills_git_workflow`.
- **Code**: Ref `@quality/code-reviewer`.
- **Docs**: Ref `tool(context7)`.
- **Complex**: Break into numbered steps.

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
1. Analyze: `$ARGUMENTS`.
2. Report: Issues + Fixes.
```

### Complex
```markdown
---
description: >-
  Deploy feature with comprehensive validation.
  Requires testing and git workflow integration.
---
1. Validate($ARGUMENTS).
2. IF success → Execute($ARGUMENTS) → ELSE Report(Error).
3. Branch(skills_git_workflow).
4. Merge_Request.
```

### With Commands & Routing
```markdown
---
description: >-
  Analyze git status and route to appropriate action.
  Uses inline commands for context.
---

1. Check status: !git status --porcelain
2. IF staged_changes → skills_git_workflow(Commit) → ELSE Exit
3. IF conflicts → Read(@references/merge-conflicts.md) → Resolve
```
