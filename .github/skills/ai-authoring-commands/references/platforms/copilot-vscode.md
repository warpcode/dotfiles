# VS Code & GitHub Copilot Prompt Files Reference

Source: <https://code.visualstudio.com/docs/agent-customization/prompt-files>

Prompt Files (`*.prompt.md`) in VS Code and GitHub Copilot are parameterized Markdown files that define reusable prompts, commands, and chained handoffs across development tasks.

---

## 1. Discovery Paths & Invocation

### File Locations
- **Workspace (Shared via Git)**: `<project-root>/.github/prompts/<name>.prompt.md` (Standard / Recommended)
- **Workspace (Custom)**: Configured in `.vscode/settings.json` via `"chat.promptFilesLocations"` (e.g. `".vscode/prompts"`).
- **User / Global**: OS User Data directory (e.g. `~/.config/Code/User/prompts/` or managed in the Agent Customizations Editor).

### Invocation & Naming
- The file basename minus `.prompt.md` becomes the slash command trigger (e.g. `review.prompt.md` $\rightarrow$ `/review`).
- Can also be triggered via the Chat prompt file picker.

---

## 2. YAML Frontmatter Schema

```yaml
---
name: string                   # Optional: override slash command identifier
description: string            # Summary shown in prompt picker and autocomplete
argument-hint: string          # Placeholder hint shown in chat input box
agent: string                  # Chat agent mode (ask, plan, edit, agent, or custom agent)
model: string | string[]       # Target model or prioritized fallback list (e.g. [claude-3.5-sonnet, gpt-4o])
tools: string[]                # Whitelist of tool identifiers (e.g. [codebase, terminal, fetch, github/*])
target: string                 # Optional environment specifier (e.g. vscode)
handoffs:                      # Interactive button transitions presented upon completion
  - label: string              # Button text displayed in chat UI (required)
    agent: string              # Target agent mode or custom agent (required)
    prompt: string             # Pre-filled prompt instructions for the next agent (required)
    send: boolean              # true = auto-execute; false = pre-fill for user review
    model: string              # Optional model override for next step
---
```

---

## 3. Dynamic Variables & Context References

### Interactive Input Variables
- `${input:variableName}`: Opens an input dialog asking the user for `variableName`.
- `${input:variableName:placeholder}`: Displays an input box with a customized placeholder.

### Editor & Selection Variables
- `${selection}`: Injects the active text selection from the open editor.
- `${file}`: Injects the path/content of the active file.
- `${file:path/to/file}`: Injects specific file contents from the workspace.
- `${command:commandId}`: Runs a VS Code command and embeds output into the prompt.

### Copilot Context References (`#...`)
- `#file:path/to/file`: Mentions and attaches specific workspace file.
- `#codebase` / `#workspace`: Injects repository semantic search context.
- `#changes` / `#diff`: Injects working tree / git diff context.
- `#terminal` / `#terminalSelection`: Injects terminal output buffer.

---

## 4. Handoffs & Multi-Stage Chaining

Handoffs enable multi-step workflows with human review gates. Upon prompt completion, Copilot renders buttons for the defined handoff targets:
- `send: false`: Pre-fills the next prompt into the chat box, enabling developer inspection before sending.
- `send: true`: Automatically triggers the downstream prompt upon button click.
