---
name: git-info-retriever
description: Retrieve information from Git repositories and GitHub. Use gh CLI for remote/GitHub operations (PRs, issues, repo metadata) and git CLI for local repository data (status, diffs, logs). Automatically route queries to the appropriate tool based on context.
---

# Git Info Retriever

This skill provides comprehensive guidance for retrieving information from Git repositories and GitHub, prioritizing `gh` CLI for remote operations while using `git` for local-only data. It helps Claude intelligently route requests to the right tool and format outputs appropriately.

## When to Use This Skill

Trigger this skill when users ask for:
- Pull request details, diffs, or reviews
- Repository status, branches, or metadata
- Commit histories or specific commit information
- Local changes (staged/unstaged) or unpushed commits
- Branch comparisons or merge status
- GitHub issues, releases, or CI status

## Core Functionality

### Query Routing Logic
- **GitHub-specific requests** (PRs, issues, releases): Use `gh` commands
- **Local repository data** (status, local diffs, logs): Use `git` commands
- **Remote branch/repo info**: Prefer `gh` when available, fallback to `git remote`
- **Authentication required**: Prompt for `gh auth login` if needed

### Supported Operations

#### Pull Request Information
- View PR details: `gh pr view <number>`
- PR diff vs main/master: `gh pr diff <number>`
- PR reviews/comments: `gh pr view <number> --comments`
- List open PRs: `gh pr list`

#### Local Repository Status
- Working tree status: `git status`
- Unstaged changes: `git diff`
- Staged changes: `git diff --staged`
- Unpushed commits: `git log --oneline origin/main..HEAD`

#### Commit Information
- Commit history: `git log --oneline -10`
- Specific commit details: `git show <commit-hash>`
- Commit diffs: `git show --stat <commit-hash>`

#### Branch Information
- List branches: `git branch -a`
- Branch status: `git status` + `git log --oneline <branch> -5`
- Branch comparison: `git diff <branch1>..<branch2>`

#### Repository Metadata
- GitHub repo info: `gh repo view`
- Local remotes: `git remote -v`
- Contributors: `gh repo view --contributors` or `git shortlog -sn`

## Usage Guidelines

### Command Execution
1. Parse the user query to determine scope (local vs remote)
2. Select the appropriate CLI tool and command
3. Execute the command and capture output
4. Format output for readability:
   - Plain text for status/summaries
   - Markdown for diffs and logs
   - JSON for structured data when requested

### Error Handling
- If `gh` fails due to auth: Suggest `gh auth login`
- If command not found: Check if tools are installed
- Network issues: Fallback to local `git` equivalents where possible
- Large outputs: Summarize or paginate results

### Best Practices
- Always prefer `gh` for GitHub data to leverage rich formatting
- Use `git` for local operations to avoid unnecessary API calls
- Combine commands when needed (e.g., `git status` + `gh pr status`)
- Respect rate limits and authentication requirements

## Examples

### Example 1: PR Changes
User: "Show me the changes in PR #123"
Claude: Use `gh pr diff 123` to get the diff against main branch

### Example 2: Local Status
User: "What's the status of my repo?"
Claude: Use `git status` to show staged/unstaged changes and branch info

### Example 3: Commit History
User: "What are my recent commits?"
Claude: Use `git log --oneline -5` for recent commit summaries

### Example 4: Branch Comparison
User: "Compare feature-branch with main"
Claude: Use `git diff main..feature-branch` for the differences

### Example 5: Repository Info
User: "Tell me about this repository"
Claude: Use `gh repo view` for GitHub metadata, supplement with `git remote -v` for local remotes

## Output Formatting

- **Diffs**: Use markdown code blocks with syntax highlighting
- **Logs**: Format as bullet lists with commit hashes and messages
- **Status**: Clear sections for staged, unstaged, and untracked files
- **Metadata**: Structured format with key-value pairs

## Limitations

- Requires `git` and `gh` CLI tools to be installed
- `gh` operations need authentication for private repos
- Some `gh` features may require specific GitHub plan levels
- Local operations work offline, remote operations require internet
