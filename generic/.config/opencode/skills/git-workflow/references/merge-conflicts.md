# Merge Conflict Resolution

This file is loaded when Claude needs to help resolve merge conflicts.

## Understanding Conflict Markers

```
<<<<<<< HEAD (current change)
Your version of the code
=======
Their version of the code
>>>>>>> branch-name (incoming change)
```

- **HEAD**: Your current branch's version
- **=======**: Separator between versions
- **branch-name**: The branch you're merging in

## Resolution Strategy Framework

### 1. Analyze Conflict Type

**Line conflicts:** Same line modified differently → choose correct version  
**Logical conflicts:** Compatible syntax but conflicting logic → understand intent  
**Structural conflicts:** File renamed/moved vs modified → locate and apply changes  
**Deletion conflicts:** File deleted vs modified → preserve if needed

### 2. Resolution Approaches

**Accept ours:** `git checkout --ours <file> && git add <file>` - **ALWAYS ask for user approval**  
**Accept theirs:** `git checkout --theirs <file> && git add <file>` - **ALWAYS ask for user approval**  
**Manual merge:** Edit to combine both changes - **ALWAYS ask for user approval**  
**Rewrite:** Discard both, create better solution - **ALWAYS ask for user approval**

### 3. Common Conflict Patterns

**Import conflicts:** Combine and sort imports alphabetically  
**Config conflicts:** Merge all settings, prioritize newer values  
**Function conflicts:** Combine parameter changes and logic modifications  

*Example resolution strategy:* When both sides add value, combine changes rather than choosing one.

## Resolution Workflow

1. **Understand:** Read markers, check `git log --merge`, review `git diff`
2. **Decide:** Combine vs. choose one vs. rewrite - **ALWAYS ask for user approval**
3. **Edit:** Remove markers, ensure valid syntax
4. **Test:** Run tests, verify functionality
5. **Complete:** `git add <files> && git commit`

## Rebase Conflicts

**Key Differences from Merge Conflicts:**
- Conflicts are resolved per-commit, not once
- Use `git rebase --skip` to skip empty commits
- Continue until all commits are replayed

**Resolution Process:**
1. Resolve conflicts in current commit - **ALWAYS ask for user approval before resolving**
2. `git add <resolved-files>`
3. `git rebase --continue`
4. Repeat for each conflicting commit
5. Use `git rebase --abort` to cancel entire rebase

## Prevention Strategies

**Short-lived branches:** Merge frequently, smaller changes  
**Communication:** Coordinate work on shared files  
**Feature flags:** Merge incomplete work behind flags

## Abort Options

**During merge:** `git merge --abort`  
**Partial resolution:** `git reset --hard HEAD`

## Advanced: 3-Way Merge Tool

```bash
git mergetool
```

Shows **LOCAL** (yours), **BASE** (common ancestor), **REMOTE** (theirs) to understand changes.

## When to Ask for Help

- Code you don't understand
- Large-scale structural conflicts  
- Generated files (consider regenerating)
- Critical system conflicts
- Unsure which version is correct

**Always:** Test after resolving - conflicts can hide bugs.  
**IMPORTANT:** ALWAYS ask for user approval before resolving any merge conflicts.

## Related Operations

**For rebase-specific operations and prevention:**
- See @references/rebase-guidelines.md for rebase workflows and safety
- Rebase conflicts require per-commit resolution (see above)
- Use rebase to prevent conflicts by staying up-to-date with main
