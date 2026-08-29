# Merge Conflict Resolution

Reference for detecting, resolving, and recovering from merge conflicts during
`git merge` and `git rebase`. Read this file when the user encounters conflict
markers (`<<<<<<<`, `=======`, `>>>>>>>`) in file contents or reports that a
merge or rebase cannot proceed.

## Detecting Conflicts

For a one-shot report detecting in-progress merges, rebases, cherry-picks, reverts, bisects, conflict files, and recovery commands:
```bash
bash @scripts/merge_state.sh
```

| Signal | Command | Meaning |
|--------|---------|---------|
| In-progress state & conflict triage | `bash @scripts/merge_state.sh` | Detects operation, conflicting files, abort/continue commands |
| Merge conflict status | `git status` | Lists files with `both modified` / `unmerged` state |
| Conflict markers | `git diff` / `git diff <file>` | Shows `<<<<<<<` `=======` `>>>>>>>` blocks |
| List unmerged paths | `git diff --name-only --diff-filter=U` | Filenames only |

## Conflict Marker Anatomy

```
<<<<<<< HEAD (current branch)
Your version
=======
Their version
>>>>>>> branch-name (incoming)
```

- `<<<<<<<` to `=======` → **ours** (current/local)
- `=======` to `>>>>>>>` → **theirs** (incoming)
- The branch name in `>>>>>>>` identifies the incoming side

## Resolution Strategies

| Approach | Command | Use when | Confirm? |
|----------|---------|----------|----------|
| Accept ours | `git checkout --ours <file> && git add <file>` | Your version is correct | Yes |
| Accept theirs | `git checkout --theirs <file> && git add <file>` | Their version is correct | Yes |
| Manual merge | Edit file to combine, `git add <file>` | Need parts of both | Yes |
| Rewrite | Edit file with a better solution, `git add <file>` | Neither side is what you want | Yes |
| Visual merge | `git mergetool <file>` | Prefer a GUI diff tool | Yes |

> **Always confirm with the user** before accepting either side wholesale.

## Aborting the Conflict

| Context | Abort command |
|--------|---------------|
| During `git merge` | `git merge --abort` |
| During `git rebase` | `git rebase --abort` |
| After editing some files but not committing | `git reset --hard` (DESTRUCTIVE — warn) |

## Merge vs. Rebase Conflicts

| Context | Symptom | Abort | Continue |
|---------|---------|-------|----------|
| `git merge` | Files have conflict markers | `git merge --abort` | Resolve all files, `git add`, then `git commit` |
| `git rebase` | Files have conflict markers per-step | `git rebase --abort` | Resolve each file, `git add`, then `git rebase --continue` |

During a rebase, conflicts are resolved in multiple steps (one per commit being
replayed). Resolve, `git add`, then `git rebase --continue` until complete.

## Recovery Recipes

Any commit reachable in the last ~90 days can be recovered via the reflog. This also covers accidentally aborted
merges or rebases.

```bash
git reflog                          # find the pre-conflict HEAD
git checkout <sha>                  # inspect
git branch recovery-branch <sha>    # restore as a branch
```

## Prevention Tips

- Keep branches short-lived; longer-running branches diverge and conflict more.
- Rebase feature branches onto `main` frequently to surface conflicts early.
- Communicate with teammates before pushing to shared branches — concurrent
  edits to the same files are the most common source of conflicts.

## Hard Constraints

- Never auto-resolve a conflict without user confirmation.
- Never skip `git add` on a resolved file during a rebase — a missing stage
  causes `git rebase --continue` to fail.
- Prefer `git merge --abort` / `git rebase --abort` when the user wants to
  discard the entire operation.
