---
name: git-info-retriever
description: Retrieve Git/GitHub info: gh for remote (PRs/issues/URLs), git for local (status/diffs/logs). Route by context.
---

# Git Info Retriever

Route: gh for GitHub (PRs/issues/releases/URLs), git for local. Auth: `gh auth login` if needed.

## Use Cases
- GitHub URLs/PRs/issues
- Local repo status/branches/commits
- Changes/diffs/reviews

## Operations
- **PRs**: view `gh pr view <num>`, diff `gh pr diff <num>`, comments `gh pr view <num> --comments`, list `gh pr list`
- **Local**: status `git status`, unstaged `git diff`, staged `git diff --staged`, unpushed `git log --oneline origin/main..HEAD`
- **Commits**: history `git log --oneline -10`, details `git show <hash>`, stat `git show --stat <hash>`
- **Branches**: list `git branch -a`, compare `git diff <b1>..<b2>`
- **Repo**: GitHub `gh repo view`, remotes `git remote -v`, contributors `gh repo view --contributors`

## Usage
Parse query → run cmd → format (MD diffs, bullets logs, key-value metadata). Errors: suggest auth, fallback git, summarize large.

**Best**: gh for rich, git for local. Combine cmds.

## Limits
Requires git/gh; auth for private; internet for remote.
