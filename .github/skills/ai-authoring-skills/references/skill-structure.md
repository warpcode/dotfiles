# Skill Structure & Frontmatter Reference

Comprehensive specifications for directory layouts, frontmatter keys, naming conventions, and multi-platform locations adhering to the agentskills.io standard.

---

## Platform Locations

| Surface | Workspace Scope | Personal / Global Scope |
|---|---|---|
| Portable Standard | `.agents/skills/<name>/` | `~/.agents/skills/<name>/SKILL.md` |
| Claude Code | `.claude/skills/<name>/` | `~/.claude/skills/<name>/` |
| Copilot / VS Code | `.github/skills/<name>/` | `~/.copilot/skills/<name>/` |
| OpenCode | `.opencode/skills/<name>/` | also reads `~/.claude/skills/` |
| Cursor | `.cursor/skills/<name>/` | `~/.cursor/skills/<name>/` |
| Codex | `.codex/skills/<name>/` | `~/.codex/skills/<name>/` |
| Antigravity | `.agents/skills/<name>/` | `~/.gemini/config/skills/<name>/` |

> [!NOTE]
> Write ONE skill package against the open standard; target platform directories via symlinks or sync workflows rather than creating divergent forks.

---

## Directory & Package Layout

```
<skill-name>/
├── SKILL.md                  # Required: YAML frontmatter + core instructions (<500 lines)
├── references/              # Optional: Deep-dive domain docs loaded on demand
│   ├── environments.md
│   └── architecture.md
├── scripts/                  # Optional: Executable black-box helpers (see references/script-standards.md)
│   └── validate.py
└── templates/                # Optional: Fixed output structures & schemas
    └── output-spec.md
```

---

## Frontmatter Specification

### Required Keys

```yaml
---
name: <folder-name>          # Must match the folder name exactly
description: >
  Concise 3rd-person description stating WHAT the skill does and WHEN to trigger it.
  Include literal user trigger phrases. Keep under 1024 characters.
---
```

### Naming Conventions

Pattern: `<optional-prefix>-<domain>-<task-or-type>` (lowercase, hyphen-separated).

| Family Prefix | Domain Scope | Examples |
|---|---|---|
| `ai-authoring-` | AI artifacts (prompts, skills, agents, rules, commands, hooks) | `ai-authoring-skills`, `ai-authoring-prompts` |
| `code-` | Codebase architecture, quality, testing, security | `code-tdd`, `code-architecture`, `code-security-audit` |
| `git-` / `github-` | Version control & GitHub platform operations | `git-expert`, `github-cli`, `github` |
| `shell-` | Shell scripting, idioms, and environment configuration | `shell-scripting` |
| `database-` | Schema migration, query optimization, data modeling | `database-architecture` |
| `task-` / `pm-` | Product planning, task decomposition, ticket authoring | `task-planning` |
| (none) | Standalone tools, products, or converters | `email-classifier`, `google-jules-api` |

### Description Rules

The `description` field is the **only** metadata visible to agent routers during initial tool selection.
1. **Third-Person & Concise**: State capability and triggering context in ~3–4 lines.
2. **Push Against Undertriggering**: Explicitly list user trigger phrases (e.g. *"create a skill"*, *"skill-ify this"*, *"audit skill"*).
3. **Character Budget**: Keep strictly under **1024 characters** to prevent truncation across Claude, OpenCode, and Copilot.

---

## Platform-Specific Extensions

Consult platform reference documents when layering optional extension fields:

| Platform | Extension Features | Reference |
|---|---|---|
| Claude Code | Invocation control, tool grants, model/effort, forked context, `!` injection | `@references/platforms/claude-code.md` |
| Copilot / VS Code | `argument-hint`, `user-invocable`, experimental `context: fork` | `@references/platforms/copilot-vscode.md` |
| OpenCode | `license`, `compatibility`, `metadata` map | `@references/platforms/opencode.md` |
| Cursor | `paths` file scoping, Custom Mode badges (`icon`/`color`), `metadata` | `@references/platforms/cursor.md` |
| Codex | `license`, `compatibility`, `metadata` map | `@references/platforms/codex.md` |
| Antigravity | Declarative JSON discovery (`skills.json`/`plugins.json`), agent scoping | `@references/platforms/antigravity.md` |
| Hermes Agent | Version/platform gating, tool requirements, env vars, blueprints | `@references/platforms/hermes.md` |

