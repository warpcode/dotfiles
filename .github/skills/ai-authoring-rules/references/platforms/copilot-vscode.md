# GitHub Copilot & VS Code Instruction Reference

Source: <https://code.visualstudio.com/docs/agent-customization/custom-instructions>

GitHub Copilot in VS Code supports project-wide instructions, hierarchical `AGENTS.md`, and path-scoped instruction files (`.instructions.md`).

---

## 1. File Locations & Discovery

| Scope | Path | Purpose |
|---|---|---|
| **Path-Scoped Instructions** | `.github/instructions/<name>.instructions.md` | Scoped guidelines attached when matching files are in context |
| **Workspace Instructions** | `.github/copilot-instructions.md` | Universal repository instructions loaded in every Copilot chat turn |
| **Nearest-Wins Instructions** | `AGENTS.md` (root or subdirectory) | Directory-scoped conventions evaluated nearest-wins |
| **User Global Instructions** | VS Code User Settings / Agent Customizations | Personal instructions applied across all local workspaces |

---

## 2. `.instructions.md` Frontmatter Schema

Rule files placed under `.github/instructions/` (subdirectories supported) must end with `.instructions.md` and use YAML frontmatter:

```markdown
---
applyTo: "**/*.php,app/**/*.php"
description: "PHP MCP server development standards using the official SDK."
excludeAgent: "cloud-agent" # optional: code-review | cloud-agent
---

# PHP Guidelines
- Use PHP 8.2+ typed properties and return types.
- Follow PSR-12 coding style.
```

### Frontmatter Fields

| Field | Type | Description |
|---|---|---|
| `applyTo` | string / list | **Required for path scoping**. Comma-separated glob string or YAML list matching target files. |
| `description` | string | Summary of the instruction set. Displayed in VS Code's Agent Customizations editor and used for instruction discovery. |
| `excludeAgent` | string | Optional. Gating flag to prevent execution by specific agents (e.g. `code-review`, `cloud-agent`). |

---

## 3. Glob Matching & Execution

- **Automatic Context Attachment**: When a user mentions a file, edits a file, or when a file matching the `applyTo` glob is included in Copilot's prompt context, VS Code automatically attaches the corresponding `.instructions.md` document.
- **Manual Attachment**: Users can attach instructions interactively using the Command Palette: `Chat: Attach Instructions...` or the gear icon in the Chat view.
- **Subdirectory Organization**: Files can be organized into subdirectories (e.g. `.github/instructions/backend/database.instructions.md`, `.github/instructions/frontend/react.instructions.md`).

---

## 4. Best Practices

- **Filename Standard**: Filename must match `[a-z0-9-]+.instructions.md`. Plain `.md` without `.instructions.md` will not be recognized as a scoped instruction file.
- **Specificity**: Keep `applyTo` globs as narrow as possible (e.g. `tests/**/*.spec.ts` rather than `**/*`).
- **Verifiable Rules**: Focus on concrete rules (naming, error handling, forbidden patterns) rather than broad commentary.
