# Merge Conflict Resolution

## Rules

### Phase 1: Clarification
IF conflict_type.ambiguous -> Ask(user: describe conflict) -> Wait(User_Input)

### Phase 2: Planning
Analyze(markers + log + diff) -> Propose(Resolution) -> **ALWAYS** Wait(User_Confirm)

### Phase 3: Execution
Resolve(edit/accept) -> Test -> Commit

### Phase 4: Validation
Syntax valid? Tests pass? IF Fail -> Debug/Retry

## Context

**Dependencies**: git (CLI), tests (project-specific)

**Threat Model**:
- Input -> Sanitize(shell_escapes) -> Validate(file_paths) -> Execute
- **CRITICAL**: User_Confirm == TRUE for ALL resolution operations

## Conflict Markers

```
<<<<<<< HEAD (current)
Your version
=======
Their version
>>>>>>> branch-name (incoming)
```

## Resolution Matrix

| Approach | Command | Use Case | Confirm? |
|----------|---------|----------|----------|
| Accept ours | `git checkout --ours <file> && git add <file>` | Your version correct | Y |
| Accept theirs | `git checkout --theirs <file> && git add <file>` | Their version correct | Y |
| Manual merge | Edit file, `git add <file>` | Combine both | Y |
| Rewrite | Edit file, `git add <file>` | Better solution | Y |

## Conflict Types

| Type | Pattern | Resolution |
|------|---------|------------|
| Line | Same line modified | Choose correct version |
| Logical | Syntax OK, logic conflicts | Understand intent, combine |
| Structural | Renamed vs modified | Locate, apply changes |
| Deletion | Deleted vs modified | Preserve if needed |

## Common Patterns

```
# Import conflicts
Combine + Sort alphabetically

# Config conflicts  
Merge all settings, prioritize newer

# Function conflicts
Combine parameter changes + logic
```

## Workflow

```
1. Understand
   -> Read markers
   -> Check: git log --merge
   -> Review: git diff
   
2. Decide
   -> Combine OR choose OR rewrite
   -> **ALWAYS** Wait(User_Confirm)
   
3. Edit
   -> Remove markers
   -> Ensure valid syntax
   
4. Test
   -> Run tests
   -> Verify functionality
   
5. Complete
   -> git add <files>
   -> git commit
```

## Rebase Conflicts

**Difference**: Per-commit resolution (not once)

```
FOR each conflicting commit:
  1. Resolve - **ALWAYS** Wait(User_Confirm)
  2. git add <resolved-files>
  3. git rebase --continue
  
Abort: git rebase --abort
```

## Abort Options

| Scenario | Command |
|----------|---------|
| During merge | `git merge --abort` |
| Partial resolution | `git reset --hard HEAD` |
| Rebase cancel | `git rebase --abort` |

## Prevention Strategies

- **Short-lived branches**: Merge frequently
- **Communication**: Coordinate shared files
- **Feature flags**: Merge incomplete work behind flags

## 3-Way Merge Tool

```bash
git mergetool
```

Shows: **LOCAL** (yours), **BASE** (ancestor), **REMOTE** (theirs)

## Decision Guide

| Situation | Ask Help? |
|-----------|-----------|
| Code you don't understand | Y |
| Large structural conflicts | Y |
| Generated files | Y (regenerate?) |
| Critical system conflicts | Y |
| Unsure which version | Y |

## Related Operations

- @references/rebase-guidelines.md for rebase workflows
- Common patterns + prevention strategies

## Examples

### Example 1: Import Conflict
Conflict: Import order
Analysis: Both added same import
Resolution: Combine, sort alphabetically

### Example 2: Function Signature Conflict
Conflict: Function signature
Analysis: Parameter types differ
Resolution: Understand intent, combine parameters

### Example 3: Deleted File Conflict
Conflict: Deleted file
Analysis: Branch A deleted, Branch B modified
Resolution: Preserve if needed, ask user
