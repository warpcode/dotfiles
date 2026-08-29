# Cursor Commands & Plugin Component Reference

Source: <https://cursor.com/docs/reference/plugins#cursor-plugin-component-discovery>

Cursor discovers custom commands, prompt templates, rules, agents, skills, and hooks through project directories and plugin packages.

---

## 1. Discovery Paths & Precedence

1. **Manifest Path Overrides**: If specified in `.cursor-plugin/plugin.json` (e.g. `"commands": "./custom-commands/"`), Cursor scans that directory exclusively.
2. **Project / Workspace Scope**: `<project-root>/.cursor/commands/<name>.md`
3. **Global / User Scope**: `~/.cursor/commands/<name>.md`
4. **Plugin Default Folder**: `commands/` inside installed plugins.

*Note*: Symlinks are not followed for plugin component discovery; use concrete file paths.

---

## 2. YAML Frontmatter Schema

Custom commands in `.cursor/commands/<name>.md` support YAML frontmatter:

```yaml
---
name: string                   # Optional: command name (default: filename without .md)
description: string            # Picker label and agent semantic matching trigger
argument-hint: string          # Usage hint in autocomplete (e.g. "[target-file] [options]")
user-invocable: boolean        # If false, hides from manual slash autocomplete
allowed-tools: string[]        # Tool permissions (e.g. [ReadFile, WriteFile, GrepSearch])
---
```

---

## 3. Parameter Substitution & Context Mentions

### Parameter Placeholders
- `$ARGUMENTS`: Full user argument string passed after the `/name` invocation.
- `$1`, `$2`, ..., `$n`: Positional whitespace-split arguments.
- `$SELECTION`: The currently selected text in the active editor buffer.

### Symbol `@` Context Injections
- `@File` / `@Folder`: Injects full content of file or directory tree.
- `@Codebase`: Semantic search across repository vector embeddings.
- `@Git`: Working tree diffs, branch status, or commit history.
- `@Terminal`: Captures stdout/stderr from active terminal tabs.
- `@Chat`: Mentions previous chat context or agent runs.
- `@Docs` / `@Web`: Queries indexed external documentation or performs live web search.

### Plugin Configuration Variables
- `${VAR_NAME}`: Runtime variables declared in `plugin.json` and populated securely via Cursor settings.
