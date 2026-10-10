# GitHub Repository & Content Operations

Manage remote repository content, files, branches, tags, commits, collaborators, and repository settings via the GitHub platform.

> [!NOTE]
> This reference covers **remote GitHub API** operations. For local git workspace actions (such as local staging, local rebases, git worktree manipulation, and local commit creation), refer to `git-expert`.

---

## Operations Overview

| Operation | Risk Level | Primary MCP Action | CLI Fallback (`gh`) |
| :--- | :--- | :--- | :--- |
| **Get file contents** | Read-Only | `get_file_contents` | `gh api repos/{owner}/{repo}/contents/{path}` |
| **Create/update file** | Mutating (Write) | `create_or_update_file` | `gh api -X PUT repos/{owner}/{repo}/contents/{path}` |
| **Delete file** | Mutating (Destructive)| `delete_file` | `gh api -X DELETE repos/{owner}/{repo}/contents/{path}` |
| **List branches** | Read-Only | `list_branches` | `git branch -r` or `gh api repos/{owner}/{repo}/branches` |
| **Create branch** | Mutating (Write) | `create_branch` | `git checkout -b <branch>` or `gh api -X POST repos/{owner}/{repo}/git/refs` |
| **Get / List tags** | Read-Only | `get_tag`, `list_tags` | `git tag` or `gh api repos/{owner}/{repo}/tags` |
| **Get / List commits** | Read-Only | `get_commit`, `list_commits` | `git log` or `gh api repos/{owner}/{repo}/commits` |
| **List collaborators** | Read-Only | `list_repository_collaborators`| `gh api repos/{owner}/{repo}/collaborators` |
| **Create repository** | Mutating (Write) | `create_repository` | `gh repo create` |
| **Fork repository** | Mutating (Write) | `fork_repository` | `gh repo fork` |

---

## 1. Remote File Operations

### Get File Contents
Fetch remote file content without checking out the branch:
```bash
gh api repos/<owner>/<repo>/contents/<path>?ref=<branch> -H "Accept: application/vnd.github.raw"
```

### Create or Update a Single Remote File
```bash
gh api -X PUT repos/<owner>/<repo>/contents/<path> \
  -f message="docs: update guide" \
  -f content="$(base64 -w 0 < local_file.md)" \
  -f branch="feature-branch" \
  -f sha="<existing_file_sha>"
```

### Delete a Single Remote File
```bash
gh api -X DELETE repos/<owner>/<repo>/contents/<path> \
  -f message="chore: remove obsolete file" \
  -f branch="feature-branch" \
  -f sha="<file_sha>"
```

---

## 2. Remote Branches & Tags

### List Branches
```bash
gh api repos/<owner>/<repo>/branches --jq '.[].name'
```

### Create a Remote Branch
Create a branch pointing directly to a specific commit SHA:
```bash
gh api -X POST repos/<owner>/<repo>/git/refs \
  -f ref="refs/heads/new-feature" \
  -f sha="<commit_sha>"
```

### List and Inspect Tags
```bash
# List tags via API
gh api repos/<owner>/<repo>/tags --jq '.[].name'
```

---

## 3. Remote Commits

### Get Commit Details
```bash
gh api repos/<owner>/<repo>/commits/<commit_sha>
```

### List Commits
```bash
gh api repos/<owner>/<repo>/commits --jq '.[].sha'
```

---

## 4. Repository Administration & Collaborators

### List Collaborators
```bash
gh api repos/<owner>/<repo>/collaborators --jq '.[].login'
```

### Create Repository
```bash
# Create private repository
gh repo create my-new-repo --private

# Create public repository with description
gh repo create my-open-source-tool --public --description "A CLI tool for developers"
```

### Fork Repository
```bash
gh repo fork <owner>/<repo> --clone=false
```
