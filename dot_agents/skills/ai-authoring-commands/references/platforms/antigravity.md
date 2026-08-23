# Google Antigravity Workflows & Slash Commands Reference

Source: <https://antigravity.google/docs/ide/workflows/#workflows>

## 1. Concepts & Primitives

In Google Antigravity, **Workflows** are structured markdown files that codify repeatable multi-step procedures, runbooks, and Standard Operating Procedures (SOPs). Saved workflow files are automatically discovered and registered as **custom slash commands** (e.g. `/code-review`), allowing developers or orchestrator agents to trigger deterministic processes with parameterized arguments, subagent delegation, checkpoints, and tool restrictions.

Workflows differ from Skills and Rules:
- **Command / Workflow (`.agents/workflows/<name>.md`)**: User or agent triggered directive executing a structured procedure with specific steps and parameters.
- **Skill (`.agents/skills/<name>/SKILL.md`)**: Reusable capability loaded on-demand via progressive disclosure.
- **Rule (`.agents/rules/*.md`)**: Persistent background context (always-on or path-scoped).

---

## 2. Locations & Discovery Hierarchy

Antigravity walks up from the current working directory to the repository root to discover workspace workflows, and also checks global user configuration:

| Scope | Standard Location | Fallback / Legacy | Notes |
|---|---|---|---|
| **Workspace (Project)** | `<root>/.agents/workflows/<name>.md` | `<root>/.agent/workflows/<name>.md`<br>`<root>/_agents/workflows/<name>.md` | Version-controlled and shared with team. |
| **Workspace Commands** | `<root>/.agents/commands/<name>.md` | — | Alternative commands directory. |
| **Global (User / Machine)** | `~/.gemini/antigravity/global_workflows/<name>.md` | `~/.gemini/config/workflows/<name>.md`<br>`~/.gemini/commands/<name>.toml` | Available across all local workspaces. |
| **Plugins** | `<plugin-root>/workflows/<name>.md` | Registered in `plugins.json` | Bundled with custom Antigravity plugins. |

### Precedence & Invocation
1. Project-level workflows (`.agents/workflows/`) override global workflows on name collisions.
2. The command trigger is derived from the filename minus `.md` (e.g. `audit-pr.md` $\rightarrow$ `/audit-pr`) or the frontmatter `name:` key.
3. Workflows can be created or managed via the Antigravity IDE Agent panel (**Customizations** $\rightarrow$ **Workflows**).

---

## 3. Frontmatter Schema

Workflows use YAML frontmatter bounded by `---`:

```yaml
---
name: string                   # Optional: command trigger (default: filename without .md)
description: string            # Picker description and agent recommendation trigger
argument-hint: string          # Usage hint in UI (e.g. "[pr-number] [--strict]")
mode: string                   # Optional: workflow | subagent | prompt (default: workflow)
model: string                  # Optional: model override (e.g. gemini-3.5-pro, gemini-3.5-flash)
temperature: float             # Optional: sampling temperature (0.0 to 1.0)
max_turns: integer             # Optional: iteration / step cap for execution
user-invocable: boolean        # Optional: visible in slash autocomplete (default: true)
inheritCustomizations: boolean # Optional: inherit parent rules/skills/MCPs (default: false)
capabilities:                  # Optional: least-privilege capability sandboxing
  allowed_tools:
    - view_file
    - grep_search
    - list_dir
    - run_command
  allowed_skills:
    - technical-review-guidelines
  allowed_mcp_servers:
    - github
  allowed_bash_commands:
    - "git status*"
    - "git diff*"
---
```

### Constraints & Rules
- **12,000-Character Budget**: Workflow definitions have a 12,000-character cap per file.
- **Capabilities Whitelist**: The `capabilities` block restricts available tools, bash command patterns, and skills to enforce least-privilege execution.

---

## 4. Parameter Placeholders & Context Interpolation

| Placeholder | Meaning | Example |
|---|---|---|
| `$ARGUMENTS` (or `{{args}}`) | Complete unparsed arguments string | `/audit-pr 123 --strict` $\rightarrow$ `"123 --strict"` |
| `$1`, `$2`, ..., `$n` | Positional whitespace-split arguments | `/deploy web prod` $\rightarrow$ `$1="web"`, `$2="prod"` |
| `$SELECTION` | Currently selected/highlighted code in editor | Injects highlighted block |
| `$FILE` / `$CURRENT_FILE` | Path to the active file in editor | Injects active file path |
| `@path` / `@file` | Inlines file or directory tree content | `@src/auth/jwt.ts` |
| `` !`command` `` | Synchronously runs shell command and embeds stdout | `` !`git diff --staged` `` |

*Safety rule*: Pre-execution shell commands (`` !`command` ``) must be read-only inspection commands.

---

## 5. Flow Control & Directives

### A. Numbered Steps & Checklists
Use explicit numbered steps and markdown checkboxes (`- [ ]`) so the executing agent can track progress:
```markdown
## Execution Steps
- [ ] 1. Inspect git status: !`git status --short`
- [ ] 2. Check staged changes: !`git diff --staged`
- [ ] 3. Run verification tests.
```

### B. Human Approval Checkpoints (Gates)
Mandate user confirmation before any state modification or destructive action:
```markdown
### Checkpoint: Plan Review
- Present proposed changes in `implementation_plan.md`.
- **STOP & PROMPT**: Require explicit user confirmation before modifying files.
```

### C. Workflow Composition & Subagents
- **Chaining**: Call other workflows directly by slash command (`Call /quick-commit`).
- **Subagents**: Delegate noisy exploration to specialized subagents (e.g. `security-auditor`).
