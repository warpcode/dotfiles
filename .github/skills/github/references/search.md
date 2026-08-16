# GitHub Search & Discovery

Execute targeted search queries across code, commits, issues, pull requests, repositories, and users.

---

## Operations Overview

| Operation | Risk Level | Primary MCP Action | CLI Fallback (`gh` / `gh search`) |
| :--- | :--- | :--- | :--- |
| **Search code** | Read-Only | `search_code` | `gh search code "<query>" [--repo <owner>/<repo>]` |
| **Search commits** | Read-Only | `search_commits` | `gh search commits "<query>" [--repo <owner>/<repo>]` |
| **Search issues** | Read-Only | `search_issues` | `gh search issues "<query>" [--state open]` |
| **Search PRs** | Read-Only | `search_pull_requests` | `gh search prs "<query>" [--state open]` |
| **Search repos** | Read-Only | `search_repositories` | `gh search repos "<query>" [--language python]` |
| **Search users** | Read-Only | `search_users` | `gh api search/users?q=<query>` / `gh search users` |

---

## 1. Code Search

Search for symbols, function definitions, or patterns across repositories:

```bash
# Search within a specific repository
gh search code "function processData" --repo owner/repo

# Filter by language and file extension
gh search code "import React" --repo owner/repo --language TypeScript --filename "*.tsx"

# Search within repository path
gh search code "TODO" --repo owner/repo --path "src/"
```

---

## 2. Commit Search

Search for commit messages, authors, or hashes:

```bash
# Search commit messages within a repository
gh search commits "fix(auth)" --repo owner/repo

# Filter by author and date range
gh search commits "refactor" --author "octocat" --committer-date ">2026-01-01"
```

---

## 3. Issues & Pull Requests Search

Search across all accessible issues and pull requests:

```bash
# Search issues across a repo or org
gh search issues "database connection timeout" --repo owner/repo --state open

# Search PRs needing review
gh search prs "review-requested:@me" --state open

# Advanced qualifiers (labels, milestones, assignees)
gh search issues "type:bug priority:high" --repo owner/repo
```

---

## 4. Repository & User Search

```bash
# Search repositories by topic and star count
gh search repos "dotfiles" --topic "zsh" --stars ">100" --sort stars

# Search users / organizations
gh api "search/users?q=location:London+followers:>50" --jq '.items[] | {login: .login, url: .html_url}'
```
