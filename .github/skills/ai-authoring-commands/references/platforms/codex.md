# OpenAI Codex & ChatGPT Workspace Prompts Reference

Source: <https://learn.chatgpt.com/docs/build-skills>

OpenAI Codex CLI and ChatGPT workspace environments support parameterized Markdown prompt templates and commands alongside `agentskills.io` packages.

---

## 1. Locations & Invocation

### Discovery Paths
- **Project Scope**: `<project-root>/.codex/prompts/<name>.md` or `.codex/commands/<name>.md`
- **Global / User Scope**: `~/.codex/prompts/<name>.md` or `~/.codex/commands/<name>.md`

### Invocation
- Invoked via `/<name>` or `/prompts:<name>`.

---

## 2. Frontmatter Schema

```yaml
---
description: string            # Single-line summary for slash command picker
argument-hint: string          # Usage hint (e.g. "[BRANCH=main] [FOCUS=security]")
allowed-tools: string[]        # Pre-approved tool list (e.g. [bash, python, browser])
---
```

---

## 3. Parameter Placeholders & Syntax

- `$ARGUMENTS`: Complete argument string supplied after the command name.
- `$1` through `$9`: Positional arguments passed to the command.
- `$UPPERCASE_NAME` (e.g. `$BRANCH`, `$FOCUS`): Named placeholders populated when passed as `KEY=value` on the command line or prompted interactively.
- `$$`: Escapes a literal dollar sign (`$`).
