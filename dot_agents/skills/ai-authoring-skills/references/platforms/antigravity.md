# Antigravity skill reference

Source: <https://antigravity.google/docs/skills/>

## Locations & discovery

- Workspace / Project: `<root>/.agents/skills/<name>/` (also supports legacy `.agent/skills/`, `_agents/skills/`, `_agent/skills/`). Discovered hierarchically by walking up from the current working directory to the repository root.
- Global / User: `~/.gemini/config/skills/<name>/`, `~/.agents/skills/<name>/`.
- Plugin bundles: `plugins/<plugin-name>/skills/<name>/` (workspace or global plugins).
- Declarative JSON registration: `skills.json` and `plugins.json` in workspace or `~/.gemini/config/` allow registering skills stored in arbitrary or external paths.

## Loading priority & precedence

1. **Workspace Project**: Hierarchical discovery walking from CWD up to repository root.
2. **Workspace Declared Configurations**: Registered in workspace `skills.json` or `plugins.json`.
3. **Global Discovery**: `~/.gemini/config/skills/`, `~/.agents/skills/`.
4. **Built-in Customizations**: Default skills bundled with the application.
5. **Global Declared Configurations**: Registered in `~/.gemini/config/skills.json`.

## Recognized frontmatter options

| Key | Required | Purpose |
|---|---|---|
| `license` | No | License identifier (e.g. `MIT`, `Apache-2.0`) or path to bundled file |
| `compatibility` | No | Environment, runtime, OS, and tool prerequisites (max 500 chars) |
| `metadata` | No | Key-value mapping for versioning, author, category, or plugin tags |

Unknown frontmatter keys are safely ignored by the parser without failing.

### Frontmatter example

```yaml
---
license: Apache-2.0
compatibility: "linux, macos; requires docker and python >= 3.10"
metadata:
  author: platform-team
  version: "1.2.0"
  category: deployment
  plugin: devops-tools
  tags: ci, docker, aws
---
```

## Agent & subagent integration

- **Skill allowlisting / scoping**: Custom subagents and declarative agents (in `.agents/agents/*.md` or `plugin.json`) can restrict available skills via the `skills` allowlist/denylist field (e.g. `skills: ["git-expert", "shell-scripting"]` or `skills: []` to disable all skills).
- **Progressive disclosure**: Only skill metadata is injected during initial planning; full `SKILL.md` body is loaded on demand upon activation.
- **Deduplication**: Customizations are deduplicated by resolved canonical file paths; a skill is never injected multiple times in a single turn.

## Bundled resources

- `scripts/`: Executable helper utilities and scripts (agents learn flags via `--help`, never read source before running).
- `references/`: Detailed reference documentation and deep-dive manuals loaded on demand.
- `examples/`: Reference implementations and test fixtures.
- `resources/` / `templates/`: Assets, prompt templates, and structured output templates.

