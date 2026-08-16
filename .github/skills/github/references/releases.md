# GitHub Releases & Tags

Query, view, create, and manage GitHub releases and release assets.

---

## Operations Overview

| Operation | Risk Level | Primary MCP Action | CLI Fallback (`gh` / `gh api`) |
| :--- | :--- | :--- | :--- |
| **List releases** | Read-Only | `list_releases` | `gh release list --limit 30` |
| **Get latest release** | Read-Only | `get_latest_release` | `gh release view --json tagName,name,body,url,publishedAt` |
| **Get release by tag** | Read-Only | `get_release_by_tag` | `gh release view <tag> --json ...` |
| **Create release** | Mutating (Write) | N/A (`gh release`) | `gh release create <tag> --title "..." --notes-file ...` |
| **Download assets** | Read-Only | N/A (`gh release`) | `gh release download <tag> -p "*.tar.gz"` |

---

## 1. Query Releases

### List Releases
```bash
# List all releases in table format
gh release list --limit 30

# Output structured JSON
gh release list --limit 30 --json tagName,name,isDraft,isPrerelease,publishedAt
```

### Get Latest Release
```bash
# Formatted view in terminal
gh release view

# Retrieve full metadata and release notes
gh release view --json tagName,name,body,assets,publishedAt,url
```

### Get Release by Tag
```bash
# View release details for a specific tag
gh release view "v1.2.0" --json tagName,name,body,assets,createdAt,url
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

### Publish an Existing Draft Release
```bash
gh release edit "v1.2.0" --draft=false
```

### Download Release Assets
```bash
# Download all assets for a tag into the current directory
gh release download "v1.2.0"

# Download specific matching assets
gh release download "v1.2.0" --pattern "*.tar.gz" --dir /tmp/assets/
```
