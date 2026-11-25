# Authoring Rules & Instructions

Create, configure, transpile, and maintain persistent AI rules and instructions across GitHub Copilot/VS Code, Cursor, Google Antigravity, Claude Code, ChatGPT/OpenAI Codex, OpenCode, and Hermes Agent.

Rules provide **persistent always-on (`AGENTS.md`, `CLAUDE.md`, `GEMINI.md`), path-scoped (`applyTo:`/`globs:`/`paths:`), or model-decision context**; deterministic enforcement belongs in Hooks and on-demand domain knowledge belongs in Skills. See [Artifact Decision Matrix](artifact-decision-matrix.md).

## Platform Matrix

| Platform | Workspace Path | User / Global Path | File Extension | Frontmatter Dialect |
|---|---|---|---|---|
| **GitHub Copilot / VS Code** | `.github/instructions/`<br>`.github/copilot-instructions.md` | VS Code User Settings / `~/.copilot/` | `.instructions.md` | `applyTo:`, `description:`, `excludeAgent:` |
| **Cursor** | `.cursor/rules/`<br>`.cursorrules` (legacy root) | Settings > User Rules | `.mdc` *(mandatory)* | `globs:`, `description:`, `alwaysApply:` |
| **Google Antigravity** | `.agents/rules/`<br>`GEMINI.md` / `AGENTS.md` | `~/.gemini/GEMINI.md`<br>`~/.gemini/config/rules/` | `.md` | `trigger:` / `activation:`, `globs:`, `description:` |
| **Claude Code** | `.claude/rules/`<br>`CLAUDE.md` (hierarchical) | `~/.claude/CLAUDE.md`<br>`~/.claude/rules/` | `.md` | `paths:` (omitted = always on) |
| **ChatGPT / Codex** | `.codex/rules/*.rules`<br>`AGENTS.md` (repo root) | `~/.codex/rules/`<br>`~/.codex/config.toml` | `.rules`, `.md` | Policy DSL; simulated via `hooks.json` |
| **OpenCode** | `AGENTS.md` (root/dir)<br>`opencode.json` | `~/.config/opencode/AGENTS.md` | `.md`, `.json` | Multi-file `instructions: []`; plugin hooks |
| **Hermes Agent** | `AGENTS.md`, `.hermes.md`<br>`AGENTS.override.md` | `SOUL.md` (personality)<br>`~/.hermes/` | `.md` | Layered prompt hierarchy |

## Dialect Mapping Table

| Universal Field | Copilot / VS Code | Cursor (`.mdc`) | Antigravity (`.md`) | Claude Code (`.md`) |
|---|---|---|---|---|
| **Globs / Patterns** | `applyTo: "src/api/**/*.ts"` | `globs: "src/api/**/*.ts"` | `globs: ["src/api/**/*.ts"]` | `paths: ["src/api/**/*.ts"]` |
| **Always Active** | `applyTo: "**"` (or root file) | `alwaysApply: true` | `trigger: always_on` | *(omit `paths` key)* |
| **Model / Intelligent** | `description: "..."` | `description: "..."` + `alwaysApply: false` | `trigger: model_decision` + `description: "..."` | *(use skill or root CLAUDE.md)* |
| **Manual / @mention** | In UI attach menu | `@rule-name` in chat | `trigger: manual` | *(reference file path)* |
| **Agent Exclusions** | `excludeAgent: "cloud-agent"` | — | — | — |

## Platform Reference Guides

- `rules/platforms/antigravity.md`, `rules/platforms/cursor.md`, `rules/platforms/copilot-vscode.md`, `rules/platforms/claude-code.md`, `rules/platforms/codex.md`, `rules/platforms/opencode.md`, `rules/platforms/hermes.md`
- `rules/hooks-and-simulation.md`: Simulating path-scoped rules on platforms lacking native frontmatter glob engines.
- `rules/best-practices.md`: Token budgeting, negative constraints, verifiable directives, and conflict hierarchy.

## Standard Rule Templates

- `templates/rules/agent-safety-governance.instructions.md`
- `templates/rules/ai-prompt-engineering-best-practices.instructions.md`
- `templates/rules/api-mcp-development.instructions.md`
- `templates/rules/language-framework-conventions.instructions.md`
- `templates/rules/path-scoped-testing.instructions.md`

## Validation

```bash
python3 <skill-dir>/scripts/validate_rules.py <path-to-rule-or-dir>
```

Checklist: correct location/extension, valid YAML frontmatter, matching platform dialect (never mix `applyTo` / `globs` / `paths` / `trigger`), tested globs, and token budget (<12,000 chars Antigravity, <200 lines Claude, <500 lines Cursor).
