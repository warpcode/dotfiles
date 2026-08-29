# GitHub Issues

Execution commands for managing GitHub issues: create, update, query, comment, and triage.

## 1. Operations Overview

| Operation | Primary MCP Action | Script Fallback (`@scripts/`) | CLI Fallback (`gh`) |
| :--- | :--- | :--- | :--- |
| **Read issue** | `get_issue` | `get_issue.sh` | `gh issue view <num> --comments` |
| **Edit/Create issue** | `issue_write` | `update_issue.sh` | `gh issue edit <num>` / `gh issue create` |
| **Add comment** | `add_issue_comment` | `add_issue_comment.sh` | `gh issue comment <num> --body "..."` |
| **List issues** | `list_issues` | `list_issues.sh` | `gh issue list` |
| **Assign Copilot** | `assign_copilot_to_issue` | `assign_copilot_to_issue.sh` | `gh issue edit <num> --add-assignee github-copilot[bot]` |
| **Add sub-issue** | `sub_issue_write` | `update_sub_issue.sh` | `gh api -X POST repos/{owner}/{repo}/issues/{num}/sub_issues` |
| **List issue types** | `list_issue_types` | `list_issue_types.sh` | `gh api repos/{owner}/{repo}/issues/types` |
| **List issue fields**| `list_issue_fields`| `list_issue_fields.sh` | `gh api repos/{owner}/{repo}/issues/fields` |

---

## 2. Execute via Scripts

### Read an Issue
```bash
# Auto-detected repository
bash @scripts/get_issue.sh --issue-number 42

# Explicit owner and repo override
bash @scripts/get_issue.sh --owner octocat --repo hello-world --issue-number 10
```

### Create / Edit an Issue
```bash
# Edit issue on auto-detected repository
bash @scripts/update_issue.sh --issue-number 42 --title "Bug: connection retry failed" --body "Steps to reproduce..."

# Edit issue on explicit repository
bash @scripts/update_issue.sh --owner octocat --repo hello-world --issue-number 10 --title "Updated title" --body "Updated description"
```
> For CLI creation with `--body-file`:
> ```bash
> gh issue create --title "Issue title" --body-file "tmp_body.md" --label "bug" && rm "tmp_body.md"
> ```

### Add Issue Comment
```bash
# Auto-detected repository
bash @scripts/add_issue_comment.sh --issue-number 42 --body "Fixed in commit abc1234."

# Explicit repository override
bash @scripts/add_issue_comment.sh --owner octocat --repo hello-world --issue-number 10 --body "Investigating now."
```

### List Issues
```bash
# Auto-detected repository
bash @scripts/list_issues.sh

# Explicit repository
bash @scripts/list_issues.sh --owner octocat --repo hello-world
```

### Assign Copilot to Issue
```bash
# Auto-detected repository
bash @scripts/assign_copilot_to_issue.sh --issue-number 42

# Explicit repository override
bash @scripts/assign_copilot_to_issue.sh --owner octocat --repo hello-world --issue-number 10
```

### Manage Sub-Issues (Issue Hierarchy)
```bash
# Auto-detected repository
bash @scripts/update_sub_issue.sh --issue-number 42 --sub-issue-id 12345678

# Explicit repository override
bash @scripts/update_sub_issue.sh --owner octocat --repo hello-world --issue-number 10 --sub-issue-id 12345678
```

### Discover Issue Types & Fields
```bash
# Auto-detected repository
bash @scripts/list_issue_types.sh
bash @scripts/list_issue_fields.sh

# Explicit repository override
bash @scripts/list_issue_types.sh --owner octocat --repo hello-world
bash @scripts/list_issue_fields.sh --owner octocat --repo hello-world
```
