---
name: ai-authoring-skills
description: >
  Create, audit, test, or refactor agent skill packages (SKILL.md, references,
  scripts, evals) across Claude, Copilot, Cursor, Antigravity, and Hermes. Use
  when authoring, updating, or packaging skills, or consolidating repeated tool
  calls into bundled runnable scripts.
---

# Agent Skills Authoring Knowledge Centre

Standards, architecture boundaries, and validation tools for agent skill packages conforming to the agentskills.io open standard.

## Architecture: Knowledge Centre vs. Agent

Skills are **Domain Knowledge Centres**, not procedural SOP scripts:

| Artifact | Owns | Does NOT Own | Skill |
|---|---|---|---|
| **Skill** (`SKILL.md`, `references/`, `scripts/`) | Timeless domain knowledge, invariants, routing hubs, and deterministic black-box scripts | Multi-agent orchestration, persona definitions, or chronological session logs | `ai-authoring-skills` |
| **Agent / Subagent** (`*.agent.md`, `*.md`) | Role personas, step ordering, multi-step workflows, isolated contexts & tool policies | Duplicated domain API docs or inline shell loops | `ai-authoring-agents` |
| **Command** (`/name`, `*.prompt.md`) | Thin user-invoked entrypoints & parameter binding | Long runbooks or domain reference tables | `ai-authoring-commands` |
| **Rule / Hook** (`AGENTS.md`, `*.instructions.md`, `hooks.json`) | Always-on/path-scoped guardrails & deterministic lifecycle gates | Task-specific domain manuals | `ai-authoring-rules` / `ai-authoring-hooks` |

See `@references/artifact-decision-matrix.md` for the single canonical Artifact Decision Matrix shared across all `ai-authoring-*` skills.

### Explicit Prohibitions in `SKILL.md`

- **No subagent JSON orchestration or delegation protocols in `SKILL.md`.** Workflow orchestration and multi-agent handoffs belong in `.github/agents/*.agent.md` or `.github/prompts/*.prompt.md` (see `ai-authoring-agents`).
- **No dated war stories or chronological post-mortems in `SKILL.md`.** Distill timeless API/tool gotchas into `@references/` and turn repeated multi-call commands into `@scripts/`.
- **No shell loops, `jq` chains, or inline `python3 -c` in `SKILL.md`.** Put deterministic loops and transforms behind `--help` in `@scripts/`.

---

## Tool-Backed Skills: Gather First, Script the Rest

For **pure Knowledge Centre skills**, `SKILL.md` is a concise routing hub pointing to `@references/` and `templates/` — do not force `1. GATHER -> 2. REASON -> 3. ACT` SOP prose onto reference domains.

For **tool-backed skills** that wrap CLIs or APIs:

1. **Gather in one consistent snapshot**: Bundle state-gathering commands into a single report-only script that returns dense JSON (writing large payloads to `--out <dir>`). Never let an agent act on partially gathered state.
2. **One script per question**: Any recurring sequence of >=2 sequential tool calls belongs in `@scripts/` with standard CRUD prefixes (`get-`, `list-`, `search-`, `create-`, `update-`, `delete-`, `-bundle`, `-rollup`).
3. **Black-box CLI interface**: Document `--help` and a "run when" routing row in `SKILL.md` so agents run scripts without reading source code. Mutations require an explicit flag (e.g. `--apply`).
4. **Report gaps explicitly**: Unreadable or missing checks must surface as gap fields, never defaulted to passing.

---

## Authoring & Validation Lifecycle

1. **Choose the right layer**: Confirm the need belongs in a Skill rather than an Agent, Command, Rule, or Hook via `@references/artifact-decision-matrix.md`.
2. **Design package layout**: Keep `SKILL.md` concise (<500 lines; ideally <120 lines as a routing hub) and pushy in `description` (<1024 chars with literal trigger phrases). Move deep docs to `@references/`, schemas to `templates/`, and deterministic logic to `@scripts/`. See `@references/skill-structure.md` and `@references/platforms/antigravity.md`.
3. **Author bundled scripts (when tool-backed)**: Follow `@references/script-standards.md`, `@references/cli-integration/cli-to-skill.md`, and `@references/cli-integration/script-patterns.md`.
4. **Validate & audit**:
   - Structure, syntax, and scriptability: `python3 <skill-dir>/scripts/validate.py <skill-directory>`
   - Empirical script usage (default 200 sessions): `python3 <skill-dir>/scripts/validate.py --audit-script-usage <skill-directory>`
   - Audit checklist & evals: `@references/audit-workflow.md` and `@references/evals.md`.

---

## Category Templates

| Category | Typical Use Case | Template Reference |
|---|---|---|
| **Knowledge Centre** *(default)* | Domain routing hub linking `@references/`, `@scripts/`, and invariants | `templates/knowledge-centre.md` |
| **Guidelines** | Static code style, security policies, architecture constraints | `templates/guidelines.md` |
| **Tool Integration** | CLI wrappers, MCP adapters, and API interfaces | `templates/integration-tool.md` |
| **Meta** | Self-improving tools, skill auditing, authoring | `templates/meta.md` |
| **Workflow / SOP** *(narrow)* | Single-agent deterministic tool pipelines only (general workflows belong in Agents) | `templates/workflow-sop.md` |
| **Orchestrator** *(legacy)* | Prefer `.github/agents/*.agent.md` via `ai-authoring-agents` for subagent orchestration | `templates/orchestrator.md` |

---

## Script Helpers & Execution

Run helper scripts relative to this skill's root directory (`<skill-dir>/scripts/...`):

| Utility | Location | Invocation | Purpose |
|---|---|---|---|
| `validate.py` | `@scripts/validate.py` | `python3 <skill-dir>/scripts/validate.py <path>` | Validates frontmatter, description cap, body length, resource links, script syntax, and scriptability |
| `validate.py` (self-test) | `@scripts/validate.py` | `python3 <skill-dir>/scripts/validate.py --self-test` | Runs built-in validation engine assertions |
| `audit_bundled_scripts.py` | `@scripts/audit_bundled_scripts.py` | `python3 <skill-dir>/scripts/audit_bundled_scripts.py <path> [--sessions 200]` | Audits empirical script usage in conversation history |

---

## Output Contract & Verification

Every created or edited skill package must satisfy:
1. `python3 <skill-dir>/scripts/validate.py <skill-path>` passes with zero `FAIL`s and zero unintended `WARN`s.
2. `SKILL.md` stays strictly under 500 lines (routing hubs target <120 lines), with `description` under 1024 characters.
3. No subagent JSON orchestration, dated session war stories, shell loops, `jq` chains, or inline `python3 -c` in `SKILL.md`.
4. Tool-backed skills expose report-only-by-default scripts that compile (`py_compile` / `bash -n`) and have been executed at least once.
