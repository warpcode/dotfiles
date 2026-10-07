# GitHub Search & Discovery

Execute targeted search queries across code, commits, issues, pull requests, repositories, and users.

---

## Operations Overview

| Operation | Risk Level | Primary MCP Action | CLI Fallback (`gh`) |
| :--- | :--- | :--- | :--- |
| **Search code** | Read-Only | `search_code` | `gh search code <query>` |
| **Search commits** | Read-Only | `search_commits` | `gh search commits <query>` |
| **Search issues** | Read-Only | `search_issues` | `gh search issues <query>` |
| **Search PRs** | Read-Only | `search_pull_requests` | `gh search prs <query>` |
| **Search repos** | Read-Only | `search_repositories` | `gh search repos <query>` |
| **Search users** | Read-Only | `search_users` | `gh api search/users?q=<query>` |

---

## 1. Code Search
```bash
gh search code "function processData repo:owner/repo"
```

---

## 2. Commit Search
```bash
gh search commits "fix(auth) repo:owner/repo"
```

---

## 3. Issues & Pull Requests Search
```bash
# Search issues across a repo or org
gh search issues "database connection timeout repo:owner/repo state:open"

# Search PRs
gh search prs "review-requested:@me state:open"
```

---

## 4. Repository & User Search
```bash
# Search repositories
gh search repos "dotfiles topic:zsh stars:>100"

# Search users / organizations
gh api search/users -f q="location:London followers:>50"
```
