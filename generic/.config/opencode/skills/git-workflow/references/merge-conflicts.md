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

### 1. Analyze the Conflict Type

**Type A: Simple Line Changes**
- Both sides modified the same line differently
- Usually clear which version to keep

**Type B: Logical Conflicts**
- Changes are compatible syntactically but conflict logically
- Requires understanding both changes' intent

**Type C: Structural Conflicts**
- One side renamed/moved, other side modified
- Need to find the file and apply changes

**Type D: Deletion Conflicts**
- One side deleted, other side modified
- Decide if modification should be preserved elsewhere

### 2. Resolution Approaches

**Accept Ours:**
```bash
git checkout --ours <file>
git add <file>
```
Keep your version, discard theirs.

**Accept Theirs:**
```bash
git checkout --theirs 
git add 
```
Keep their version, discard yours.

**Manual Merge:**
Edit file to combine both changes appropriately.

**Rewrite:**
Discard both and write a better solution.

### 3. Common Conflict Patterns

**Pattern: Import Statement Conflicts**
```python
<<<<<<< HEAD
import os
import sys
=======
import sys
import json
>>>>>>> feature
```

**Resolution:** Combine and sort alphabetically
```python
import json
import os
import sys
```

**Pattern: Configuration Conflicts**
```json
<<<<<<< HEAD
{
  "timeout": 3000,
  "retries": 3
}
=======
{
  "timeout": 5000,
  "maxConnections": 10
}
>>>>>>> feature
```

**Resolution:** Merge all settings
```json
{
  "timeout": 5000,
  "retries": 3,
  "maxConnections": 10
}
```

**Pattern: Function Modification Conflicts**
```javascript
<<<<<<< HEAD
function calculate(x, y) {
  return x + y + 10; // Added bonus
}
=======
function calculate(x, y, z) {
  return x + y + z; // Added third param
}
>>>>>>> feature
```

**Resolution:** Combine both changes
```javascript
function calculate(x, y, z = 0) {
  return x + y + z + 10; // Both changes applied
}
```

## Resolution Workflow

1. **Understand both changes**
   - Read the conflict markers
   - Check commit messages: `git log --merge`
   - See full diff: `git diff`

2. **Decide on approach**
   - Can you combine both changes?
   - Is one clearly correct?
   - Do you need to rewrite?

3. **Make the edit**
   - Remove conflict markers
   - Keep/combine/rewrite code
   - Ensure syntax is valid

4. **Test the resolution**
   - Run tests if available
   - Verify functionality
   - Check for logical errors

5. **Complete the merge**
   ```bash
   git add <resolved-files>
   git commit
   # Default merge message is usually fine
   ```

## Prevention Strategies

**Keep branches short-lived:**
- Merge frequently (daily if possible)
- Smaller changes = fewer conflicts

**Communicate:**
- Tell team when working on shared files
- Coordinate major refactors

**Rebase regularly:**
```bash
git fetch origin
git rebase origin/main
```
Stay up-to-date with main branch.

**Use feature flags:**
- Merge incomplete work behind flags
- Avoid long-lived feature branches

## Abort Options

**During merge:**
```bash
git merge --abort
```

**During rebase:**
```bash
git rebase --abort
```

**After partial resolution:**
```bash
git reset --hard HEAD
```

## Advanced: 3-Way Merge Tool

```bash
git mergetool
```

Shows three panes:
- **LOCAL**: Your version (HEAD)
- **BASE**: Common ancestor
- **REMOTE**: Their version (incoming)

Helps understand what each side changed from the original.

## When to Ask for Help

- Conflicts in code you don't understand
- Large-scale structural conflicts
- Conflicts in generated files (consider regenerating)
- Conflicts affecting critical systems
- When unsure which version is correct

**Always:** Test after resolving. Conflicts can hide bugs.
