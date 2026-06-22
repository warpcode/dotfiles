---
type: command
description: >-
  Interactive git commit assistant
  Scope: staged changes, security scans, conventional commit messages via git-workflow skill
---

# Git Commit Assistant

## EXECUTION PROTOCOL

### Phase 1: Clarification
Check user input section for ambiguity -> List(Questions) -> Wait(User_Input)

### Phase 2: Planning
Plan: Verify staged changes -> Security scan -> Load git-workflow -> Generate message -> Request approval -> Execute

### Phase 3: Execution
Execute atomic steps. Validate result after EACH step.

### Phase 4: Validation
Final_Checklist: Commit message format? User approved? Success?

## DEPENDENCIES
- git (CLI)
- skill(git-workflow)
- Bash (git commands)

## THREAT MODEL
- Input -> Sanitize() -> Validate(Safe) -> Execute
- Destructive_Op(commit) -> User_Confirm == TRUE
- Secret_Scan: Check for password/secret/key/token/api_key patterns

## EXECUTION STEPS

**CRITICAL**: Execute steps 1-4 IN ORDER. IF step 2 OR step 4 triggers termination -> STOP IMMEDIATELY. NO git commands, NO skill loads, NO continuation beyond step 4.

**Step 1**: STAGED=!`git status --short | grep '^[MADRC]' || echo "none"`

**Step 2**: IF $STAGED == "none" -> Report(No staged changes. Stage using `git add`) -> TERMINATE

**Step 3**: SECRETS=!`sh -c 'git diff --staged | grep -Ei "password|secret|key|token|api_key" 2>/dev/null || echo "safe"'`

**Step 4**: IF $SECRETS != "safe" -> Warning(Sensitive data detected. Commit aborted) -> TERMINATE

**Step 5**:
- BRANCH=!`sh -c 'git branch --show-current 2>/dev/null | sed "s|^origin/||" || { git rev-parse --verify main >/dev/null 2>/dev/null && echo main; }'`
- DEFAULT=!`sh -c 'git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed "s|^origin/||" || { git rev-parse --verify main >/dev/null 2>/dev/null && echo main; }'`
- CHANGES=!`git diff --staged --stat`
- DIFF=!`git diff --staged`
- HISTORY=!`git log --oneline -5 --graph`

**Step 6**: skill(git-workflow) -> Generate conventional commit message

**Step 7**: Display drafted message -> Request User_Confirm

**Step 8**: IF approved -> Execute `git commit -m "approved_message"` -> Report success
         ELSE -> Request feedback -> Refine -> Return to Step 7

**Step 9**: IF commit fails -> Report error -> STOP

## EXAMPLES

### Example 1: /commit
User: /commit
STAGED=generic/.config/opencode/command/git/commit.md
SECRETS=safe
Result: Generates commit message -> Displays to user -> Waits approval

### Example 2: /commit "fix login bug"
User: /commit "fix login bug"
STAGED=src/auth/login.py
SECRETS=safe
Result: Generates "fix(auth): resolve login timeout" -> Displays -> Waits approval
