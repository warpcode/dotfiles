# Rule Authoring Best Practices

Engineering principles for designing, scoping, and maintaining persistent AI rules and instructions across platforms.

---

## 1. Cognitive Boundaries & Scoping

Persistent rules shape how an AI assistant operates on a codebase. Choosing the right mechanism prevents context pollution:

| Need | Appropriate Mechanism | Why |
|---|---|---|
| Non-negotiable safety or coding constraint for specific files | **Path-Scoped Rule** (`applyTo:`, `globs:`, `paths:`) | Injected only when relevant files are touched |
| Universal repository architecture and bootstrap commands | **Root Memory** (`AGENTS.md`, `CLAUDE.md`) | Onboards agent in every session |
| Complex, multi-step procedural task | **Skill** (`SKILL.md`) | Loaded on demand; keeps main context clean |
| User-initiated shortcut or routine | **Command / Workflow** (`/name`) | Triggered explicitly with parameters |
| Isolated, resource-intensive exploration | **Subagent** (`<name>.agent.md`) | Runs in separate context with specific tool sandbox |
| Hard execution block or security barrier | **Hook / Guardrail** (`PreToolUse`) | Deterministic binary pass/fail check |

---

## 2. Token Economics & Progressive Disclosure

Every line in an always-on rule consumes context tokens on every turn across every session.

### Activation Mode Selection Hierarchy

1. **Glob / Path Scoping (First Choice)**: Only inject rules when the active file or user query touches matching globs.
2. **Model Decision / Intelligent Application (Second Choice)**: Expose only a concise description; let the agent pull the full rule body when relevant.
3. **Manual (`@mention`) (Third Choice)**: Keep specialized procedures offline until requested.
4. **Always-On (Last Resort)**: Reserve exclusively for repository-wide non-negotiables.

---

## 3. Writing Effective Directives

### Directives Must Be Verifiable
- **Bad**: "Write clean, readable code and test thoroughly."
- **Good**: "Run `npm run lint` and `pytest tests/unit` before finalizing file modifications."

### Use Clear Negative Constraints
- **Bad**: "Try to avoid `any` in TypeScript."
- **Good**: "Do NOT use `any`. Use `unknown` with explicit type narrowing or generic type parameters."

### The Pointer Pattern
Avoid pasting large boilerplate templates or complete class definitions directly into rule files. Instead, point the model to canonical example files:
- **Bad**: Pasting 150 lines of database model boilerplate.
- **Good**: "When creating new database entities, follow the structure and decorators defined in [`src/models/user.entity.ts`](file:///src/models/user.entity.ts)."

---

## 4. Platform Budgets & Caps

| Platform | Budget / Hard Cap | Guidance |
|---|---|---|
| **Google Antigravity** | 12,000 characters | Strict limit per `.agents/rules/*.md` file |
| **Claude Code** | < 200 lines | Target per `CLAUDE.md` and `.claude/rules/*.md` |
| **Cursor** | < 500 lines | Target per `.cursor/rules/*.mdc` |
| **GitHub Copilot** | < 300 lines | Target per `.github/instructions/*.instructions.md` |

---

## 5. Scope Hierarchy & Conflict Resolution

When multiple rules apply to a given file or task, models resolve conflicts based on specificity:

1. **Path-Scoped Rule** (`.instructions.md` / `.mdc` / `.agents/rules/*.md` matching the target file)
2. **Subdirectory Memory** (`src/backend/AGENTS.md`)
3. **Project Root Memory** (`<root>/AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`)
4. **User / Global Defaults** (`~/.agents/AGENTS.md`, `~/.gemini/GEMINI.md`)

Explicit negative constraints ("Do NOT...") in higher-priority rules always override permissive guidance in base files.
