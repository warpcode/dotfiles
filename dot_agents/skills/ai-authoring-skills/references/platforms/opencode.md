# OpenCode skill reference

Source: <https://opencode.ai/docs/skills/>

## Locations & discovery

- Project: `.opencode/skills/<name>/`, `.claude/skills/<name>/`, `.agents/skills/<name>/`
- Global: `~/.config/opencode/skills/<name>/`, `~/.claude/skills/<name>/`, `~/.agents/skills/<name>/`

## Recognized frontmatter options

| Key | Required | Purpose |
|---|---|---|
| `user-invocable` | No | Default `true`; `false` hides from the slash command menu (model auto-activation only) |
| `disable-model-invocation` | No | Default `false`; `true` = manual slash invocation only, prevents automatic model loading |
| `license` | No | License identifier (agentskills.io open standard) |
| `compatibility` | No | Environment, runtime, and tool prerequisites (max 500 chars) |
| `metadata` | No | Arbitrary string-to-string key-value mapping (e.g. author, version, tags) |

OpenCode safely ignores unknown frontmatter keys without failing.

### Frontmatter example

```yaml
---
user-invocable: true
disable-model-invocation: false
license: MIT
compatibility: "bun >= 1.0, git >= 2.30"
metadata:
  author: frontend-core
  version: "1.4.2"
  tags: typescript, bundling, bun
---
```

## Access control & permission configuration (`opencode.json`)

Skill access and execution policies are managed declaratively in `opencode.json` under `permission.skill`:

```json
{
  "permission": {
    "skill": {
      "allow": ["git-*", "testing-*"],
      "deny": ["admin-*"],
      "ask": ["deploy-*"]
    }
  }
}
```

- **Policy actions**: `"allow"` (auto-loaded), `"deny"` (blocked), `"ask"` (requires explicit user confirmation).
- **Pattern matching**: Supports wildcard matching on skill names.
- **Agent overrides**: Individual agents defined in `opencode.json` or `.opencode/agent/` can override skill permissions or disable the `skill` tool entirely (`"tools": { "skill": false }`).

