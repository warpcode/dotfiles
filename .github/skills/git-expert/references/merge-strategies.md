# Merge Strategies

Reference for the different merge types available in Git: explicit merges,
implicit merges (rebase/fast-forward), and squash-on-merge. Read this file
when the query involves how changes are integrated into a branch.

## Merge Types

### Explicit Merges

Explicit merges are the default merge type. The "explicit" part is that they
create a new merge commit. This alters the commit history and explicitly shows
where a merge was executed. The merge commit content is also explicit in the
fact that it shows which commits were the parents of the merge commit. Some
teams avoid explicit merges because arguably the merge commits add "noise" to
the history of the project.

```bash
git merge feature/branch
```

- Creates a merge commit with two parents
- Preserves full history and context
- Best for: shared branches, release branches, when history fidelity matters

### Implicit Merges (Fast-Forward)

When the target branch has not diverged, Git can perform a fast-forward merge
— no merge commit is created, the branch pointer simply moves forward.

```bash
git merge feature/branch   # fast-forwards if possible
```

- No merge commit; linear history
- Best for: short-lived feature branches, clean history preference

### Implicit Merges (Rebase)

Rebase replays commits from the source branch on top of the target branch,
producing a linear history without a merge commit.

```bash
git rebase main             # rebase feature branch onto main
git checkout main
git merge feature/branch    # fast-forward
```

- Linear history, no merge commit
- Best for: personal branches, clean history preference
- **Never rebase shared/public branches**

### Squash on Merge

Squash-on-merge combines all commits from the source branch into a single new
commit on the target branch. No merge commit is created.

```bash
git merge --squash feature/branch
git commit
```

- Single commit on target branch
- Best for: keeping history clean, when individual commits are not meaningful
- Loses individual commit history from the source branch

## Decision Matrix

The matrix below shows the **default** merge type for each scenario. These
defaults apply only when no project-specific rules already specify a different
merge type. Always defer to explicit project/team conventions when they exist.

### Process-Based Defaults

| Scenario | Default Merge Type | Rationale |
|----------|-------------------|-----------|
| `git pull` (sync with remote) | Implicit (rebase or fast-forward) | Keeps local history clean; no merge commit noise |
| Update feature branch from main | Explicit | Preserves context of when the branch was synced |
| Merge feature branch into another feature branch | Explicit | Shows integration point; preserves both branch histories |
| Merge sub-branches into parent branch | Explicit | Maintains audit trail of what was merged when |
| Release a completed feature branch | Squash | Condenses feature work into a single commit on the release branch |

### Merge Type Summary

| Merge Type | History | Merge Commit | Use Case |
|------------|---------|--------------|----------|
| Explicit merge | Preserved | Yes | Shared branches, releases, integration points |
| Fast-forward | Linear | No | Short-lived branches, `git pull` |
| Rebase | Linear | No | Personal branches, cleanup, `git pull` |
| Squash | Condensed | No | Clean history, single commit, releases |

## Safety

- NEVER rebase shared/public branches.
- NEVER force-push without `--force-with-lease` and user confirmation.
- Recover from botched rebases with `git rebase --abort` or the reflog (see
  `@references/merge-conflicts.md` Recovery Recipes).
