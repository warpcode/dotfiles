# GitHub Issues

Execution commands for managing GitHub issues: create, update, query, comment, and triage.

## 1. Operations Overview

| Operation | Primary MCP Action | CLI Fallback (`gh`) |
| :--- | :--- | :--- |
| **Read issue** | `get_issue` | `gh issue view <num> --comments` |
| **Create issue** | `issue_write` | `gh issue create --title "..." --body-file "..."` |
| **Edit issue** | `issue_write` | `gh issue edit <num> --title "..." --body-file "..."` |
| **Add comment** | `add_issue_comment` | `gh issue comment <num> --body-file "..."` |
| **List issues** | `list_issues` | `gh issue list` |
| **Assign Copilot** | `assign_copilot_to_issue` | `gh issue edit <num> --add-assignee github-copilot[bot]` |
| **Add sub-issue** | `sub_issue_write` | `gh api -X POST repos/{owner}/{repo}/issues/{num}/sub_issues` |
| **List issue types** | `list_issue_types` | `gh api repos/{owner}/{repo}/issues/types` |
| **List issue fields**| `list_issue_fields`| `gh api repos/{owner}/{repo}/issues/fields` |

---

## 2. Execute via `gh` CLI

### Read an Issue
```bash
# Auto-detected repository
gh issue view 42 --comments

# Explicit owner and repo override
gh issue view 10 --repo octocat/hello-world --comments
```

### Create / Edit an Issue
```bash
# Create an issue (always write body to a file first)
gh issue create --title "Bug: connection retry failed" --body-file issue_body.md --label "bug"

# Edit issue on auto-detected repository
gh issue edit 42 --title "Bug: connection retry failed" --body-file issue_body.md

# Edit issue on explicit repository
gh issue edit 10 --repo octocat/hello-world --title "Updated title"
```

### Add Issue Comment
```bash
# Auto-detected repository
gh issue comment 42 --body-file comment.md

# Explicit repository override
gh issue comment 10 --repo octocat/hello-world --body-file comment.md
```

### List Issues
```bash
# Auto-detected repository
gh issue list --state open --limit 30

# Explicit repository with label filter
gh issue list --repo octocat/hello-world --label "bug" --state open
```

### Assign Copilot to Issue
```bash
# Auto-detected repository
gh issue edit 42 --add-assignee github-copilot[bot]

# Explicit repository override
gh issue edit 10 --repo octocat/hello-world --add-assignee github-copilot[bot]
```

### Manage Sub-Issues (Issue Hierarchy)
```bash
# Add sub-issue via GitHub API
gh api -X POST repos/{owner}/{repo}/issues/42/sub_issues -f sub_issue_id=12345678
```

### Discover Issue Types & Fields
```bash
# Discover configured issue types and custom fields
gh api repos/{owner}/{repo}/issues/types
gh api repos/{owner}/{repo}/issues/fields
```
