# Stacked Pull Requests (`gh stack`)

Execution reference for managing stacked branches and pull requests with the official `github/gh-stack` GitHub CLI extension. For general stacked PR design rules and merge policies, refer to the `github-pr` skill.

A **stack** is an ordered linear chain of branches rooted on a trunk (e.g., `main`):

```text
(main) <- layer-1 (bottom) <- layer-2 (middle) <- layer-3 (top)
```

- **Bottom**: closest to the trunk; merges first.
- **Top**: furthest from the trunk; merges last.
- `up` moves toward the top (away from trunk); `down` moves toward the trunk.

---

## 1. Prerequisites & Setup

Requires Git `2.36+` and an authenticated `gh` CLI (`v2.0+`):

```bash
gh extension install github/gh-stack
git config rerere.enabled true         # remember conflict resolutions across cascading rebases
git config remote.pushDefault origin   # required when multiple remotes exist
```

---

## 2. Non-Interactive Agent Rules

`gh stack` switches behavior on whether stdout is a TTY. Under a PTY, bare commands open prompts or full-screen TUIs and hang. Always use the non-interactive flags below:

| Always Run (Non-Interactive) | Never Run Bare (Interactive / TUI) | Reason |
|---|---|---|
| `gh stack view --json` | `gh stack view` | Bare `view` opens a full-screen TUI under a PTY |
| `gh stack submit --auto [--open]` | `gh stack submit` | Prompts interactively for a title per new PR |
| `gh stack merge <target> --yes [--squash]` | `gh pr merge` | `gh pr merge` cannot merge a native GitHub stack |
| `gh stack init <branch>...` | `gh stack init` | Prompts for branch names |
| `gh stack add <branch>` | `gh stack add` | Prompts for branch name and fails when piped |
| `gh stack checkout <target>` | `gh stack checkout` / `gh stack switch` | Opens an interactive picker menu |
| `gh stack unstack` + `gh stack init` | `gh stack modify` | `modify` is strictly TUI-only |

- For multiple remotes without `remote.pushDefault`, pass `--remote <name>` to `push`, `submit`, `sync`, `rebase`, and `link`.
- `gh stack <command> --help` prints flags and arguments; `gh stack help <command>` prints only top-level help.

---

## 3. Resolving Stack Conflicts (4-Step Flow)

Stacked pull requests rely on **rebasing rather than merge commits** to update branches:

```bash
# Step 1: Checkout the stack of branches locally (stack number, PR number, PR URL, or branch)
gh stack checkout <stack-or-pr-number>

# Step 2: Rebase the stack with changes from the base branch
gh stack rebase

# Step 3: If rebase stops on conflict (exit code 3), resolve files, stage them, and continue
git add <resolved-files>
gh stack rebase --continue
# Repeat --continue if upper layers also conflict.
# To abort and restore every branch in the stack to its pre-rebase state:
# gh stack rebase --abort

# Step 4: Push the updated stack branches atomically (--force-with-lease per branch)
gh stack push
```

- When editing a **lower layer** mid-review, check out that layer first (`gh stack checkout <layer>` or `gh stack down`), commit the fix, run `gh stack rebase --upstack`, return with `gh stack top`, and push with `gh stack push`.
- Use `--no-trunk` with `gh stack rebase` to align stack layers with each other without fetching or rebasing onto trunk.

---

## 4. Core Lifecycle Commands

### Creating & Submitting a New Stack
```bash
gh stack init <layer-1>                # initialize stack on first branch from default trunk (or --base <trunk>)
git add <files> && git commit -m "..."
gh stack add <layer-2>                 # branch layer-2 on top of layer-1
git add <files> && git commit -m "..."
gh stack submit --auto                 # atomic multi-ref push + open draft PRs linked as a stack (add --open for ready)
gh stack view --json                   # verify stack state
```
- Update auto-generated titles and bodies afterwards with `gh pr edit <num> --title "..." --body-file <file>`.

### Synchronizing & Post-Squash-Merge Updates
```bash
gh stack sync                          # fetch, reconcile with GitHub stack, rebase (--onto for merged PRs), push
gh stack sync --prune                  # also delete local branches for already-merged PRs
```
- If `gh stack sync` detects local vs. remote divergence, it prints both chains and exits `0` with `Sync aborted` without mutating state. To adopt the remote stack:
  ```bash
  gh stack unstack --local
  gh stack checkout <stack-or-pr-number>
  ```
- If `gh stack sync` exits `3` due to conflict, it restores all branches first; run `gh stack rebase` to stop at the conflict, resolve, `git add`, and `gh stack rebase --continue`.

### Merging a Stack
```bash
gh stack merge <pr-number> --yes --squash     # merge <pr-number> and every unmerged PR below it
gh stack merge <stack-number> --yes --squash  # merge every unmerged PR in stack #<stack-number>
```
- Merges are **all-or-nothing**: if any PR in the target set is blocked or draft, none merge.

### External Tools & Non-Interactive Restructuring
- **Link branches managed outside `gh stack`** (no local tracking):
  ```bash
  gh stack link <branch-1> <branch-2> <branch-3>          # bottom to top
  gh stack link <stack-number> <new-top-branch>           # append to existing stack
  ```
- **Restructure without TUI `modify`**:
  ```bash
  gh stack unstack                                        # removes grouping only; PRs & branches remain
  # adjust branch ancestry with git rebase --onto as needed
  gh stack init --base <trunk> <branch-1> <branch-2> ...
  gh stack submit --auto
  ```
- **Worktrees**: Use `--print-path` with navigation (`up`, `down`, `top`, `bottom`, `trunk`) or explicit `checkout` to get the owning worktree path without stealing another worktree's checkout.

---

## 5. Exit Codes & Recovery

| Code | Meaning | Recovery |
|---|---|---|
| `0` | Success | Check stderr for `Sync aborted` when running `gh stack sync` |
| `1` | Generic error | Read stderr |
| `2` | Not in a stack / stack not found | `gh stack init` or `gh stack checkout <target>` |
| `3` | Rebase conflict | After `rebase`: resolve + `git add` + `gh stack rebase --continue` (or `--abort`). After `sync`: run `gh stack rebase` to surface and resolve the conflict |
| `4` | GitHub API failure | Check `gh auth status` and retry |
| `5` | Invalid arguments or flags | Run `gh stack <command> --help` |
| `6` | Disambiguation required | Branch belongs to multiple stacks; checkout a unique branch or pass `<stack-number>` |
| `7` | Rebase already in progress | `gh stack rebase --continue` or `gh stack rebase --abort` |
| `8` | Stack file locked | Another `gh stack` process is active; wait ~5s and retry |
| `9` | Stacked PRs unavailable | Feature not enabled on repository; inform the user |
| `10` | Interrupted modify session | `gh stack modify --abort` |
