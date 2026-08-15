# Branching Strategies

Reference for branching strategies, branch naming rules, and the merge-vs-rebase
decision. Read this file when the query involves branch strategy selection (Git Flow,
trunk-based, GitHub Flow), branch creation/naming, or how to integrate changes.

## Branch Strategy Selection

Ask what fits the repo/team before recommending. Key dimensions: team size,
release model, CI/CD setup.

| Branch Strategy | Best for | Characteristics |
|----------|----------|-----------------|
| **Git Flow** | Releases on a cadence | `develop` + `feature/*` + `release/*` + `hotfix/*`; `master` holds only released code |
| **GitHub Flow** | Continuous deployment, small teams | One mainline branch; short-lived feature branches; PR per change |
| **Trunk-based** | CI/CD, trunk-stable teams | Short-lived branches or direct commits; feature flags for incomplete work |

### Decision heuristic

```
IF releases on a fixed cadence → Git Flow
ELSE IF continuous delivery, few developers → GitHub Flow
ELSE IF CI/CD with short-lived branches / feature flags → Trunk-based
```

## Branch Naming Rules

Enforce before branch creation. No special characters (`git` allows most, but
naming rules keep things safe and greppable).

| Branch type | Pattern | Example |
|-------------|---------|---------|
| Feature | `feat/<ticket>-<slug>` | `feat/tic-1234-oauth-login` |
| Fix | `fix/<ticket>-<slug>` | `fix/tic-4567-null-jwt` |
| Hotfix | `hotfix/<slug>` | `hotfix/logout-timeout` |
| Release | `release/<version>` | `release/v2.1.0` |
| Chore | `chore/<slug>` | `chore/dep-upgrade` |

Rules:
- Use hyphens between words, no spaces, no `/` in the slug portion itself.
- Include the ticket ID when one exists or one is provided — it makes cross-referencing trivial.
- Do not name branches after the person; name them after the work.

## Merge vs Rebase

See `${SKILL_DIR}/references/merge-strategies.md` for the full breakdown of
merge types (explicit, fast-forward, rebase, squash) and when to use each.

**Rule: Merge (public), Rebase (private).**

| Scenario | Rebase | Merge |
|----------|--------|-------|
| Update feature branch from main | ✅ | ❌ |
| Integrate feature into main | ❌ | ✅ |
| Clean local commits (squash WIP) | ✅ | ❌ |
| Shared branch | ❌ | ✅ |
| Public history | ❌ | ✅ |
| Private branch | ✅ | Either |

## Common Operations

### Update a feature branch

```bash
git fetch origin && git rebase origin/main
```

Conflicts: `git add <files> && git rebase --continue` (**always** ask user).
Abort: `git rebase --abort`.

### Interactive rebase (clean history)

```bash
git rebase -i HEAD~5   # edit last 5 commits
```

Commands: `pick` keep, `reword` edit message, `edit` amend, `squash` merge
into previous, `fixup` merge discarding message, `drop` remove.

### Squash all local commits

```bash
git rebase -i $(git merge-base HEAD main)
```

### Compare branch to base (PR preparation)

```bash
# Token-efficient divergence, commit list, and file diffs
bash ${SKILL_DIR}/scripts/branch_diff.sh [base_branch]
```

### Branch overview & cleanup

```bash
# List local/remote branches with upstream tracking and merged status
bash ${SKILL_DIR}/scripts/branches.sh

# Prune stale tracking refs and delete merged local branches (requires confirmation)
bash ${SKILL_DIR}/scripts/branches.sh --prune --delete-merged
```

### Push safely

```bash
git push --force-with-lease   # never plain --force on shared branches
```

## Safety

- NEVER rebase shared/public branches.
- NEVER force-push without `--force-with-lease` and user confirmation.
- Recover from botched rebases with `git rebase --abort` or the reflog (see
  `${SKILL_DIR}/references/cli-commands.md`).
