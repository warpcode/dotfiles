# GitHub Repository & Content Operations

Manage remote repository content, files, branches, tags, commits, collaborators, and repository settings via the GitHub platform.

> [!NOTE]
> This reference covers **remote GitHub API** operations. For local git workspace actions (such as local staging, local rebases, git worktree manipulation, and local commit creation), refer to `git-expert`.

---

## Operations Overview

| Operation | Risk Level | Primary MCP Action | Script Fallback (`${SKILL_DIR}/scripts/`) |
| :--- | :--- | :--- | :--- |
| **Get file contents** | Read-Only | `get_file_contents` | `get_file_contents.sh` |
| **Create/update file** | Mutating (Write) | `create_or_update_file` | `create_or_update_file.sh` |
| **Delete file** | Mutating (Destructive)| `delete_file` | `delete_file.sh` |
| **Push multiple files** | Mutating (Write) | `push_files` | `push_files.sh` |
| **List branches** | Read-Only | `list_branches` | `list_branches.sh` |
| **Create branch** | Mutating (Write) | `create_branch` | `create_branch.sh` |
| **Get / List tags** | Read-Only | `get_tag`, `list_tags` | `get_tag.sh`, `list_tags.sh` |
| **Get / List commits** | Read-Only | `get_commit`, `list_commits` | `get_commit.sh`, `list_commits.sh` |
| **List collaborators** | Read-Only | `list_repository_collaborators`| `list_repository_collaborators.sh` |
| **Create repository** | Mutating (Write) | `create_repository` | `create_repository.sh` |
| **Fork repository** | Mutating (Write) | `fork_repository` | `fork_repository.sh` |

---

## 1. Remote File Operations

### Get File Contents
Fetch remote file content without checking out the branch:
```bash
bash ${SKILL_DIR}/scripts/get_file_contents.sh --path "path/to/file.txt" --branch "main" [--owner <owner>] [--repo <repo>]
```

### Create or Update a Single Remote File
```bash
# 1. Create a brand new file (no --sha required)
bash ${SKILL_DIR}/scripts/create_or_update_file.sh \
  --path "docs/guide.md" \
  --message "docs: create user guide" \
  --content "<base64_encoded_content>" \
  --branch "feature-branch"

# 2. Update an existing file (passing optional --sha)
bash ${SKILL_DIR}/scripts/create_or_update_file.sh \
  --path "docs/guide.md" \
  --message "docs: update user guide" \
  --content "<base64_encoded_content>" \
  --branch "feature-branch" \
  --sha "3a4b5c6d..." \
  --owner "octocat" \
  --repo "custom-repo"
```

### Delete a Single Remote File
```bash
bash ${SKILL_DIR}/scripts/delete_file.sh \
  --path "path/to/file.txt" \
  --message "chore: remove obsolete file" \
  --branch "feature-branch" \
  --sha "<file_sha>" \
  [--owner <owner>] [--repo <repo>]
```

---

## 2. Remote Branches & Tags

### List Branches
```bash
bash ${SKILL_DIR}/scripts/list_branches.sh [--owner <owner>] [--repo <repo>]
```

### Create a Remote Branch
Create a branch pointing directly to a specific commit SHA:
```bash
bash ${SKILL_DIR}/scripts/create_branch.sh --branch "new-feature" --sha "<commit_sha>" [--owner <owner>] [--repo <repo>]
```

### List and Inspect Tags
```bash
# List all tags
bash ${SKILL_DIR}/scripts/list_tags.sh [--owner <owner>] [--repo <repo>]

# Get specific tag ref
bash ${SKILL_DIR}/scripts/get_tag.sh --tag "<tag_name>" [--owner <owner>] [--repo <repo>]
```

---

## 3. Remote Commits

### Get Commit Details
```bash
bash ${SKILL_DIR}/scripts/get_commit.sh --sha "<commit_sha>" [--owner <owner>] [--repo <repo>]
```

### List Commits
```bash
bash ${SKILL_DIR}/scripts/list_commits.sh [--owner <owner>] [--repo <repo>]
```

---

## 4. Repository Administration & Collaborators

### List Collaborators
```bash
bash ${SKILL_DIR}/scripts/list_repository_collaborators.sh [--owner <owner>] [--repo <repo>]
```

### Create Repository
```bash
# Minimal private repository (default)
bash ${SKILL_DIR}/scripts/create_repository.sh --name "my-new-repo"

# Public repository with optional description
bash ${SKILL_DIR}/scripts/create_repository.sh --name "my-open-source-tool" --description "A CLI tool for developers" --public true
```

### Fork Repository
```bash
# Fork the currently auto-detected repository
bash ${SKILL_DIR}/scripts/fork_repository.sh

# Fork a specific external repository
bash ${SKILL_DIR}/scripts/fork_repository.sh --owner upstream-org --repo project-template
```
