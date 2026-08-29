# Cursor Rules Reference

Source: <https://cursor.com/docs/rules>

Cursor uses `.mdc` files in `.cursor/rules/` to define modular, project-specific rules that provide persistent context to the AI.

---

## 1. File Locations & Extension Requirement

| Location | Format | Purpose |
|---|---|---|
| `.cursor/rules/<name>.mdc` | Markdown + YAML Frontmatter | Project-specific modular rules |
| `.cursorrules` (repo root) | Plain Markdown | Legacy project-wide rules (applies to all sessions) |
| Settings > User Rules | Text / Markdown | Global rules across all workspaces |

> [!WARNING]
> **File Extension Requirement**: Rule files inside `.cursor/rules/` **must** have the `.mdc` extension. Plain `.md` files in `.cursor/rules/` are completely ignored by Cursor.

---

## 2. `.mdc` Frontmatter Schema

Every `.mdc` file starts with YAML frontmatter enclosed in `---`:

```yaml
---
description: "TypeScript and NestJS API conventions"
globs: "src/api/**/*.ts"
alwaysApply: false
---
```

### Frontmatter Fields

| Field | Type | Default | Description |
|---|---|---|---|
| `description` | string | `""` | Short summary of what the rule covers. Used by Cursor's AI to assess relevance in intelligent routing mode. |
| `globs` | string / list | `""` | Comma-separated string or YAML array of glob patterns matching files to attach the rule to. |
| `alwaysApply` | boolean | `false` | When `true`, rule is injected into the system prompt for every interaction regardless of files edited. |

---

## 3. Activation Behavior Matrix

The combination of frontmatter fields determines exactly when Cursor activates a rule:

| `alwaysApply` | `description` | `globs` | Trigger Behavior |
|---|---|---|---|
| `true` | — | — | **Always Active**: Injected into every chat session and composer interaction. |
| `false` | — | Set | **Auto-Attach on Match**: Injected automatically when a matching file is in context or active tab. |
| `false` | Set | — | **Apply Intelligently**: Cursor's agent reads description and dynamically pulls rule if relevant to user intent. |
| `false` | — | — | **Manual Only**: Attached only when explicitly `@-mentioned` in chat (e.g. `@typescript-rules`). |

---

## 4. Best Practices & Token Economy

- **Keep Rules Focused**: Split rules into small, domain-specific `.mdc` files (e.g. `react-hooks.mdc`, `prisma-migrations.mdc`) rather than one massive file.
- **Budget Ceiling**: Keep rule files under **500 lines**.
- **Avoid Overusing `alwaysApply: true`**: Every line of an always-applied rule consumes context tokens on every single turn. Prefer `globs` or intelligent application.
