# Authoring Agent Skills

Standards, architecture boundaries, and validation tools for agent skill packages conforming to the agentskills.io open standard.

## Architecture: Knowledge Centre vs. Agent

Skills are **Domain Knowledge Centres**, not procedural SOP scripts. See [Artifact Decision Matrix](artifact-decision-matrix.md) for the boundary across Skills, Agents, Commands, Rules, Hooks, and Prompt Patterns.

### Explicit Prohibitions in `SKILL.md`

- **No subagent JSON orchestration or delegation protocols in `SKILL.md`.** Workflow orchestration and multi-agent handoffs belong in `.github/agents/*.agent.md` or `.github/prompts/*.prompt.md` (see [Authoring Agents](agents.md)).
- **No dated war stories or chronological post-mortems in `SKILL.md`.** Distill timeless API/tool gotchas into `references/` and turn repeated multi-call commands into `scripts/`.
- **No shell loops, `jq` chains, or inline `python3 -c` in `SKILL.md`.** Put deterministic loops and transforms behind `--help` in `scripts/`.

## Tool-Backed Skills: Gather First, Script the Rest

For **pure Knowledge Centre skills**, `SKILL.md` is a concise routing hub pointing to `@references/` and `templates/` — do not force `1. GATHER -> 2. REASON -> 3. ACT` SOP prose onto reference domains.

For **tool-backed skills** that wrap CLIs or APIs:

1. **Gather in one consistent snapshot**: Bundle state-gathering commands into a single report-only script that returns dense JSON (writing large payloads to `--out <dir>`). Never let an agent act on partially gathered state.
2. **One script per question**: Any recurring sequence of >=2 sequential tool calls belongs in `scripts/` with standard CRUD prefixes (`get-`, `list-`, `search-`, `create-`, `update-`, `delete-`, `-bundle`, `-rollup`).
3. **Black-box CLI interface**: Document `--help` and a "run when" routing row in `SKILL.md` so agents run scripts without reading source code. Mutations require an explicit flag (e.g. `--apply`).
4. **Report gaps explicitly**: Unreadable or missing checks must surface as gap fields, never defaulted to passing.

## Authoring & Validation Lifecycle

1. **Choose the right layer**: Confirm the need belongs in a Skill rather than an Agent, Command, Rule, or Hook via [Artifact Decision Matrix](artifact-decision-matrix.md).
2. **Design package layout**: Keep `SKILL.md` concise (<500 lines; ideally <120 lines as a routing hub) and pushy in `description` (<1024 chars with literal trigger phrases). Move deep docs to `references/`, schemas to `templates/`, and deterministic logic to `scripts/`. See `skills/skill-structure.md` and `skills/platforms/antigravity.md`.
3. **Author bundled scripts (when tool-backed)**: Follow `skills/script-standards.md`, `skills/cli-integration/cli-to-skill.md`, and `skills/cli-integration/script-patterns.md`.
4. **Validate & audit**:
   - Structure, syntax, and scriptability: `python3 <skill-dir>/scripts/validate.py <skill-directory>`
   - Empirical script usage (default 200 sessions): `python3 <skill-dir>/scripts/validate.py --audit-script-usage <skill-directory>`
   - Audit checklist & evals: `skills/audit-workflow.md` and `skills/evals.md`.

## Category Templates

| Category | Typical Use Case | Template Path |
|---|---|---|
| **Knowledge Centre** *(default)* | Domain routing hub linking `@references/`, `@scripts/`, and invariants | `templates/knowledge-centre.md` |
| **Guidelines** | Static code style, security policies, architecture constraints | `templates/skills/guidelines.md` |
| **Tool Integration** | CLI wrappers, MCP adapters, and API interfaces | `templates/skills/integration-tool.md` |
| **Meta** | Self-improving tools, skill auditing, authoring | `templates/skills/meta.md` |
| **Workflow / SOP** *(narrow)* | Single-agent deterministic tool pipelines only (general workflows belong in Agents) | `templates/skills/workflow-sop.md` |
| **Orchestrator** *(legacy)* | Prefer `.github/agents/*.agent.md` via [Authoring Agents](agents.md) for subagent orchestration | `templates/skills/orchestrator.md` |

## Output Contract & Verification

Every created or edited skill package must satisfy:
1. `python3 <skill-dir>/scripts/validate.py <skill-path>` passes with zero `FAIL`s and zero unintended `WARN`s.
2. `SKILL.md` stays strictly under 500 lines (routing hubs target <120 lines), with `description` under 1024 characters.
3. No subagent JSON orchestration, dated session war stories, shell loops, `jq` chains, or inline `python3 -c` in `SKILL.md`.
4. Tool-backed skills expose report-only-by-default scripts that compile (`py_compile` / `bash -n`) and have been executed at least once.
