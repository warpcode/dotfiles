# GitHub Releases & Tags

Query, view, create, and manage GitHub releases and release assets.

---

## Operations Overview

| Operation | Risk Level | Primary MCP Action | CLI Fallback (`gh`) |
| :--- | :--- | :--- | :--- |
| **List releases** | Read-Only | `list_releases` | `gh release list` |
| **Get latest release** | Read-Only | `get_latest_release` | `gh release view` |
| **Get release by tag** | Read-Only | `get_release_by_tag` | `gh release view <tag>` |
| **Create release** | Mutating (Write) | N/A (`gh release`) | `gh release create <tag> --draft` |
| **Download assets** | Read-Only | N/A (`gh release`) | `gh release download <tag>` |

---

## 1. Query Releases

### List Releases
```bash
# Auto-detected repository
gh release list --limit 20

# Explicit repository override
gh release list --repo octocat/hello-world
```

### Get Latest Release
```bash
# Auto-detected repository
gh release view

# Explicit repository override
gh release view --repo octocat/hello-world
```

### Get Release by Tag
```bash
# Auto-detected repository
gh release view "v1.2.0"

# Explicit repository override
gh release view "v1.2.0" --repo octocat/hello-world
```

---

## 2. Create and Manage Releases

> [!IMPORTANT]
> Always ask for explicit user approval before publishing a release. Present the tag, title, and release notes draft first.

### Create a Release (Draft first)
```bash
gh release create "v1.2.0" \
  --title "v1.2.0 Release Title" \
  --notes-file "release_notes.md" \
  --draft
```

### Download Release Assets
```bash
gh release download "v1.2.0" --pattern "*.tar.gz" --dir "./dist"
```
