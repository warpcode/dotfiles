# GitHub Pull Requests

Execution commands for pull requests: create, update, publish, view, review, and search.

## 1. Operations Overview

| Operation | Primary MCP Action | Script Tool (`@scripts/`) | CLI Fallback (`gh`) |
| :--- | :--- | :--- | :--- |
| **Audit PR (Full)** | N/A | `pr_audit_bundle.sh` | N/A (1-call snapshot gather) |
| **Create PR** | `create_pull_request` | N/A | `gh pr create --draft ...` |
| **Read PR** | `pull_request_read` | N/A | `gh pr view <num> --comments` |
| **Rollup / CI Status**| N/A | `pr_state_rollup.py` | `gh pr list` / `gh pr checks` |
| **Update PR** | `update_pull_request` | N/A | `gh pr edit <num> ...` |
| **Merge PR** | `merge_pull_request` | `merge_pull_request.sh` | `gh pr merge <num> --squash` |
| **List PRs** | `list_pull_requests` | `list_pull_requests.sh` | `gh pr list` |
| **Request Copilot** | `request_copilot_review` | N/A | `gh pr edit <num> --add-reviewer github-copilot[bot]` |

---

## 2. Execute PR Workflows

### Audit a Pull Request (Composite Bundle)
Collect full metadata, clean diff, head file copies, and check runs in a single call:
```bash
# Auto-detected repository
bash @scripts/pr_audit_bundle.sh --repo <owner/repo> --pr 42 --out /tmp/pr42
```

### Create a Pull Request (Always Draft)
```bash
# Standard draft creation on current branch
gh pr create \
  --draft \
  --title "feat(ui): Add dark mode toggle" \
  --body-file "pr_body.md" \
  --base "master"

# Cross-repo / fork draft creation
gh pr create \
  --repo "octocat/hello-world" \
  --draft \
  --title "feat(ui): Add dark mode toggle" \
  --body-file "pr_body.md" \
  --head "fork-user:feat/dark-mode" \
  --base "master"
```

### Update a Pull Request
```bash
# Update title and body
gh pr edit 42 --title "feat(ui): Add dark mode toggle (v2)" --body-file "updated_body.md"

# Update with explicit repo override
gh pr edit 42 --repo "octocat/hello-world" --title "Updated title"
```

### Request Copilot Review
```bash
gh pr edit 42 --add-reviewer github-copilot[bot]
```

### Merge a Pull Request (Safe Ruleset Bypass)
> [!CAUTION]
> Always verify review checks and ruleset invariants first before initiating merge.

```bash
# Standard auto-detected repository
bash @scripts/merge_pull_request.sh --pull-number 42

# Explicit repository override
bash @scripts/merge_pull_request.sh --owner "octocat" --repo "hello-world" --pull-number 42

# Ruleset bypass with admin privileges (required when rulesets require admin)
bash @scripts/merge_pull_request.sh --owner "octocat" --repo "hello-world" --pull-number 42 --admin
```

### List & Filter Pull Requests
```bash
# 1. Basic open PRs overview on auto-detected repository
bash @scripts/list_pull_requests.sh

# 2. Discovery & Filtering with triage flags
bash @scripts/list_pull_requests.sh --approved
bash @scripts/list_pull_requests.sh --commits-after-review --state OPEN --limit 50
```

### Rollup PR State & CI Health
```bash
# Dense table of state, draft, head SHA, review decision, mergeability, and CI checks
python3 @scripts/pr_state_rollup.py --repo <owner/repo> 42 43
```
