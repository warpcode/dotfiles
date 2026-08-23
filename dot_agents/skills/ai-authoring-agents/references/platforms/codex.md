# ChatGPT & OpenAI Codex Subagent Reference

Source: <https://learn.chatgpt.com/docs/agent-configuration/subagents>

## Locations & Architecture

- System/Environment Config: `.codex/config.toml` or `~/.codex/config.toml` under `[agents]`
- Agent Definitions: `.codex/agents/<name>.md` or referenced from `AGENTS.md`
- Project Instructions: `AGENTS.md` (project root / directory hierarchy)

In ChatGPT and Codex environments, subagents are spun out as parallel threads to handle complex tasks (research, implementation, review) without overloading the main conversation context.

## Configuration Schemas

### 1. Markdown Agent Definition (`.codex/agents/<name>.md`)

```yaml
---
name: Codebase Explorer
description: Explores project files, symbol definitions, and dependency trees in a background subagent thread.
model: gpt-4o-mini
tools:
  - file_search
  - read_file
  - list_dir
temperature: 0.2
---
# Role & Instructions
You are a Codebase Explorer subagent. Your objective is to...
```

### 2. TOML Configuration (`config.toml`)

Subagents and roles can also be configured declaratively in `.codex/config.toml`:

```toml
[agents.researcher]
description = "Fast background codebase and web exploration"
model = "gpt-4o-mini"
tools = ["read", "search", "web"]
temperature = 0.2

[agents.reviewer]
description = "Strict PR and security review subagent"
model = "o3-mini"
tools = ["read", "diff"]
temperature = 0.1
```

## `AGENTS.md` Hierarchy & Delegation

- When project context expands, `AGENTS.md` should delegate specialized workflows to separate markdown instruction files.
- The coordinator agent references subagent personas when breaking down complex goals.
