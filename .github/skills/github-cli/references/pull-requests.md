# GitHub Pull Requests

Execution commands for pull requests: create, update, publish, view, review, and search.

## 1. Operations Overview

| Operation | Primary MCP Action | Script Fallback (`${SKILL_DIR}/scripts/`) | CLI Fallback (`gh`) |
| :--- | :--- | :--- | :--- |
| **Create PR** | `create_pull_request` | `create_pull_request.sh` | `gh pr create --draft ...` |
| **Read PR** | `pull_request_read` | `get_pull_request.sh` | `gh pr view <num> --comments` |
| **Update PR** | `update_pull_request` | `update_pull_request.sh` | `gh pr edit <num> ...` |
| **Update Branch** | `update_pull_request_branch` | `update_pull_request_branch.sh` | `gh pr update-branch <num>` |
| **Merge PR** | `merge_pull_request` | `merge_pull_request.sh` | `gh pr merge <num> --squash` |
| **List PRs** | `list_pull_requests` | `list_pull_requests.sh` | `gh pr list` |
| **Request Copilot** | `request_copilot_review` | `request_copilot_review.sh` | `gh api ... requested_reviewers` |

---

## 2. Execute via Scripts

### Create a Pull Request
Execute creation (always draft):
```bash
# 1. Standard creation on auto-detected repository
bash ${SKILL_DIR}/scripts/create_pull_request.sh \
  --title "feat(ui): Add dark mode toggle" \
  --body "PR description body" \
  --head "$current_branch" \
  --base "$base_branch"

# 2. Creation on explicit target repository (cross-repo / forks)
bash ${SKILL_DIR}/scripts/create_pull_request.sh \
  --owner "octocat" \
  --repo "hello-world" \
  --title "feat(ui): Add dark mode toggle" \
  --body "PR description body" \
  --head "fork-user:feat/dark-mode" \
  --base "main"
```

### Update a Pull Request
```bash
# Update title and body on current repo
bash ${SKILL_DIR}/scripts/update_pull_request.sh \
  --pull-number 42 \
  --title "feat(ui): Add dark mode toggle (v2)" \
  --body "Updated PR description body"

# Update with explicit owner/repo override
bash ${SKILL_DIR}/scripts/update_pull_request.sh \
  --owner "octocat" \
  --repo "hello-world" \
  --pull-number 42 \
  --title "Updated title" \
  --body "Updated body"
```

### Synchronize / Update PR Branch
```bash
# Auto-detected repository
bash ${SKILL_DIR}/scripts/update_pull_request_branch.sh --pull-number 42

# Explicit owner/repo
bash ${SKILL_DIR}/scripts/update_pull_request_branch.sh --owner "octocat" --repo "hello-world" --pull-number 42
```

### Request Copilot Review
```bash
bash ${SKILL_DIR}/scripts/request_copilot_review.sh --pull-number 42
### Get Pull Request & Merge Readiness
Fetch full pull request state, merge readiness checks, reviews, and comments:
```bash
# Auto-detected repository
bash ${SKILL_DIR}/scripts/get_pull_request.sh --pull-number 42

# Explicit repository override
bash ${SKILL_DIR}/scripts/get_pull_request.sh --owner "octocat" --repo "hello-world" --pull-number 42
```

### Merge a Pull Request
> [!CAUTION]
> Run `${SKILL_DIR}/scripts/get_pull_request.sh --pull-number <pr_number>` or review checks first to verify merge status and readiness.

```bash
# Auto-detected repository
bash ${SKILL_DIR}/scripts/merge_pull_request.sh --pull-number 42

# Explicit repository override
bash ${SKILL_DIR}/scripts/merge_pull_request.sh --owner "octocat" --repo "hello-world" --pull-number 42
```

### View & Read PR Details
Read raw JSON/comments or formatted view:
```bash
# Auto-detected repository
bash ${SKILL_DIR}/scripts/get_pull_request.sh --pull-number 42

# Explicit repository override
bash ${SKILL_DIR}/scripts/get_pull_request.sh --owner "octocat" --repo "hello-world" --pull-number 42
```

### List & Filter Pull Requests
```bash
# 1. Basic open PRs overview on auto-detected repository
bash ${SKILL_DIR}/scripts/list_pull_requests.sh

# 2. Basic open PRs on explicit repository
bash ${SKILL_DIR}/scripts/list_pull_requests.sh --owner "octocat" --repo "hello-world"

# 3. Discovery & Filtering (with optional flags)
bash ${SKILL_DIR}/scripts/list_pull_requests.sh --all
bash ${SKILL_DIR}/scripts/list_pull_requests.sh --owner "octocat" --repo "hello-world" --approved
bash ${SKILL_DIR}/scripts/list_pull_requests.sh --commits-after-review --state OPEN --limit 50
```
