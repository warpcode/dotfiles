# ChatGPT & OpenAI Codex Rule Reference

Source: <https://learn.chatgpt.com/docs/agent-configuration/rules>

OpenAI Codex uses project `AGENTS.md` files, `.codex/rules/*.rules` policy files, and a lifecycle **Hooks framework** (`hooks.json` / `config.toml`) to enforce rules and govern agent behavior.

---

## 1. File Locations & Hierarchy

| Scope | Path | Purpose |
|---|---|---|
| **Project Context** | `AGENTS.md` (repo root) | Universal project instructions, stack description, and house conventions |
| **Project Rules** | `.codex/rules/*.rules` | Project-specific behavioral policies and tool constraints *(trusted workspaces only)* |
| **Project Hooks** | `.codex/hooks.json` | Project-specific lifecycle hook scripts *(trusted workspaces only)* |
| **User Rules** | `~/.codex/rules/*.rules` | Global rule and policy files (e.g. `~/.codex/rules/default.rules`) |
| **User Hooks** | `~/.codex/hooks.json` or `~/.codex/config.toml` | Global lifecycle hooks |

> [!IMPORTANT]
> **Workspace Trust Requirement**: Codex will ignore project-local `.codex/` configuration (including local rules and hook scripts) if the workspace is not marked as trusted, preventing arbitrary script execution.

---

## 2. Native Rules Format (`.rules`)

Codex `.rules` files enforce behavioral constraints, permission boundaries, and tool policies:

```
# Example default.rules
policy tool_execution {
    deny pattern "rm -rf *"
    prompt pattern "git push*"
    require_approval true
}
```

- Explicit "deny" rules take precedence over allow rules.
- Rules govern what tools the agent can invoke and under what security constraints.

---

## 3. Simulating Path-Scoped Rules via Lifecycle Hooks

Because Codex does not natively parse YAML frontmatter `applyTo` / `globs` on markdown files, **lifecycle hooks** provide the standard mechanism to simulate path-scoped rule injection and hard guardrails.

### Supported Hook Lifecycle Events

| Event | Trigger Point | Use Case for Rules |
|---|---|---|
| `UserPromptSubmit` | Fired when user submits a prompt | Inspect prompt/working files and dynamically append relevant rule instructions |
| `PreToolUse` | Fired before a tool is executed | Inspect file paths targeted by tools (`readFile`, `writeFile`) and inject rules or validate constraints |
| `PostToolUse` | Fired after a tool completes | Verify compliance (e.g. ensure linter passed after write) |
| `SessionStart` | Fired when session begins | Inject global environment constraints |

### Hook Configuration Example (`.codex/hooks.json`)

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "command": "python3 scripts/inject_scoped_rules.py --prompt \"$PROMPT\""
      }
    ],
    "PreToolUse": [
      {
        "matcher": "writeFile|editFile",
        "command": "python3 scripts/enforce_rule_guardrails.py --file \"$FILE_PATH\""
      }
    ]
  }
}
```

For complete implementation scripts and recipes for hook-simulated rules, see [@references/hooks-and-simulation.md](../hooks-and-simulation.md).
