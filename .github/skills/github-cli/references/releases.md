# GitHub Releases & Tags

Query, view, create, and manage GitHub releases and release assets.

---

## Operations Overview

| Operation | Risk Level | Primary MCP Action | Script Fallback (`${SKILL_DIR}/scripts/`) | CLI Fallback (`gh`) |
| :--- | :--- | :--- | :--- | :--- |
| **List releases** | Read-Only | `list_releases` | `list_releases.sh` | `gh release list` |
| **Get latest release** | Read-Only | `get_latest_release` | `get_latest_release.sh` | `gh release view` |
| **Get release by tag** | Read-Only | `get_release_by_tag` | `get_release_by_tag.sh` | `gh release view <tag>` |
| **Create release** | Mutating (Write) | N/A (`gh release`) | N/A | `gh release create <tag> --draft` |
| **Download assets** | Read-Only | N/A (`gh release`) | N/A | `gh release download <tag>` |

---

## 1. Query Releases

### List Releases
```bash
# Auto-detected repository
bash ${SKILL_DIR}/scripts/list_releases.sh

# Explicit repository override
bash ${SKILL_DIR}/scripts/list_releases.sh --owner octocat --repo hello-world
```

### Get Latest Release
```bash
# Auto-detected repository
bash ${SKILL_DIR}/scripts/get_latest_release.sh

# Explicit repository override
bash ${SKILL_DIR}/scripts/get_latest_release.sh --owner octocat --repo hello-world
```

### Get Release by Tag
```bash
# Auto-detected repository
bash ${SKILL_DIR}/scripts/get_release_by_tag.sh --tag "v1.2.0"

# Explicit repository override
bash ${SKILL_DIR}/scripts/get_release_by_tag.sh --owner octocat --repo hello-world --tag "v1.2.0"
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
