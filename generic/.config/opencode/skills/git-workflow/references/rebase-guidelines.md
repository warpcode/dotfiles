# Rebase Guidelines

This file is loaded when Claude needs to advise on rebasing operations.

## What is Rebasing?

Rebasing rewrites commit history by replaying commits on a new base.

**Before:** `A---B---E---F main` + `C---D feature`  
**After rebase:** `A---B---E---F---C'---D' feature`

Commits C and D are replayed on top of F.

## When to Rebase

**✅ DO rebase when:**
- Updating feature branch with main's changes
- Cleaning up local commits before pushing
- Squashing work-in-progress commits
- Removing sensitive data (with care)
- Making commit history linear and clean

**❌ DON'T rebase when:**
- Branch is already pushed and shared
- Working on public/main branches
- Commits are already in production
- You're unsure about the changes
- During an active merge

**Golden Rule:** Never rebase commits that exist outside your repository.

## Common Rebase Operations

### Update Feature Branch

```bash
git fetch origin && git rebase origin/main
```

**Conflicts:** `git add . && git rebase --continue` - **ALWAYS ask for user approval before resolving conflicts**  
**Abort:** `git rebase --abort`

### Interactive Rebase (Clean History)

```bash
git rebase -i HEAD~5  # Edit last 5 commits
```

**Commands:** `pick` (keep), `reword` (msg), `edit` (amend), `squash`/`fixup` (combine), `drop` (remove)

**Example cleanup:**
```
pick a1b2c3d Add feature X
fixup e4f5g6h Fix typo          # Combine with previous
drop i7j8k9l WIP: debugging      # Remove
fixup m0n1o2p Fix feature X      # Combine
pick q3r4s5t Update docs
```
Result: 2 clean commits instead of 5.

### Squash All Commits

```bash
git rebase -i $(git merge-base HEAD main)  # Squash all since main branch
```

### Change Old Commit

```bash
git rebase -i HEAD~5  # Mark commit as 'edit'
git add . && git commit --amend  # Make changes
git rebase --continue
```

## Rebase vs Merge

| Aspect | Merge | Rebase |
|--------|-------|--------|
| History | Preserves exact timeline | Linear, clean |
| Context | Shows integration points | Loses merge context |
| Use case | Public/shared branches | Personal feature cleanup |
| Result | `A---B---E---F---G` (with merge) | `A---B---E---F---C'---D'` |

**Choose Merge:** Public branches, team collaboration  
**Choose Rebase:** Personal branches, linear history preferred

## Rebase Workflow

### Common Workflows

**Daily Update:**
```bash
git fetch origin && git rebase origin/main
```

**Before PR:**
```bash
git log --oneline  # Review
git rebase -i origin/main  # Clean up
git push --force-with-lease
```

## Safety Tips

**Abort:** `git rebase --abort`  
**Force push:** `git push --force-with-lease` (safer than --force)  
**Backup:** `git branch backup && git rebase -i HEAD~10`  
**Check commits:** `git log origin/main..HEAD`  
**Recover:** `git reflog` → `git reset --hard HEAD@{5}`

## Common Issues

**Repeated conflicts:** Too many commits → use merge or smaller chunks  
**Lost commits:** `git reflog` → `git cherry-pick <commit>`  
**Accidental shared branch rebase:** Team must `git reset --hard origin/branch`  
**Conflict resolution:** ALWAYS ask for user approval before resolving any conflicts



## Advanced: Autosquash

```bash
# Make fixup commit
git commit --fixup 

# Later, autosquash
git rebase -i --autosquash origin/main
```

Automatically marks fixup commits for squashing.

## Decision Matrix

| Scenario | Use Rebase | Use Merge |
|----------|------------|-----------|
| Update feature from main | ✅ | ❌ |
| Integrate feature to main | ❌ | ✅ |
| Clean local commits | ✅ | ❌ |
| Shared branch | ❌ | ✅ |
| Public history | ❌ | ✅ |
| Private branch | ✅ | Either |

## Related Operations

**For general conflict resolution patterns:**
- See @references/merge-conflicts.md for detailed conflict resolution strategies
- Common conflict patterns and resolution approaches
- Prevention strategies for avoiding conflicts

## Remember

- Rebase rewrites history - never rebase published commits
- Always test after rebasing
- Use `--force-with-lease` for force pushes
- When in doubt, merge instead
