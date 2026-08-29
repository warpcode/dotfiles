# OpenAI Codex & ChatGPT skill reference

Source: <https://learn.chatgpt.com/docs/build-skills>

## Locations & discovery

- Project: `.codex/skills/<name>/`, `.agents/skills/<name>/`
- User: `~/.codex/skills/<name>/`, `~/.agents/skills/<name>/SKILL.md`

## Recognized frontmatter options

| Key | Required | Purpose |
|---|---|---|
| `license` | No | License identifier (e.g. `MIT`, `Apache-2.0`) or path to bundled file |
| `compatibility` | No | Environment, runtime, OS, and tool prerequisites (max 500 chars) |
| `allowed-tools` | No | List of required or pre-approved tool capabilities (e.g. `python`, `bash`, `browser`) |
| `metadata` | No | Arbitrary string-to-string map for packaging, versioning, author, category, or plugin tags |

Unknown frontmatter keys are safely ignored by the parser without failing.

### Frontmatter example

```yaml
---
license: Apache-2.0
compatibility: "python >= 3.11, nodejs >= 20"
allowed-tools:
  - python
  - bash
  - browser
metadata:
  author: data-science-team
  version: "1.1.0"
  category: analytics
  plugin: tabular-analysis
  tags: data, pandas, plotting
---
```

## Conventions & structure

- Follows the agentskills.io open standard.
- The `metadata` map commonly carries `author`, `version`, `category`, and `plugin` identifiers when packaged or distributed.
- Standard directory layout:
  - `scripts/`: Executable helper tools (agents learn invocation via `--help`).
  - `@references/`: Detailed documentation and reference manuals loaded on demand.
  - `assets/` / `templates/`: Boilerplate code, prompt templates, and structured output templates.

