# Git CLI Commands & Triage

Reference for git CLI syntax, error triage, and repository recovery recipes.
Read this file when the query involves command syntax, status/diff/log output,
or recovery from a broken state (detached HEAD, lost commits, merge conflicts,
botched rebase).

## Local State & History

| Category | Operation | Command | Format |
|----------|-----------|---------|--------|
| Local | Status | `git status` | Bullets |
| Local | Unstaged diff | `git diff` | MD diff |
| Local | Staged diff | `git diff --staged` | MD diff |
| Local | Unpushed commits | `git log --oneline origin/main..HEAD` | Bullets |
| Commits | History | `git log --oneline -10` | Bullets |
| Commits | Details | `git show <hash>` | MD + stat |
| Commits | Stat | `git show --stat <hash>` | Table |
| Branches | List | `git branch -a` | Bullets |
| Branches | Compare | `git diff <b1>..<b2>` | MD diff |
| Repo | Remotes | `git remote -v` | Table |

## Triage: Error Recovery Recipes

### Detached HEAD

Symptom: `HEAD detached at <oid>` — you're on a commit, not a branch.

| Situation | Command |
|-----------|---------|
| Inspect without committing | `git checkout main` (or current branch) |
| Discard changes made here | `git checkout main && git branch -D <tmp>` |
| Keep the work as a new branch | `git checkout -b <new-branch>` |

### Lost Commits (reflog recovery)

Any commit reachable in the last ~90 days can be recovered:

```bash
git reflog                 # find the commit/hash of the lost state
git checkout <sha>         # inspect
git branch <name> <sha>    # restore it as a branch
```

`git reflog` is the first resort for "I lost my commits". Never assume a hard
reset is irreversible — the reflog outlives it.

### Merge Conflicts

Detailed conflict resolution (markers, strategies, abort options) lives in
`merge-conflicts.md`. Brief: `git status` shows unmerged paths; accept
ours/theirs via `git checkout --ours/--theirs <file> && git add <file>`; abort
with `git merge --abort` (merge) or `git rebase --abort` (rebase).

### Broken / Botched Rebase

| Situation | Command |
|-----------|---------|
| Abort the rebase entirely | `git rebase --abort` |
| Continue after resolving a step | `git add <files> && git rebase --continue` |
| Recover after an accidental shared rebase | `git reset --hard origin/<branch>` |

Never resolve a rebase conflict without explicit user confirmation of each step.

### Stash

| Operation | Command |
|-----------|---------|
| Stash changes | `git stash push -m "<msg>"` |
| List stashes | `git stash list` |
| View a stash | `git stash show -p stash@{0}` |
| Apply and drop | `git stash pop` |
| Apply without dropping | `git stash apply` |
| Drop a stash | `git stash drop stash@{0}` |

## Execution Standards

1. **Parse** — Extract intent, select operation, validate params.
2. **Execute** — Run command, capture output, handle errors.
3. **Format** — Diffs as MD code blocks, logs as bullet lists, metadata as
   key-value pairs.
4. **Error handling** — Suggest auth (`gh auth login`) when needed; summarize
   or limit large output.

## Safety Constraints

- Destructive operations (`reset --hard`, `clean -f`, `push --force`) always
  require user confirmation and a warning.
- Prefer `--force-with-lease` over `--force`.
- Never rebase or force-push shared/public branches.
