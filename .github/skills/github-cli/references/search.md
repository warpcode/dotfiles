# GitHub Search & Discovery

Execute targeted search queries across code, commits, issues, pull requests, repositories, and users.

---

## Operations Overview

| Operation | Risk Level | Primary MCP Action | Script Fallback (`@scripts/`) |
| :--- | :--- | :--- | :--- |
| **Search code** | Read-Only | `search_code` | `search_code.sh` |
| **Search commits** | Read-Only | `search_commits` | `search_commits.sh` |
| **Search issues** | Read-Only | `search_issues` | `search_issues.sh` |
| **Search PRs** | Read-Only | `search_pull_requests` | `search_pull_requests.sh` |
| **Search repos** | Read-Only | `search_repositories` | `search_repositories.sh` |
| **Search users** | Read-Only | `search_users` | `search_users.sh` |

---

## 1. Code Search
```bash
bash @scripts/search_code.sh --query "function processData repo:owner/repo"
```

---

## 2. Commit Search
```bash
bash @scripts/search_commits.sh --query "fix(auth) repo:owner/repo"
```

---

## 3. Issues & Pull Requests Search
```bash
# Search issues across a repo or org
bash @scripts/search_issues.sh --query "database connection timeout repo:owner/repo state:open"

# Search PRs
bash @scripts/search_pull_requests.sh --query "review-requested:@me state:open"
```

---

## 4. Repository & User Search
```bash
# Search repositories
bash @scripts/search_repositories.sh --query "dotfiles topic:zsh stars:>100"

# Search users / organizations
bash @scripts/search_users.sh --query "location:London followers:>50"
```
