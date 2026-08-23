# GitHub Copilot / VS Code skill reference

Source: <https://code.visualstudio.com/docs/agent-customization/agent-skills#_skillmd-file-format>

## Locations & discovery

- Project: `.github/skills/<name>/`, `.claude/skills/<name>/`, `.agents/skills/<name>/`
- Personal: `~/.copilot/skills/<name>/`, `~/.claude/skills/<name>/`, `~/.agents/skills/<name>/`
- Custom locations: Configured via the `chat.agentSkillsLocations` setting in VS Code `settings.json` (array of directory paths).

## Recognized frontmatter options

| Key | Required | Purpose |
|---|---|---|
| `argument-hint` | No | Hint shown in the chat input on slash invocation (e.g. `[test-file] [--coverage]`) |
| `user-invocable` | No | Default `true`; `false` hides from the `/` menu (model loads automatically) |
| `disable-model-invocation` | No | Default `false`; `true` = manual slash invocation only, prevents auto-loading |
| `context` | No | Experimental: `fork` runs the skill in a dedicated subagent session |
| `agent` | No | Target agent name when `context: fork` is active |
| `paths` | No | Glob pattern(s) scoping skill activation to matching workspace files |
| `license` | No | License identifier (e.g. `MIT`, `Apache-2.0`) |
| `compatibility` | No | Runtime, tool, and extension prerequisites (max 500 chars) |
| `metadata` | No | Key-value mapping for author, version, category, and plugin metadata |

### Frontmatter examples

**Slash command with argument hints and path scoping:**

```yaml
---
argument-hint: "[file-path] [--fix]"
user-invocable: true
disable-model-invocation: false
paths:
  - "**/*.spec.ts"
  - "**/*.test.ts"
license: MIT
compatibility: "VS Code >= 1.95, Copilot Chat extension"
metadata:
  author: testing-guild
  version: "1.3.0"
  category: testing
  plugin: test-runner
---
```

**Forked context subagent invocation:**

```yaml
---
context: fork
agent: code-explainer
disable-model-invocation: true
user-invocable: true
metadata:
  author: core-team
  version: "1.0.0"
---
```

## Platform integration & gotchas

- **Namespacing**: Extensions and plugins add namespace prefixes automatically (e.g. `/plugin-name:skill`); manual prefixes or slashes in frontmatter `name` fail silently or cause parse errors.
- **Extension contribution**: VS Code extensions contribute packaged skills via `contributes.chatSkills` in `package.json`.
- **Context variables**: Interactive prompts support VS Code variables such as `${workspaceFolder}`, `${file}`, and `${selectedText}`.
- **Multi-root workspaces**: Skills in `.github/skills/` located at the root of any open workspace folder are automatically discovered.

