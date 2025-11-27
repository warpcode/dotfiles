---
name: git-info-retriever
description: Retrieve Git/GitHub info: gh for remote (PRs/issues/URLs), git for local (status/diffs/logs). Route by context.
---

# Git Info Retriever

Guides routing: gh for GitHub (PRs/issues/releases/URLs), git for local data. Auth: `gh auth login` if needed.

## When to Use
- Given GitHub URL (PR/branch/commit link)
- Current git repo info (in working dir)
- PR details/diffs/reviews
- Repo status/branches/commits
- Local changes/unpushed commits
- Branch comparisons
- GitHub issues/releases/CI

## Supported Operations

### PRs
- Details: `gh pr view &lt;num&gt;`
- Diff: `gh pr diff &lt;num&gt;`
- Comments: `gh pr view &lt;num&gt; --comments`
- List: `gh pr list`

### Local Status
- Status: `git status`
- Unstaged: `git diff`
- Staged: `git diff --staged`
- Unpushed: `git log --oneline origin/main..HEAD`

### Commits
- History: `git log --oneline -10`
- Details: `git show &lt;hash&gt;`
- Diff stat: `git show --stat &lt;hash&gt;`

### Branches
- List: `git branch -a`
- Status: `git status` + `git log --oneline &lt;branch&gt; -5`
- Compare: `git diff &lt;b1&gt;..&lt;b2&gt;`

### Repo Metadata
- GitHub: `gh repo view`
- Remotes: `git remote -v`
- Contributors: `gh repo view --contributors` or `git shortlog -sn`

## Usage
1. Parse query (local/remote).
2. Run command, format: text summaries, MD diffs/logs, JSON if requested.
3. Errors: Suggest `gh auth login`; fallback to git; summarize large output.

**Best Practices:** Prefer gh for rich output; git for local/offline; combine cmds.

## Examples
- "PR #123 changes": `gh pr diff 123`
- "Repo status": `git status`
- "Recent commits": `git log --oneline -5`
- "Compare branches": `git diff main..feature`
- "Repo info": `gh repo view` + `git remote -v`

## Output
- Diffs: MD code blocks
- Logs: Bulleted lists
- Status: Sections (staged/unstaged)
- Metadata: Key-value

## Limits
- Needs git/gh installed; gh auth for private; internet for remote.
