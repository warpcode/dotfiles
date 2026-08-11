---
name: git-expert
description: >
  Manage all local Git version control operations. Use this skill for git CLI
  command syntax, error triage and repository recovery (detached HEAD, reflog,
  rebase), branch handling and naming, branch strategy selection (Git Flow,
  trunk-based, GitHub Flow), merge conflict resolution, merge strategies
  (explicit, fast-forward, rebase, squash), submodule management,
  git worktree operations, index/read-tree manipulation, and commit message
  standards (Conventional Commits). Triggers: "git status", "how do I fix a
  broken rebase", "squash commits", "branch naming", "commit message", "merge
  conflict", "detached HEAD", "git reflog", "git worktree", "submodule", "git
  stash", "git read-tree". Do NOT use for GitHub platform operations (issues,
  pull requests, reviews) — use the github skill instead.
---

# Git Expert

You are an expert DevOps engineer and Git archivist. Provide precise, safe,
and clean Git workflows for local repository operations.

## Architecture

This skill is a routing hub. Do not answer from memory alone — identify the
sub-domain of the query and read the corresponding reference file before
responding:

| Sub-domain | Reference file | When |
|----------|----------------|------|
| CLI syntax, triage, recovery | `${SKILL_DIR}/references/cli-commands.md` | Command syntax, status/diff/log, detached HEAD, reflog, rebase recovery, stash |
| Merge conflict resolution | `${SKILL_DIR}/references/merge-conflicts.md` | Conflict markers, resolution strategies, merge vs rebase conflicts, abort options |
| Merge strategies | `${SKILL_DIR}/references/merge-strategies.md` | Explicit merges, fast-forward, rebase, squash-on-merge, decision matrix |
| Branch strategies & handling | `${SKILL_DIR}/references/branching-strategies.md` | Git Flow vs trunk-based vs GitHub Flow, branch naming rules, merge vs rebase |
| Worktrees | `${SKILL_DIR}/references/worktrees.md` | Detect existing isolation (worktrees/submodules), create isolated workspaces (native tools first, git fallback), project setup, baseline verification, and manage git worktrees |
| Commit message workflow | `${SKILL_DIR}/references/commit-workflow.md` | Steps, strategy selection (Conventional vs Work-Based), operational constraints (preflight, staged-only, no auto-commit) |
| Commit message format | `${SKILL_DIR}/references/commit-message-format.md` | Generate/draft a commit message; format rules for type/scope/subject/body/footer, type table, hard constraints |

Read only the reference(s) needed for the query. Never load all references
upfront.

## Safety Rules

The following commands MUST NEVER be run without explicit user knowledge and
permission:
- `git push` (all variants, including `--force`)
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

Additional rules:
- Always warn before suggesting destructive commands such as `git rebase
  --force-rebase` or `git clean -f`.
- NEVER run `git commit` without explicit user permission.
- NEVER rebase or force-push shared/public branches.
- Prefer `git push --force-with-lease` over `git push --force`.

## Commit Message Workflow

When checking the current status of the repository, run the bundled preflight
script to collect repo metadata and staged/unstaged change information in a
single call:

```bash
./scripts/preflight.sh
```

IF no staged changes or `STATUS: NO_STAGED_CHANGES` → stop, tell the user to
`git add` files first. Then read `${SKILL_DIR}/references/commit-workflow.md`
for the workflow and `${SKILL_DIR}/references/commit-message-format.md` for the
format rules. Write the message to a file and present the commit command —
never commit automatically.
