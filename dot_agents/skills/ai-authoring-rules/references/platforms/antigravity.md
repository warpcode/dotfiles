# Google Antigravity Rule Reference

Source: <https://antigravity.google/docs/rules-workflows/#workspace-rules>

Google Antigravity supports both modular rule files with YAML frontmatter triggers and hierarchical directory-based instruction files.

---

## 1. File Locations & Discovery

| Type | Path | Purpose |
|---|---|---|
| **Workspace Modular Rules** | `.agents/rules/<name>.md`<br>*(also `.agent/rules/`, `.gemini/rules/`)* | Scoped or conditional rule files with frontmatter triggers |
| **Directory-Scoped Rules** | `GEMINI.md` or `AGENTS.md` | Plain markdown applied to that directory and all child subtrees |
| **Global / User Rules** | `~/.gemini/GEMINI.md`<br>`~/.gemini/config/rules/*.md` | Universal instructions loaded across all projects |

---

## 2. Modular Rules Frontmatter (`.agents/rules/*.md`)

Modular rule files use YAML frontmatter enclosed by `---` lines at the top of the file.

### Frontmatter Schema

| Key | Type | Default | Description |
|---|---|---|---|
| `trigger` (or `activation`) | string | `always_on` | Activation mode: `always_on`, `glob`, `model_decision`, or `manual`. |
| `globs` (or `glob_pattern`) | string / list | `[]` | Glob pattern(s) triggering the rule when matching files are edited/read. Required when `trigger: glob`. |
| `description` | string | `""` | Short summary of rule intent. Required for `model_decision` so the model can evaluate relevance before loading. |

### Activation Modes

1. **`always_on`**:
   - Injected into the context window on every turn unconditionally.
   - Use only for universal guardrails and high-priority constraints.
2. **`glob`**:
   - Injected automatically when the files being inspected, edited, or discussed match the glob pattern.
   - Example: `globs: ["**/*.ts", "**/*.tsx"]`.
3. **`model_decision`**:
   - Progressive disclosure mode: only the `description` is initially exposed to the agent.
   - The agent reads the full rule body into context only when its task requires it.
   - Maximizes token efficiency for domain-specific guidelines (e.g. database migrations, accessibility checks).
4. **`manual`**:
   - Active only when explicitly referenced by the user via `@rule-name` in the prompt.

### Frontmatter Examples

**Glob-scoped rule:**
```markdown
---
trigger: glob
globs: ["src/api/**/*.ts", "src/routes/**/*.ts"]
description: "API design and error response standards"
---

# API Guidelines
- Return standardized RFC 7807 problem details on 4xx/5xx errors.
- Never leak internal database stack traces to clients.
```

**Model-decision rule:**
```markdown
---
trigger: model_decision
description: "Guidelines and safety procedures for database schema migrations and data backfills."
---

# Migration Safety
- Always wrap schema alterations in transactional blocks where supported.
- Backfill scripts must run in batches of <= 500 rows with 50ms pauses.
```

---

## 3. Directory-Scoped Rules (`GEMINI.md` / `AGENTS.md`)

- Placed directly in any project folder (e.g. `src/frontend/GEMINI.md` or `tests/AGENTS.md`).
- **No frontmatter**: Standalone plain markdown.
- **Traversal**: When a session starts or operates in a directory, Antigravity walks from the current working directory upward to the repository root, concatenating all discovered rule files.
- **Inheritance**: Subdirectories inherit parent rules.

---

## 4. Platform Constraints & Features

- **Character Budget**: Hard ceiling of **12,000 characters** per rule file. Keep rules concise and split large topics across files.
- **Path Inlining**: Support for `@path` syntax to inline external references or shared snippets (e.g. `@docs/api-specs.md`).
- **Deduplication**: Rule files are deduplicated by their canonical resolved path; symlinked rules or multi-path matches are injected only once per conversation turn.
