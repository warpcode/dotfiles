# GitHub Copilot & VS Code Custom Agent Reference

Source: <https://code.visualstudio.com/docs/agent-customization/custom-agents>

## Locations & Discovery

- Workspace-scoped: `.github/agents/<name>.agent.md`
- Personal/User-scoped: `~/.copilot/agents/<name>.agent.md` or paths configured in `chat.agentFilesLocations`
- Extension-contributed agents: packaged via VS Code extension manifest

Files must use the `.agent.md` double extension for discovery by Copilot and VS Code agent pickers.

## Recognized Frontmatter Options

| Key | Type | Default | Description |
|---|---|---|---|
| `name` | string | filename | Display title shown in agent dropdown pickers and typeahead |
| `description` | string | **Required** | Detailed description of the agent's role, used for agent discovery, picker search, and autonomous subagent delegation |
| `model` | string / list | user default | Pinned model or ordered fallback array (e.g. `["Claude Sonnet 3.5 (copilot)", "GPT-4o (copilot)"]`) |
| `tools` | list | all permitted | Allowlist of built-in VS Code tools and MCP tools (supports exact names and wildcard prefixes like `github/*`, `figma-dev-mode-mcp-server`) |
| `user-invocable` | boolean | `true` | `true` shows the agent in chat `@` autocomplete; `false` reserves it for programmatic subagent invocation |
| `agents` | list | all | Allowlist of other custom agents this agent is permitted to delegate to |
| `target` | string | `vscode` | Target host environment (`vscode` or `github-copilot`) |
| `handoffs` | list | none | List of suggested follow-up agents presented in the UI upon completion |
| `argument-hint` | string | none | Parameter placeholder hint shown in chat input when `@`-mentioned |

## Built-In Tool Names & MCP Qualifiers

Common tool namespaces in VS Code / Copilot:
- File & Workspace: `read/readFile`, `edit/editFiles`, `codebase`, `search`, `vscode/newWorkspace`, `vscode/getProjectSetupInfo`
- Execution & Terminal: `execute/runInTerminal`, `execute/runTask`, `execute/runTests`, `execute/getTerminalOutput`, `read/terminalSelection`
- Web & Diagnostics: `web/fetch`, `read/problems`
- MCP Tools: `figma-dev-mode-mcp-server`, `github/*`, `context7/*`

## Example Frontmatter

### 1. Frontend Design Specialist (with MCP Tools)
```yaml
---
name: Frontend Specialist
description: Expert assistant for developing web components using Tailwind CSS, HTML/HTL, and Figma design tokens via MCP.
model:
  - Claude Sonnet 3.5 (copilot)
  - GPT-4.1
tools:
  - codebase
  - edit/editFiles
  - web/fetch
  - figma-dev-mode-mcp-server
  - read/problems
user-invocable: true
handoffs:
  - code-reviewer
---
```

### 2. Autonomous Janitor / Cleanup Agent (Non-Invocable Subagent)
```yaml
---
name: Codebase Janitor
description: Eliminates tech debt, dead code, unused imports, and unreferenced functions across the workspace.
model: GPT-4.1
tools:
  - codebase
  - edit/editFiles
  - search
  - execute/runTests
user-invocable: false
target: vscode
---
```

## System Prompt Body

The markdown body serves as the system prompt:
- State exact coding standards, architectural boundaries, and lint constraints.
- Structure guidelines with clear headings (`## Your Expertise`, `## Your Approach`, `## Guidelines`).
