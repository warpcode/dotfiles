# Rebase Guidelines

This file is loaded when Claude needs to advise on rebasing operations.

## What is Rebasing?

Rebasing rewrites commit history by moving commits to a new base.

**Before rebase:**
```
      C---D  feature
     /
A---B---E---F  main
```

**After `git rebase main`:**
```
              C'---D'  feature
             /
A---B---E---F  main
```

Commits C and D are "replayed" on top of F.

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
# On feature branch
git fetch origin
git rebase origin/main
```

Replays your feature commits on top of latest main.

**When conflicts occur:**
1. Resolve conflicts in files
2. `git add <resolved-files>`
3. `git rebase --continue`
4. Repeat until complete

**To abort:**
```bash
git rebase --abort
```

### Interactive Rebase (Clean History)

```bash
git rebase -i HEAD~5
```

Opens editor with last 5 commits:
```
pick a1b2c3d Add feature X
pick e4f5g6h Fix typo
pick i7j8k9l WIP: debugging
pick m0n1o2p Fix feature X
pick q3r4s5t Update docs
```

**Commands:**
- `pick` - Keep commit as-is
- `reword` - Change commit message
- `edit` - Pause to amend commit
- `squash` - Combine with previous commit
- `fixup` - Like squash but discard message
- `drop` - Remove commit

**Example cleanup:**
```
pick a1b2c3d Add feature X
fixup e4f5g6h Fix typo
drop i7j8k9l WIP: debugging
fixup m0n1o2p Fix feature X
pick q3r4s5t Update docs
```

Results in 2 clean commits instead of 5.

### Squash All Commits

```bash
# Squash all commits since branching from main
git rebase -i $(git merge-base HEAD main)
```

Then use `squash` or `fixup` on all but the first commit.

### Change Old Commit

```bash
git rebase -i HEAD~5
# Change 'pick' to 'edit' for commit to modify
# Save and close

# Make your changes
git add 
git commit --amend

# Continue rebase
git rebase --continue
```

## Rebase vs Merge

**Merge:**
```
      C---D  feature
     /     \
A---B---E---F---G  main
```
- Preserves history
- Shows when feature was integrated
- Can be messy with many merges

**Rebase:**
```
A---B---E---F---C'---D'  main
```
- Linear history
- Cleaner to read
- Loses merge context

**Choose Merge when:**
- Working on public/shared branches
- Want to preserve exact history
- Multiple people working on branch

**Choose Rebase when:**
- Cleaning personal feature branch
- Want linear project history
- Updating feature with main changes

## Rebase Workflow

### Daily: Keep Feature Updated

```bash
# Start of day
git checkout feature
git fetch origin
git rebase origin/main

# If conflicts
# ... resolve conflicts
git add 
git rebase --continue

# Force push (only if branch not shared!)
git push --force-with-lease
```

### Before PR: Clean History

```bash
# Review commits
git log --oneline

# Interactive rebase
git rebase -i origin/main

# Squash WIP commits
# Reword unclear messages
# Drop debug commits

# Force push
git push --force-with-lease
```

## Safety Tips

**1. Use `--force-with-lease` not `--force`:**
```bash
git push --force-with-lease
```
Fails if someone else pushed, preventing overwrites.

**2. Create backup branch:**
```bash
git branch backup-feature
git rebase -i HEAD~10
# If disaster strikes: git reset --hard backup-feature
```

**3. Check what you're rebasing:**
```bash
git log origin/main..HEAD
```
Shows commits that will be rebased.

**4. Use reflog to recover:**
```bash
git reflog
git reset --hard HEAD@{5}  # Go back to previous state
```

## Common Issues

**Issue: Repeated conflicts on same file**
- You're rebasing too many commits at once
- Consider merge instead
- Or break rebase into smaller chunks

**Issue: Lost commits after rebase**
```bash
git reflog
git cherry-pick 
```

**Issue: Accidentally rebased shared branch**
- Communicate with team immediately
- Everyone must: `git reset --hard origin/branch`
- Then `git pull` to get correct history

**Issue: Merge conflicts during rebase**
- Same resolution as merge conflicts
- But resolved per commit, not once
- Use `git rebase --skip` to skip empty commits

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

## Remember

- Rebase rewrites history - it's powerful but dangerous
- Never rebase published commits
- Always test after rebasing
- Use `--force-with-lease` when force pushing
- Keep backups when learning
- When in doubt, merge instead
