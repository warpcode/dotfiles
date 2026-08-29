# Claude Code Rule & Memory Reference

Source: <https://docs.anthropic.com/en/docs/claude-code>

Claude Code provides persistent context and instructions through project memory (`CLAUDE.md`) and modular rule files (`.claude/rules/*.md`).

---

## 1. File Locations & Hierarchy

| Scope | Path | Behavior |
|---|---|---|
| **User Global** | `~/.claude/CLAUDE.md`<br>`~/.claude/rules/*.md` | Loaded across all workspaces on your machine |
| **Project Memory** | `<repo-root>/CLAUDE.md` | Primary behavioral contract loaded at session start |
| **Directory Memory** | `<sub-dir>/CLAUDE.md` | Loaded when working within that subdirectory |
| **Modular Rules** | `.claude/rules/<name>.md` | Path-scoped or topic-specific rules |

---

## 2. Modular Rules Frontmatter (`.claude/rules/*.md`)

Rule files are placed in `.claude/rules/` and use YAML frontmatter to control path activation.

### Frontmatter Schema

```markdown
---
paths:
  - "src/frontend/**/*"
  - "**/*.vue"
  - "**/*.tsx"
---

# Frontend Guidelines
- Use Composition API with `<script setup>`.
- Use Pinia for state management instead of Vuex.
```

### Activation Behavior

- **With `paths` defined**: Rule is loaded into Claude's context window only when Claude reads, edits, or inspects files matching the specified glob patterns.
- **Without `paths` (or omitted frontmatter)**: Rule is loaded unconditionally for every session in the project, acting as an always-on modular extension to `CLAUDE.md`.

---

## 3. `CLAUDE.md` Project Memory

`CLAUDE.md` serves as an architectural contract and onboarding guide for Claude Code.

### Loading & Import Rules

1. **Hierarchy**: When Claude Code starts in a directory, it walks up the directory tree to the git root, discovering and concatenating all `CLAUDE.md` files (broadest first, most specific last).
2. **File Imports (`@path`)**:
   - `CLAUDE.md` can import other files at launch using `@path/to/file` syntax (e.g. `@docs/architecture.md`).
   - Recursion is supported up to a maximum depth of **4**.

---

## 4. Best Practices & Token Budgets

- **Budget Cap**: Target **< 200 lines** per `CLAUDE.md` file. Context windows fill up quickly if instructions are bloated.
- **Offload Details to Rules**: Move framework-specific, test-specific, or directory-specific guidelines from root `CLAUDE.md` into `.claude/rules/` using `paths:` scoping.
- **No Code Duplication**: Do not copy full classes or boilerplate into `CLAUDE.md`. Point Claude at canonical example files in the repository instead.
