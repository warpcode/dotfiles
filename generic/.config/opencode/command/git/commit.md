---
description: >-
  Interactive git commit assistant.
  Analyzes staged changes, performs security scans, and generates conventional commit messages via git-workflow skill.
---

<rules>
## Phase 1: Clarification (Ask)
IF $ARGUMENTS.ambiguous != FALSE -> List(Questions) -> Wait(User_Input)

## Phase 2: Planning (Think)
Plan: Verify staged changes -> Security scan -> Load git-workflow -> Generate message -> Request approval -> Execute

## Phase 3: Execution (Do)
Execute atomic steps. Validate result after EACH step.

## Phase 4: Validation (Check)
Final_Checklist: Commit message format? User approved? Success?
</rules>

<context>
**Dependencies**: git (CLI), skill(git-workflow), Bash (git commands)

**Threat Model**:
- Input -> Sanitize(shell_escapes) -> Validate(Safe) -> Execute
- Destructive_Op(commit) -> User_Confirm == TRUE
- Secret_Scan: Check for password/secret/key/token/api_key patterns

**Reference**: Load git-workflow skill -> Read @references/commit-message.md
</context>

<user>
    <default>
        Auto-generate from staged changes
    </default>
    <input>
        $ARGUMENTS
    </input>
</user>

<execution>
**CRITICAL**: Execute steps 1-4 IN ORDER. IF step 2 OR step 4 triggers termination -> STOP IMMEDIATELY. NO git commands, NO skill loads, NO continuation beyond step 4.

**Step 1**: STAGED=!`git status --short | grep '^[MADRC]' || echo "none"`

**Step 2**: IF $STAGED == "none" -> Report(No staged changes. Stage using `git add`) -> TERMINATE

**Step 3**: SECRETS=!`sh -c 'git diff --staged | grep -Ei "password|secret|key|token|api_key" 2>/dev/null || echo "safe"'`

**Step 4**: IF $SECRETS != "safe" -> Warning(Sensitive data detected. Commit aborted) -> TERMINATE

**Step 5**: Context_Gather:
  - BRANCH=!`git branch --show-current`
  - DEFAULT=!`sh -c 'git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed "s|^origin/||" || { git rev-parse --verify main >/dev/null 2>/dev/null && echo main; } || echo master'`
  - CHANGES=!`git diff --staged --stat`
  - DIFF=!`git diff --staged`
  - HISTORY=!`git log --oneline -5 --graph`

**Step 6**: skill(git-workflow)

**Step 7**: Analyze:
  - Review $DIFF + $HISTORY
  - Apply git-workflow conventions -> Draft commit message
  - Incorporate custom context if provided

**Step 8**: Display drafted message -> Request User_Confirm

**Step 9**: IF approved -> Execute `git commit -m "approved_message"` -> Report success
        ELSE -> Request feedback -> Refine -> Return to Step 8

**Step 10**: IF commit fails -> Report error -> STOP
</execution>

<examples>
<example>
User: /commit
STAGED=M  generic/.config/opencode/command/git/commit.md
SECRETS=safe
Result: Generates commit message -> Displays to user -> Waits approval
</example>

<example>
User: /commit "fix login bug"
STAGED=M  src/auth/login.py
SECRETS=safe
Result: Generates "fix(auth): resolve login timeout" -> Displays -> Waits approval
</example>
</examples>
