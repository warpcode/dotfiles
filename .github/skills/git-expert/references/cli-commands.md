# Git CLI Commands & Triage

Reference for git CLI syntax, error triage, and repository recovery recipes.
Read this file when the query involves command syntax, status/diff/log output,
or recovery from a broken state (detached HEAD, lost commits, merge conflicts,
botched rebase).

## Common Commands

Everyday git commands an AI agent uses, grouped by workflow — the day-to-day
inspect → stage → commit → branch → sync → integrate loop. Format output as:
diffs in MD code blocks, logs as bullet lists, metadata as key-value pairs.

### Inspect State

| Operation | Command | Notes |
|-----------|---------|-------|
| Working tree status | `git status` | Always the first command; shows branch, staged/unstaged/untracked |
| Short status | `git status -sb` | Branch + ahead/behind in one line |
| Unstaged diff | `git diff` | Working tree vs index |
| Staged diff | `git diff --staged` | Index vs HEAD — what a commit would contain |
| Diff a specific file | `git diff -- <path>` | Scope to one path |
| Recent history | `git log --oneline -10` | Compact one-line log |
| History with graph | `git log --oneline --graph --all -20` | Branch topology |
| Show a commit | `git show <hash>` | Full diff + metadata |
| Show commit stat | `git show --stat <hash>` | Files changed summary |
| Unpushed commits | `git log --oneline origin/main..HEAD` | Commits ahead of remote |
| Compare branches | `git diff <b1>..<b2>` | Diff between two refs |
| Who changed a line | `git blame <file>` | Per-line attribution |

> **Tip:** For one-shot token-efficient summaries, use bundled scripts:
> - `@scripts/repo_overview.sh` — remotes, recent commits, tags, worktrees, stashes, config
> - `@scripts/branches.sh` — branch tracking, ahead/behind counts, and merged status
> - `@scripts/branch_diff.sh` — branch divergence, commit list, and file diffs vs base
> - `@scripts/status.sh` — working tree state, branch, staged/unstaged summary, and push/pull counts

### Stage & Unstage

| Operation | Command | Notes |
|-----------|---------|-------|
| Stage a file | `git add <path>` | |
| Stage all | `git add -A` | Includes deletions and untracked |
| Stage interactively | `git add -p` | Hunk-by-hunk staging |
| Unstage a file | `git restore --staged <path>` | Keeps working-tree changes |
| Discard a change | `git restore <path>` | ⚠️ Destructive — confirm first |
| Remove a file | `git rm <path>` | Stages the deletion |
| Rename/move | `git mv <old> <new>` | Stages the rename |

### Commit

| Operation | Command | Notes |
|-----------|---------|-------|
| Commit staged changes | `git commit -m "<msg>"` | Only staged changes |
| Commit from file | `git commit -F <file>` | Message from file — see `@references/commit-workflow.md` |
| Amend last commit | `git commit --amend` | ⚠️ Only if not yet pushed |
| Show last commit | `git show HEAD` | |

### Branch & Switch

| Operation | Command | Notes |
|-----------|---------|-------|
| List branches | `git branch -a` | Local + remote |
| List with upstreams | `git branch -vv` | Tracking + ahead/behind |
| Current branch | `git branch --show-current` | |
| Create + switch | `git switch -c <name>` | Modern `checkout -b` |
| Switch branch | `git switch <name>` | |
| Delete merged branch | `git branch -d <name>` | Safe — refuses if unmerged |
| Delete unmerged branch | `git branch -D <name>` | ⚠️ Destructive — confirm first |
| Rename branch | `git branch -m <new>` | |

### Remote Sync

| Operation | Command | Notes |
|-----------|---------|-------|
| List remotes | `git remote -v` | |
| Fetch remote refs | `git fetch` | Updates remote-tracking refs only |
| Fetch + merge | `git pull` | Defaults to merge — see `@references/merge-strategies.md` |
| Fetch + rebase | `git pull --rebase` | Linear history |
| Push branch | `git push` | ⚠️ Requires user permission |
| Push + set upstream | `git push -u origin <branch>` | First push of a new branch |
| Force-push with lease | `git push --force-with-lease` | ⚠️ Only safe force-push form |
| Delete remote branch | `git push origin --delete <branch>` | ⚠️ Confirm first |

### Integrate

| Operation | Command | Notes |
|-----------|---------|-------|
| Merge a branch | `git merge <branch>` | See `@references/merge-strategies.md` |
| Abort a merge | `git merge --abort` | |
| Rebase onto branch | `git rebase <branch>` | ⚠️ Never on shared branches |
| Abort a rebase | `git rebase --abort` | |
| Continue a rebase | `git add <files> && git rebase --continue` | After resolving conflicts |
| Cherry-pick a commit | `git cherry-pick <hash>` | Apply one commit onto HEAD |

### Stash

| Operation | Command | Notes |
|-----------|---------|-------|
| Stash changes | `git stash push -m "<msg>"` | |
| List stashes | `git stash list` | |
| View a stash | `git stash show -p stash@{0}` | |
| Apply + drop | `git stash pop` | |
| Apply without drop | `git stash apply` | |
| Drop a stash | `git stash drop stash@{0}` | |

> **Tip:** Use `@scripts/stash.sh` to view stashes with age and file lists, or filter/drop aged stashes via `@scripts/stash.sh --older-than N [--drop]`.

### Search

| Operation | Command | Notes |
|-----------|---------|-------|
| Search tracked code | `git grep <pattern>` | Faster than grep on tracked files |
| Find when a string changed | `git log -S "<string>" --oneline` | Pickaxe search |
| Search commit messages | `git log --grep="<text>" --oneline` | |
| Commits touching a file | `git log --oneline -- <path>` | |

### Tags

| Operation | Command | Notes |
|-----------|---------|-------|
| List tags | `git tag` | |
| Create annotated tag | `git tag -a <name> -m "<msg>"` | |
| Push a tag | `git push origin <name>` | ⚠️ Confirm first |

### Config

| Operation | Command | Notes |
|-----------|---------|-------|
| Read a setting | `git config --get <key>` | |
| Set repo setting | `git config <key> <value>` | Repo-scoped |
| Set global setting | `git config --global <key> <value>` | User-scoped |
| List effective config | `git config --list` | |

### Worktrees & Submodules

| Operation | Command | Notes |
|-----------|---------|-------|
| List worktrees | `git worktree list` | |
| Add a worktree | `git worktree add <path> <branch>` | See `@references/worktrees.md` |
| Remove a worktree | `git worktree remove <path>` | |
| List submodules | `git submodule status` | |
| Init submodules | `git submodule update --init --recursive` | After a fresh clone |

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
`@references/merge-conflicts.md`. For one-shot detection of in-progress state and conflict triage,
use `@scripts/merge_state.sh`. Brief: `git status` shows unmerged paths; accept
ours/theirs via `git checkout --ours/--theirs <file> && git add <file>`; abort
with `git merge --abort` (merge) or `git rebase --abort` (rebase).

### Broken / Botched Rebase

| Situation | Command |
|-----------|---------|
| Abort the rebase entirely | `git rebase --abort` |
| Continue after resolving a step | `git add <files> && git rebase --continue` |
| Recover after an accidental shared rebase | `git reset --hard origin/<branch>` |

Never resolve a rebase conflict without explicit user confirmation of each step.

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
