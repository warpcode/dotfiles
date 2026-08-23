# Cursor Custom Agent Reference

Source: <https://cursor.com/docs/agent-customization>

## Locations & Discovery

- Project-level: `.cursor/agents/<name>.md`
- Scoped rules: `.cursor/rules/<name>.mdc`
- Global: `~/.cursor/agents/<name>.md`

## Recognized Frontmatter Options

| Key | Type | Default | Description |
|---|---|---|---|
| `name` | string | filename | Agent title |
| `description` | string | **Required** | Trigger conditions and capabilities summary |
| `model` | string | user default | Pinned model (e.g. `claude-3-5-sonnet`, `gpt-4o`) |
| `tools` | list | all permitted | Allowlist of tools available to this agent |
| `paths` | list | none | File glob patterns restricting when this agent/rule applies |

## Example Frontmatter

```yaml
---
name: Database Migration Specialist
description: Generates, verifies, and audits database schemas and migration scripts.
model: claude-3-5-sonnet
tools:
  - read_file
  - edit_file
  - run_terminal_command
paths:
  - "database/migrations/**"
  - "db/**"
  - "prisma/schema.prisma"
---
```
