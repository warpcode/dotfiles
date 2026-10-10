---
name: git-worktrees
description: >
  Manage git worktrees and isolated workspaces: detect existing worktree/submodule
  isolation, create isolated worktrees (native tools first, git fallback),
  verify directory ignore safety, and inspect or prune worktrees. Use when
  managing git worktrees or setting up isolated workspaces.
user-invocable: false
---

# Git Worktrees & Workspace Isolation

Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.

**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.

## Standard Operating Procedure

### Step 0: Detect Existing Isolation

Before creating anything, check if you are already in an isolated workspace:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:

```bash
# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
git rev-parse --show-superproject-working-tree 2>/dev/null
```

**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to project setup. Do NOT create another worktree.

Report with branch state:
- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."

**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout.

Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:

> "Would you like me to set up an isolated worktree? It protects your current branch from changes."

Honor any existing declared preference without asking. If the user declines consent, work in place.

### Step 1a: Native Worktree Tools Preference

The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and proceed with task execution.

Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.

Only proceed to Step 1b if you have no native worktree tool available.

### Step 1b: Git Worktree Manual Fallback

Only use this if Step 1a does not apply — you have no native worktree tool available. Create a worktree manually using git.

#### Directory Selection Priority Hierarchy

Follow this priority order. Explicit user preference always beats observed filesystem state.

1. Check your instructions for a declared worktree directory preference. If specified, use it without asking.
2. Check for an existing project-local worktree directory:
   ```bash
   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
   ls -d worktrees 2>/dev/null      # Alternative
   ```
   If found, use it. If both exist, `.worktrees` wins.
3. Default to `.worktrees/` at the project root if no other guidance is available.

#### Safety Verification & Git Ignore Gate

MUST verify directory is ignored before creating worktree:

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

If NOT ignored: Add to `.gitignore`, commit the change, then proceed.
Why critical: Prevents accidentally committing worktree contents to repository.

#### Worktree Creation

```bash
path="$LOCATION/$BRANCH_NAME"
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

Sandbox fallback: If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and work in current directory instead.

## Shared Resources

Run bundled helper scripts relative to this skill's root directory (`<skill-dir>/scripts/...` e.g. `.github/skills/git-worktrees/scripts/...`):

| Script | Purpose | Invocation |
|--------|---------|------------|
| `@scripts/worktrees.sh` | Create isolated worktree, list active/stale worktrees, prune metadata, or remove worktree | `bash <skill-dir>/scripts/worktrees.sh [--create <branch>] [--base <base>] [--remove <path>] [--raw]` |

## Worktree Management & Lifecycle

Use the bundled script for end-to-end worktree isolation, inspection, and cleanup:

```bash
# Create an isolated worktree for a branch and merge base ref (e.g. origin/master)
bash <skill-dir>/scripts/worktrees.sh --create <branch> [--base <base>] [--path <path>]

# Detect active and stale worktrees, and prune metadata (dry-run by default)
bash <skill-dir>/scripts/worktrees.sh

# Raw porcelain output
bash <skill-dir>/scripts/worktrees.sh --raw

# Remove a specific worktree (requires explicit confirmation and flag)
bash <skill-dir>/scripts/worktrees.sh --remove <path>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| Already in linked worktree | Skip creation (Step 0) |
| In a submodule | Treat as normal repo (Step 0 guard) |
| Native worktree tool available | Use it (Step 1a) |
| No native tool | Git worktree fallback (Step 1b) |
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check instruction file, then default `.worktrees/` |
| Directory not ignored | Add to .gitignore + commit |
| Permission error on create | Sandbox fallback, work in place |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I'm obviously not in a worktree — no need to check" | Run Step 0. Harness-created isolation and submodules both fool eyeballing; the detection commands settle it. |
| "`git worktree add` is quicker than hunting for a native tool" | A native tool (e.g. `EnterWorktree`) owns placement, branching, and cleanup. Bypassing it is the #1 mistake — it creates phantom state your harness can't see or manage. |
| "The worktree directory is surely ignored already" | Run `git check-ignore`. An unignored worktree directory commits the whole tree into the repo. |
| "Any directory name works" | Explicit instructions beat an existing project-local directory, which beats the `.worktrees/` default. |
| "The workspace is fresh — baseline tests can wait" | A dirty baseline makes every later failure ambiguous. Run the tests now; proceeding past failures is your human partner's call. |
