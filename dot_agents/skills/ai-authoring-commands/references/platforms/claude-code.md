# Claude Code Commands & Workflows Reference

Sources:
- Workflows: <https://code.claude.com/docs/en/workflows>
- Slash Commands: <https://code.claude.com/docs/en/commands>

Claude Code provides two distinct execution primitives for custom prompts and automation:
1. **Slash Commands (`.claude/commands/<name>.md`)**: Parameterized prompt templates invoked via `/<name>` with argument placeholders, tool allowlists, model/effort control, and pre-execution dynamic shell injection.
2. **Workflows (`.claude/workflows/<name>.js` or UI `/workflows`)**: Programmatic JavaScript orchestration scripts executing top-level `await`, subagent fleets (`agent()`, `pipeline()`, `parallel()`), schema validation, and concurrency bounds.

---

## 1. Slash Commands (`.claude/commands/<name>.md`)

### Locations & Precedence
- **Project Scope (VCS-shared)**: `<project-root>/.claude/commands/<name>.md`
- **Personal / User Scope**: `~/.claude/commands/<name>.md`
- **Namespaces**: Subdirectories namespace commands (e.g. `.claude/commands/git/review.md` $\rightarrow$ `/git:review`).
- **Precedence**: Project-level commands override user-level commands on name collision.

### YAML Frontmatter Schema

```yaml
---
description: string                 # Command picker summary
argument-hint: string               # Autocomplete hint (e.g. "[issue-number] [target-branch]")
allowed-tools: string | list        # Tools Claude can run without permission prompts (e.g. gh, git, webfetch)
model: string                       # Model override (sonnet, opus, haiku)
effort: string                      # Reasoning effort level (low, medium, high, max)
disable-model-invocation: boolean   # Prevent autonomous SlashCommand agent auto-invocation
context: string                     # Set to "fork" to isolate execution in a fresh subagent
subagent-type: string               # Subagent profile when context: fork is used (general-purpose, explore)
visible: boolean                    # false = hide from / autocomplete menu
paths: string | list                # Path globs scoping command availability
---
```

### Parameter Placeholders & Pre-Execution
- `$ARGUMENTS`: Entire argument string passed after the slash command.
- `$1`, `$2`, ..., `$n`: Positional whitespace-split arguments.
- `@path`: Mentions and inlines files or directory contents into the prompt.
- `` !`command` ``: Executes a shell command locally *before* rendering the prompt; stdout is embedded directly. Must be read-only inspection commands.

---

## 2. Scripted JavaScript Workflows (`.claude/workflows/<name>.js`)

Workflows allow deterministic programmatic orchestration of multiple subagents in a sandboxed JavaScript runtime.

### APIs & Primitives

| Primitive | Signature | Purpose |
|---|---|---|
| `meta` | `export const meta = { name, description }` | Required named export identifying the workflow. |
| `args` | `string` | User argument string passed upon invocation. |
| `agent(prompt, opts)` | `async (prompt: string, opts?: AgentOpts) => Promise<any>` | Spawns an isolated subagent. Resolves to `null` if stopped/errored. |
| `pipeline(items, ...stages)` | `async (items: T[], ...stages) => Promise<R[]>` | Streams items sequentially or with concurrency through worker stages. |
| `parallel(thunks)` | `async (thunks: (() => Promise<any>)[]) => Promise<any[]>` | Barrier synchronization concurrency across subtasks. |

### `AgentOpts` Properties:
- `schema`: JSON Schema enforcing structured tool output extraction (automatic retry on schema mismatch).
- `label`: Display label for progress tracking in the terminal UI.
- `phase`: Grouping label for multi-stage visual pipeline tracking.
- `model`: Subagent model override (`sonnet`, `haiku`, etc.).
- `tools`: Array of allowed tools for the subagent.

### Execution Constraints & Resilience
- **Concurrency**: Maximum 16 concurrent agents.
- **Run Limit**: Maximum 1,000 subagent invocations per workflow run.
- **Sandboxed**: No dynamic `import()` or arbitrary external npm packages.
- **Null Safety**: `agent()` returns `null` on failure/cancellation; filter results (`results.filter(Boolean)`).
- **Return Value**: Values returned from the script (`return summary`) enter Claude's main conversation context.
