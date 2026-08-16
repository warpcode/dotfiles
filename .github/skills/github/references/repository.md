# GitHub Repository & Content Operations

Manage remote repository content, files, branches, tags, commits, collaborators, and repository settings via the GitHub platform.

> [!NOTE]
> This reference covers **remote GitHub API** operations. For local git workspace actions (such as local staging, local rebases, git worktree manipulation, and local commit creation), refer to `git-expert`.

---

## Operations Overview

| Operation | Risk Level | Primary MCP Action | CLI Fallback (`gh` / `gh api`) |
| :--- | :--- | :--- | :--- |
| **Get file contents** | Read-Only | `get_file_contents` | `gh api repos/{owner}/{repo}/contents/{path}?ref={ref}` |
| **Create/update file** | Mutating (Write) | `create_or_update_file` | `gh api -X PUT repos/{owner}/{repo}/contents/{path} --input payload.json` |
| **Delete file** | Mutating (Destructive)| `delete_file` | `gh api -X DELETE repos/{owner}/{repo}/contents/{path} --input payload.json` |
| **Push multiple files** | Mutating (Write) | `push_files` | GraphQL `createCommitOnBranch` |
| **List branches** | Read-Only | `list_branches` | `gh api repos/{owner}/{repo}/branches` |
| **Create branch** | Mutating (Write) | `create_branch` | `gh api -X POST repos/{owner}/{repo}/git/refs -f ref="refs/heads/{branch}" -f sha="{sha}"` |
| **Get / List tags** | Read-Only | `get_tag`, `list_tags` | `gh api repos/{owner}/{repo}/tags` |
| **Get / List commits** | Read-Only | `get_commit`, `list_commits` | `gh api repos/{owner}/{repo}/commits` / `gh api repos/{owner}/{repo}/commits/{ref}` |
| **List collaborators** | Read-Only | `list_repository_collaborators`| `gh api repos/{owner}/{repo}/collaborators` |
| **Create repository** | Mutating (Write) | `create_repository` | `gh repo create <name> [--public/--private]` |
| **Fork repository** | Mutating (Write) | `fork_repository` | `gh repo fork <owner>/<repo> [--clone=false]` |

---

## 1. Remote File Operations

### Get File Contents
Fetch remote file content without checking out the branch:
```bash
# Get metadata + base64 content
gh api repos/{owner}/{repo}/contents/{path}?ref={branch_or_sha}

# Or use the helper script for decoded stdout:
bash ${SKILL_DIR}/scripts/fetch_file.sh <owner> <repo> <path> <branch>
```

### Create or Update a Single Remote File
Creates or updates a file directly on a remote branch via the GitHub REST API:
1. Fetch the existing file SHA (if updating):
   ```bash
   FILE_SHA=$(gh api repos/{owner}/{repo}/contents/{path}?ref={branch} --jq .sha 2>/dev/null || true)
   ```
2. Prepare the JSON payload:
   ```json
   {
     "message": "docs: update README with API instructions",
     "content": "<base64-encoded-content>",
     "branch": "feature-branch",
     "sha": "<existing-sha-if-updating>"
   }
   ```
3. Execute:
   ```bash
   gh api -X PUT repos/{owner}/{repo}/contents/{path} --input payload.json
   ```

### Delete a Single Remote File
```json
{
  "message": "chore: remove obsolete config",
  "sha": "<file-sha>",
  "branch": "feature-branch"
}
```
```bash
gh api -X DELETE repos/{owner}/{repo}/contents/{path} --input payload.json
```

### Push Multiple Files (Atomic Commit via GraphQL)
To commit multiple files atomically without local git checkout, use GitHub's GraphQL `createCommitOnBranch` mutation:
```graphql
mutation CreateCommit($input: CreateCommitOnBranchInput!) {
  createCommitOnBranch(input: $input) {
    commit {
      oid
      url
    }
  }
}
```
Input structure:
```json
{
  "input": {
    "branch": {
      "repositoryNameWithOwner": "owner/repo",
      "branchName": "feature-branch"
    },
    "expectedHeadOid": "<current_head_oid>",
    "message": { "headline": "feat: add multiple configuration files" },
    "fileChanges": {
      "additions": [
        { "path": "config/app.json", "contents": "<base64_encoded_content>" }
      ],
      "deletions": [
        { "path": "config/legacy.json" }
      ]
    }
  }
}
```

---

## 2. Remote Branches & Tags

### List Branches
```bash
gh api repos/{owner}/{repo}/branches --paginate --jq '.[].name'
```

### Create a Remote Branch
Create a branch pointing directly to a specific commit SHA:
```bash
gh api -X POST repos/{owner}/{repo}/git/refs \
  -f ref="refs/heads/new-feature" \
  -f sha="6dcb09b5b57875f334f61aebed695e2e4193db5e"
```

### List and Inspect Tags
```bash
# List tags
gh api repos/{owner}/{repo}/tags --jq '.[].name'

# Get specific tag ref
gh api repos/{owner}/{repo}/git/ref/tags/{tag_name}
```

---

## 3. Remote Commits

### Get Commit Details
```bash
gh api repos/{owner}/{repo}/commits/{commit_sha}
```

### List Commits
```bash
# List recent commits on a branch or PR
gh api repos/{owner}/{repo}/commits?sha={branch}&per_page=30

# Filter commits by author or path
gh api "repos/{owner}/{repo}/commits?author={username}&path={file_path}"
```

---

## 4. Repository Administration & Collaborators

### List Collaborators
```bash
gh api repos/{owner}/{repo}/collaborators --jq '.[] | {login: .login, role: .role_name}'
```

### Create Repository
```bash
# Interactive / scripted repository creation
gh repo create {owner}/{repo_name} --private --description "Project description"
```

### Fork Repository
```bash
# Fork to authenticated user's namespace without cloning locally
gh repo fork {owner}/{repo} --clone=false
```
