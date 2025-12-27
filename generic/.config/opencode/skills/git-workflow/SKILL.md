---
name: git-workflow
description: Route ALL git operations to appropriate resources. Load reference files before responding. Covers status, diff, log, commits, branches, conflicts, rebasing, code review.
tools:
  read: true
  bash: ask
---

# Git Workflow Orchestrator

<rules>
## Phase 1: Clarification (Ask)
IF query.ambiguous != FALSE -> List(Missing_Info) -> Wait(User_Input)

## Phase 2: Planning (Think)
Propose(Route: ref OR cmd + tools + impacts). IF impact > Low -> Wait(User_Confirm)

## Phase 3: Execution (Do)
Execute(Route: READ @references/* -> Parse -> Format). Validate EACH step.

## Phase 4: Validation (Check)
Final_Checklist: Correct? Safe? Complete? IF Fail -> Self_Correct.
</rules>

<context>
**Dependencies**: git (CLI), gh (GitHub CLI - optional), Bash (ask)

**Threat Model**:
- Input -> Sanitize() -> Validate(Safe) -> Execute
- Destructive_Op (push, force, reset) -> User_Confirm == TRUE
- Rule: NEVER commit/push without EXPLICIT user permission
</context>

## Routing Logic

```
IF intent in ["status", "diff", "log", "changes", "info", "url"]:
  -> READ @references/changes-info.md
  -> Execute(cmd) -> Format(MD)
  
ELSE IF intent in ["commit", "message", "conventional"]:
  -> READ @references/commit-message.md
  -> Generate(message) -> Show(code_block)
  
ELSE IF intent in ["branch", "strategy", "naming"]:
  -> READ @references/branch-strategies.md
  -> Recommend -> Explain(precision)
  
ELSE IF intent in ["conflict", "merge", "resolve"]:
  -> READ @references/merge-conflicts.md
  -> Guide(resolution) -> User_Confirm(ALL changes)
  
ELSE IF intent in ["rebase", "rewrite", "squash"]:
  -> READ @references/rebase-guidelines.md
  -> Guide(workflow) -> User_Confirm(ALL changes)
  
ELSE:
  -> Execute(git cmd) -> Format(MD/bullets)
```

## Operational Standards

1. **Load References**: READ @references/* before responding
2. **Progressive Disclosure**: Main < 500 lines, Details -> @references/
3. **Format Output**: MD diffs, bullets logs, KV metadata
4. **Error Handling**: Suggest auth, fallback git, summarize large
5. **Security**: Destructive ops -> User_Confirm (Y/N required)

## Execution Examples

<example>
User: "What's the status?"
Plan: READ @references/changes-info.md -> git status -> format
Result: Clean bullet list of changes
</example>

<example>
User: "Generate commit message"
Plan: READ @references/commit-message.md -> git diff --staged -> generate
Result: Code block with conventional commit
</example>

<example>
User: "Help with merge conflict"
Plan: READ @references/merge-conflicts.md -> explain markers -> guide resolution -> confirm
Result: Step-by-step resolution with approval required
</example>
