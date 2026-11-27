# Hermes Agent Instruction Reference

Source: <https://hermes-agent.nousresearch.com/docs/>

Hermes Agent uses a layered prompt assembly hierarchy comprising `SOUL.md`, `AGENTS.md`, `.hermes.md`, and local override files.

---

## 1. Context Hierarchy & Assembly Order

When assembling the agent system prompt, Hermes resolves files in strict priority order:

| File | Purpose | Priority / Slot |
|---|---|---|
| **`SOUL.md`** | Global agent persona, tone, and identity | Always loaded (Slot #1) |
| **`.hermes.md`** | Project-specific Hermes directives | Highest project priority |
| **`AGENTS.override.md`** | Personal, gitignored developer overrides | High (overrides team `AGENTS.md`) |
| **`AGENTS.md`** | Standard repository and directory rules | Base project context |
| **`CLAUDE.md`** | Claude Code compatibility fallback | Lower fallback |
| **`.cursorrules`** | Cursor IDE compatibility fallback | Lowest fallback |

---

## 2. Directory Chain Traversal

- Hermes traverses the directory structure from the **git repository root down to the current working directory**.
- Discovered `AGENTS.md` files are loaded sequentially.
- Rules located deeper in the directory hierarchy appear later in the assembled prompt, naturally allowing local subfolder rules to refine or override root rules.

---

## 3. Best Practices

- **Separate Persona from Rules**: Put conversational style and tone into `SOUL.md`; keep `AGENTS.md` strictly focused on technical constraints, testing commands, and architecture rules.
- **Use `AGENTS.override.md` for Personal Setups**: Put developer-specific local paths, test keys, or private preferences in `AGENTS.override.md` (add it to `.gitignore`).
- **Compatibility**: If maintaining a multi-agent repository, authoring a clean `AGENTS.md` at root provides immediate cross-compatibility across Hermes, OpenCode, Codex, and Copilot.
