# Worktrees & Workspace Isolation

Reference for detecting existing workspace isolation, selecting native worktree tools vs. manual git worktrees, verifying `.gitignore` safety, and managing worktrees via bundled scripts.

**Core principle:** Detect existing isolation first. Prefer native harness worktree tools when available; fall back to manual git worktrees only when no native tool exists.

## Isolation Detection & Submodule Guard

Check whether the current directory is already an isolated linked worktree before creating anything:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Verify you are not in a submodule before concluding you are in a worktree:

```bash
# Non-empty output means you are in a submodule, not a linked worktree
git rev-parse --show-superproject-working-tree 2>/dev/null
```

- **If `GIT_DIR != GIT_COMMON` (and not a submodule):** Already in a linked worktree. Do not create a second nested worktree. Note whether `HEAD` is on a branch or detached.
- **If `GIT_DIR == GIT_COMMON` (or inside a submodule):** In a normal repo checkout. Confirm workspace isolation preference before creating a worktree unless instructions already declare one.

## Native Tools vs. Manual Git Worktree Fallback

### Native Worktree Tools Preference

If your harness provides a native worktree tool (e.g., `EnterWorktree`, `WorktreeCreate`, `/worktree`, or `--worktree`), use it rather than running `git worktree add` directly. Native tools manage directory placement, branch creation, and cleanup; bypassing them creates phantom state the harness cannot track.

### Manual Git Worktree Fallback

When no native worktree tool is available, follow this directory selection priority:

1. Declared worktree directory preference in repo/user instructions (use without asking).
2. Existing project-local worktree directory (`.worktrees` takes precedence over `worktrees` if both exist).
3. Default to `.worktrees/` at the project root (or `/tmp/wt-<branch>` when external isolation is preferred).

#### Safety Verification & `.gitignore` Gate

For project-local worktree directories, verify the directory is ignored before creating the worktree:

```bash
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

If not ignored, add the directory to `.gitignore` and commit that change before creating the worktree so worktree contents are never accidentally committed.

#### Manual Creation

```bash
path="$LOCATION/$BRANCH_NAME"
git worktree add "$path" -b "$BRANCH_NAME" <base-ref>
```

If `git worktree add` fails with a sandbox permission error, report the block or use `BypassSandbox: true` when authorized.

## Bundled Scripts

Run bundled helper scripts relative to the `git-expert` skill directory (`.github/skills/git-expert/scripts/...`):

| Script | Purpose | Invocation |
|---|---|---|
| `@scripts/worktrees.sh` | Create, list, prune, or remove isolated worktrees | `bash <skill-dir>/scripts/worktrees.sh [-C <dir>] [--create <branch>] [--base <ref>] [--path <dir>] [--remove <path>] [--raw]` |
| `@scripts/wt_test.sh` | Run a command or test suite inside a worktree with execution summary | `bash <skill-dir>/scripts/wt_test.sh <worktree-path> <command...>` |
| `@scripts/pr_sync.sh` | Sync a PR branch with a base ref (`--base <ref>`, defaulting to the auto-detected repository default branch) in an isolated worktree | `bash <skill-dir>/scripts/pr_sync.sh <pr-or-branch> [--base <ref>] [--continue \| --abort]` |

### Common Invocations

```bash
# Create an isolated worktree for a branch from a specific base ref
bash <skill-dir>/scripts/worktrees.sh --create <branch> [--base <ref>] [--path <dir>]

# Inspect active and stale worktrees (dry-run by default)
bash <skill-dir>/scripts/worktrees.sh [-C /path/to/repo] [--raw]

# Remove a linked worktree (preserves dirty trees unless --force is passed)
bash <skill-dir>/scripts/worktrees.sh --remove <path>

# Execute tests or builds inside an isolated worktree
bash <skill-dir>/scripts/wt_test.sh <worktree-path> <command...>
```

> [!TIP]
> **Sandbox Bypass**: In sandboxed agent environments that restrict `/tmp` or path globs, run worktree creation and skill script commands with `BypassSandbox: true` to avoid execution aborts.

## Quick Reference

| Situation | Action |
|---|---|
| Already in linked worktree | Skip worktree creation |
| Inside a submodule | Treat as normal checkout (submodule guard) |
| Native worktree tool available | Use native tool instead of `git worktree add` |
| No native tool available | Follow manual directory priority + `.gitignore` gate |
| `.worktrees/` and `worktrees/` both exist | `.worktrees/` wins |
| Directory not ignored | Add to `.gitignore` and commit before creating worktree |
| Permission error on create | Report sandbox block or run with `BypassSandbox: true` |

## Common Rationalizations

| Excuse | Reality |
|---|---|
| "Obviously not in a worktree — skip detection" | Harness isolation and submodules both fool eyeballing; run `GIT_DIR` vs `GIT_COMMON` and the submodule guard. |
| "`git worktree add` is faster than a native tool" | Bypassing native tools creates phantom state the harness cannot track or clean up. |
| "The worktree directory is surely ignored already" | Always verify with `git check-ignore`; an unignored worktree commits the whole checkout. |
| "Any directory name works" | Explicit instructions beat project-local `.worktrees/`, which beats `worktrees/`. |
| "The workspace is fresh — baseline tests can wait" | A dirty baseline makes later failures ambiguous; verify baseline health early. |
