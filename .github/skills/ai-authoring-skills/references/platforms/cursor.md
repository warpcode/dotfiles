# Cursor skill reference

Source: <https://cursor.com/docs/skills>

## Locations & discovery

- Project: `.cursor/skills/<name>/`, `.agents/skills/<name>/`
- User: `~/.cursor/skills/<name>/`, `~/.agents/skills/<name>/`
- Compatibility loading: Discovers skills in project and user `.claude/skills/` and `.codex/skills/`.
- Recursive discovery: Skill roots are walked recursively — category subfolders are organizational only; skill identity is defined by the folder directly containing `SKILL.md`.

## Recognized frontmatter options

| Key | Required | Purpose |
|---|---|---|
| `paths` | No | Glob patterns (string or list) restricting auto-activation to matching workspace files |
| `globs` | No | Legacy/alternative alias for `paths` (string or list of globs) |
| `disable-model-invocation` | No | `true` = manual slash invocation only (`/skill-name`), model cannot auto-trigger |
| `user-invocable` | No | `false` = hidden from slash command autocomplete menu (model-only auto-activation) |
| `alwaysApply` | No | `true` = skill instructions are always injected into the agent's context window |
| `icon` | No | Badge icon identifier when backing a Custom Mode (e.g. `beaker`, `rocket`, `bug`, `shield`, `terminal`, `sparkle`, `zap`, `book`, `code`, `gear`, `file`, `globe`, `search`) |
| `color` | No | Badge color theme: `default`, `green`, `cyan`, `blue`, `purple`, `magenta`, `orange`, `yellow`, `red`, `brand` |
| `license` | No | License identifier (agentskills.io open standard) |
| `compatibility` | No | Environment, runtime, and tool prerequisites |
| `metadata` | No | Arbitrary key-value mapping |

### Frontmatter examples

**Scoped guidelines with path matching:**

```yaml
---
paths:
  - "src/components/**/*.tsx"
  - "styles/**/*.css"
user-invocable: true
disable-model-invocation: false
license: MIT
metadata:
  category: frontend
  framework: react
  tags: ui, styling, components
---
```

**Custom Mode backing skill with icon and color badges:**

```yaml
---
icon: shield
color: red
alwaysApply: false
disable-model-invocation: true
user-invocable: true
metadata:
  role: security-auditor
  version: "2.0.0"
---
```

## Unique platform features

- **Custom Mode backing**: Any skill can back a dedicated session-long Custom Mode; `icon` and `color` style its UI badge in the mode selector. Unrecognized icons fall back to a default lightning badge.
- **Nested directory auto-scoping**: Skills placed in nested project subdirectories (e.g. `apps/web/.cursor/skills/<name>/`) automatically scope their context to files under that directory tree without requiring explicit `paths`.
- **Bundled resources**: Supports standard resource directories (`scripts/`, `references/`, `assets/` / `templates/`).

