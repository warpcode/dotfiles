# Rebase Guidelines

## Rules

### Phase 1: Clarification
IF rebase_target.ambiguous -> Ask(user: branch, commits) -> Wait(User_Input)

### Phase 2: Planning
Verify(shared? == FALSE) -> Propose(rebase_type) -> **ALWAYS** Wait(User_Confirm)

### Phase 3: Execution
Execute(rebase) -> Resolve(conflicts?) -> Test -> Push(force-with-lease)

### Phase 4: Validation
History linear? Tests pass? IF Fail -> Abort/Retry

## Context

**Dependencies**: git (CLI), tests (project-specific)

**Threat Model**:
- Input -> Sanitize(shell_escapes) -> Validate(branch_local) -> Execute
- **CRITICAL**: Never rebase shared/public branches
- **CRITICAL**: User_Confirm == TRUE before rebase

## What is Rebasing?

**Concept**: Replay commits on new base (rewrites history)

```
Before: A---B---E---F main
              C---D feature
              
After:  A---B---E---F---C'---D' feature
              (replayed)
```

## When to Rebase

| ✅ DO | ❌ DON'T |
|-------|----------|
| Update feature with main | Already pushed/shared |
| Clean local commits | Public/main branches |
| Squash WIP commits | In production |
| Remove sensitive data | Unsure about changes |
| Linear history | Active merge |

**Golden Rule**: Never rebase commits outside your repository

## Common Operations

### Update Feature Branch

```bash
git fetch origin && git rebase origin/main
```

Conflicts: `git add . && git rebase --continue` (**ALWAYS** ask user)
Abort: `git rebase --abort`

### Interactive Rebase (Clean History)

```bash
git rebase -i HEAD~5  # Edit last 5
```

**Commands**:
- `pick` - Keep commit
- `reword` - Edit message
- `edit` - Amend changes
- `squash` - Merge into previous
- `fixup` - Merge (discard message)
- `drop` - Remove

**Example**:
```
pick a1b2c3d Add feature X
fixup e4f5g6h Fix typo          # Combine
drop i7j8k9l WIP: debugging      # Remove
fixup m0n1o2p Fix feature X     # Combine
pick q3r4s5t Update docs
```
Result: 2 clean commits

### Squash All Commits

```bash
git rebase -i $(git merge-base HEAD main)
```

### Change Old Commit

```bash
git rebase -i HEAD~5          # Mark 'edit'
git add . && git commit --amend  # Amend
git rebase --continue         # Continue
```

## Rebase vs Merge

| Aspect | Merge | Rebase |
|--------|-------|--------|
| History | Preserves timeline | Linear/clean |
| Context | Shows merge points | Loses context |
| Use case | Public/shared | Personal/cleanup |
| Result | `A---B---G` (merge) | `A---B---C'---D'` |

**Rule**: Merge (public), Rebase (private)

## Workflows

### Daily Update

```bash
git fetch origin && git rebase origin/main
```

### Before PR

```bash
git log --oneline                      # Review
git rebase -i origin/main              # Clean
git push --force-with-lease            # Push
```

### Autosquash

```bash
# Make fixup commit
git commit --fixup <commit>

# Later, autosquash
git rebase -i --autosquash origin/main
```

## Safety Tips

| Action | Command |
|--------|---------|
| Abort | `git rebase --abort` |
| Force push | `git push --force-with-lease` |
| Backup | `git branch backup && git rebase -i HEAD~10` |
| Check commits | `git log origin/main..HEAD` |
| Recover | `git reflog -> git reset --hard HEAD@{5}` |

## Decision Matrix

| Scenario | Rebase | Merge |
|----------|--------|-------|
| Update feature from main | ✅ | ❌ |
| Integrate feature to main | ❌ | ✅ |
| Clean local commits | ✅ | ❌ |
| Shared branch | ❌ | ✅ |
| Public history | ❌ | ✅ |
| Private branch | ✅ | Either |

## Common Issues

| Issue | Solution |
|-------|----------|
| Repeated conflicts | Use merge OR smaller chunks |
| Lost commits | `git reflog -> git cherry-pick` |
| Accidental shared rebase | Team: `git reset --hard origin/branch` |
| Conflict resolution | **ALWAYS** ask user before resolving |

## Related Operations

- @references/merge-conflicts.md for conflict resolution
- Prevention strategies + common patterns

## Examples

### Example 1: Update Feature Branch
Task: Update feature branch
Plan: git fetch && rebase origin/main
Execute: Fetch, rebase, resolve conflicts (ask user)
Result: Feature rebased on latest main

### Example 2: Clean Up WIP Commits
Task: Clean up WIP commits
Plan: git rebase -i HEAD~10, squash WIPs
Execute: Interactive rebase, squash fixups
Result: 3 clean commits instead of 10
