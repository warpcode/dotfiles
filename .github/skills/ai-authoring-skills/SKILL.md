---
name: ai-authoring-skills
description: >
  Create, modify, update, improve, merge, replace, split, rename, or audit
  agent skills (SKILL.md packages) across Claude Code, GitHub Copilot,
  OpenCode, Cursor, Gemini CLI/Antigravity, and Hermes Agent. Use when the
  user says "create a skill", "make a skill for X", "skill-ify this", "turn
  this into a skill", asks where skills live, how SKILL.md frontmatter works,
  how to name/rename/group skills with prefixes, which template or skill type
  fits (workflow/SOP, guidelines, tool integration, orchestrator, meta),
  reports a skill not triggering, or wants proof a skill works ("test my
  skill", "run evals", "trigger benchmark"). Not for agents, rules, slash
  commands, or hooks - those have their own ai-authoring skills. Covers the
  agentskills.io open standard, naming rules, folder hierarchy, script
  standards, validation, and evals with subagents.
---

# Authoring Agent Skills

Create, modify, rename, and audit agent skills - `SKILL.md` packages defined
by the agentskills.io open standard, supported natively by Claude Code,
Copilot/VS Code, OpenCode, Cursor, Codex, Gemini CLI/Antigravity, and Hermes Agent.
A skill is a folder containing `SKILL.md` (YAML frontmatter + markdown
instructions) plus optional bundled resources.

## When to use

- The user says "create a skill", "make a skill for X", "skill-ify this", or
  "turn this into a skill".
- They want to modify, update, improve, merge, replace, break down, or break
  up an existing skill.
- They ask where skills live on a platform, or how `SKILL.md` frontmatter
  works.
- They ask how to name, rename, or group skills with prefixes.
- They ask which template or skill type fits (workflow/SOP, guidelines,
  tool integration, orchestrator, meta).
- They report that a skill is not triggering.
- They want to test, evaluate, or benchmark how a skill performs.

## Skill structure

### Platform locations

| Surface | Workspace scope | Personal/global scope |
|---|---|---|
| Portable | `.agents/skills/<name>/` | `~/.agents/skills/<name>/SKILL.md` |
| Claude Code | `.claude/skills/<name>/` | `~/.claude/skills/<name>/` |
| Copilot / VS Code | `.github/skills/<name>/` | `~/.copilot/skills/<name>/` |
| OpenCode | `.opencode/skills/<name>/` | also reads `~/.claude/skills/` |
| Cursor | `.cursor/skills/<name>/` | `~/.cursor/skills/<name>/` |
| Codex | `.codex/skills/<name>/` | `~/.codex/skills/<name>/` |
| Antigravity | `.agents/skills/<name>/` | `~/.gemini/config/skills/<name>/` |

Write ONE skill against the standard; platform directories are deployment
targets (symlink or sync), never forks.

### Directory and file structure

Illustrative example - subfolders are optional; bundle only what the skill needs:

```
deploy-app/
├── SKILL.md                  # required: YAML frontmatter + instructions;
│                             #   body stays routing + core rules
├── references/               # optional: detail loaded on demand
│   ├── environments.md       #   deep-dive doc, read only when needed
│   └── rollback/             #   group related docs in a subfolder
│       └── procedure.md
├── scripts/                  # optional: executable helpers (black boxes)
│   └── healthcheck.sh        #   agents run --help first, never read source
└── templates/                # optional: fixed output structures
    └── changelog.md          #   (`assets/` upstream); group by context
```

### SKILL.md frontmatter

#### Required keys: `name` and `description`

These are the only standard keys; everything else is platform-specific.

```yaml
---
name: <folder-name>          # must match the folder name exactly
description: >
  Explicitly states how to trigger the skill only.
  Description is used by agents to decide when to load the skill; it is the only thing they see.
---
```

#### Name rules

General pattern: `<optional-prefix>-<domain>-<task-or-skill-type>` -
lowercase, hyphen-separated, every segment optional except one meaningful
identifier. All of these are valid:

- `jules-cli`, `google-jules-api`, `jules-agent-workflows`
- `git-helper`, `git-cli`
- `github-cli`, `github-mcp`, `github-best-practices`,
  `github-pull-request-review-guidelines`

Prefixes are conventions, not a closed registry - reuse an existing family
when it fits, invent one for a genuinely new domain:

| Family | Domain |
|---|---|
| `ai-authoring-` | creating/modifying AI artifacts (prompts, skills, agents, rules, commands, hooks) |
| `git-` / `github-` | version control / GitHub platform |
| `shell-` | shell scripting & style |
| `email-`, `jira-` | product domains |
| `security-` | secrets & vulnerability patterns |
| `content-` | content transforms |
| `personal-` | life admin |
| (none) | product names and converters |

Don't append `-guidelines` unless inherent to the skill's purpose.
Externally-installed upstream skills keep upstream names - renaming breaks
update tracking.

#### Description rules

The description is the ONLY thing an agent sees when deciding to load a skill.

1. Third person, one paragraph, roughly four lines max.
2. State WHAT it does and WHEN to use it; include literal phrases users type
   ("create a skill", "commit message").
3. Push against undertriggering: list near-miss contexts explicitly.
4. All "when to use" information lives here - never only in the body.
5. Keep under ~1024 characters: OpenCode and Copilot hard-cap there, and
   Claude truncates listing text at 1,536.

#### Platform-specific extensions

Each platform layers extra keys on top of the required core. Consult the
reference before adding extras, and keep skills fully functional without them:

| Platform | Extension highlights | Reference |
|---|---|---|
| Claude Code | Invocation control, tool grants, model/effort, forked context, `!` injection | `references/platforms/claude-code.md` |
| Copilot / VS Code | `argument-hint`, `user-invocable`, experimental `context: fork` | `references/platforms/copilot-vscode.md` |
| OpenCode | `license`, `compatibility`, `metadata` map; unknown keys ignored | `references/platforms/opencode.md` |
| Cursor | `paths` file scoping, Custom Mode badge (`icon`/`color`), `metadata` | `references/platforms/cursor.md` |
| Codex | `license`, `compatibility`, `metadata` map | `references/platforms/codex.md` |
| Antigravity | Declarative JSON discovery (`skills.json`/`plugins.json`), agent scoping, hierarchical discovery | `references/platforms/antigravity.md` |
| Hermes Agent | Version/platform gating, tool requirements, env vars, blueprints | `references/platforms/hermes.md` |

Up-to-date sources: [Claude Code](https://code.claude.com/docs/en/skills),
[Copilot/VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills),
[OpenCode](https://opencode.ai/docs/skills/),
[Cursor](https://cursor.com/docs/skills),
[Codex](https://learn.chatgpt.com/docs/build-skills),
[Antigravity](https://antigravity.google/docs/skills/),
[Hermes Agent](https://hermes-agent.nousresearch.com/docs/developer-guide/creating-skills).

## Skill progressive disclosure

Skills use a three-level loading system to optimize agent context:

1. **Metadata** (`name` + `description` frontmatter) - always in context (~100 words).
2. **SKILL.md body** - loaded into context only when the skill triggers (<500 lines target).
3. **Bundled resources** (`references/`, `scripts/`, `templates/`) - loaded on demand by the agent as needed; unlimited size, and scripts can execute without being read.

### Progressive disclosure rules

- **Keep SKILL.md body under 500 lines**: When approaching this limit, move deep domain documentation into `references/` or templates into `templates/`.
- **Targeted reference pointers**: Provide explicit, conditional pointers in `SKILL.md` indicating *when* an agent should read a reference file (e.g. `See references/platforms/claude-code.md when deploying to Claude Code`). Never instruct the agent to "load all references upfront".
- **Prompt body composition**: For prompt body styling, imperative tone, RFC 2119 directives, calibrated specificity, negative constraints, and output contracts, consult and apply `ai-authoring-prompts`.


## Scripts

Python is the preferred language for bundled scripts.

**Zero external dependencies by default**: write against the standard
library. When a dependency is unavoidable, the skill must state how to
install it - prefer `uvx` so tools run in ephemeral environments without
polluting the host.

**Minimal and single-purpose**: each script does one task. Multi-step logic
gets split across separate scripts rather than growing flag combinations
inside one file.

**Shared modules over copies**: helpers used by several scripts live in an
importable module next to them, not duplicated per script.

**CRUD-prefixed names**: split scripts into `get-` / `list-` / `search-` /
`create-` / `update-` / `delete-` prefixed names (`get-status.py`,
`search-issues.py`, `delete-stack.py`). Reads are graded: `get-` fetches a
single item, `list-` returns a small premade set of options, and `search-`
exposes a robust query against a search syntax. Many agent platforms key
allow/deny rules on command prefixes, so this shape makes bulk policies such
as "allow all `get-*` and `list-*`, deny all `delete-*`" trivial to express.

**Accurate `--help`**: every script implements `--help` that matches its
real behaviour - it is the primary interface agents rely on.

**Token-efficient output**: return only what the caller needs - no extra
context rows, highlights, or decoration "while we're at it". A script
answering "what is the current git branch?" prints `main`, not the full
branch list with the current one highlighted.

**Source stays unread**: skills instruct agents to learn invocation from
`--help`, never by reading script contents before running. Reading source
wastes context tokens and tempts unnecessary edits.

**One runnable check**: non-trivial logic ships with an assert-based demo or
small test file - trivial one-liners are exempt.

## Skill categories & template selection

> **Note**: For universal prompt body design, cognitive architectures, persona archetypes, negative constraints, and output contracts, load and apply `ai-authoring-prompts`.

Before creating a skill, select the structural category template that matches the capability:

| Category | Use when | Template |
|---|---|---|
| Workflow / SOP | A multi-stage procedure that must run in order and produce evidence of completion | `templates/workflow-sop.md` |
| Guidelines / best practices | Static rules (style, security, performance) applied while writing/refactoring/reviewing code | `templates/guidelines.md` |
| Integration / tool-bound | Wraps an external CLI/API/MCP: env setup, connection checks, exact commands | `templates/integration-tool.md` |
| Subagent orchestrator | Decomposes work across parallel subagents and synthesizes their output | `templates/orchestrator.md` |
| Meta / self-improving | Authors, audits, or optimizes skills themselves | `templates/meta.md` |

Every skill body follows a consistent structural hierarchy: **Objective → When to Use → Procedure / Directives → What NOT to Do → Verification / Exit Criteria**.
- **Container structure**: Governed by this skill (`name`, `description`, `references/` and `scripts/` layout).
- **Prompt body contents**: Composed using patterns and archetypes from `ai-authoring-prompts`.


## Workflows

### Creation workflow

Figure out where the user already is - brand-new skill, draft in hand, or
improving an existing one - and jump in at that stage. Full path:

1. Capture intent: what the skill enables, when it triggers (literal user
   phrases), expected output format. For "turn this into a skill", extract
   answers from the conversation first (tools used, step order, user
   corrections, observed inputs/outputs) and confirm them with the user.
2. Interview: edge cases, input/output formats, example files, success
   criteria, dependencies. Research docs and similar skills in parallel via
   subagents where available; arrive prepared to reduce burden on the user.
3. Check existing coverage (`~/.agents/skills/`, workspace skill dirs) -
   extend, don't duplicate. Grep old names before any rename or move.
4. Draft: create folder + `SKILL.md` following the name rules and the
   closest category template. Write a pushy description (Description rules
   above - undertriggering is the default failure) and bundle only what the
   skill needs.
5. Re-read with fresh eyes: fix ambiguity, gaps, and over-fitting to the
   triggering example before validating.
6. Validate (below); fix and rerun until clean.
7. Wire discovery: symlink from platform directories (e.g.
   `.github/skills/`) where workspace-level discovery is needed.
8. Offer proof: run test cases per `references/evals.md` - skills with
   subjective outputs may skip them - then optionally optimize the
   description for triggering (same reference).

Stay flexible: a user who says "just vibe with me" gets a qualitative
review, not the full harness.

### Testing & evals

When the user wants proof a skill works - test prompts, graded runs, pass
rates, or trigger benchmarks - follow `references/evals.md`. It executes
every test case as a parallel subagent pair (with-skill vs baseline) so
results stay independent of this conversation's context, and it works on any
platform with native subagent spawning - no Claude Code CLI required.

### Validation workflow

Run after every create or edit, before wiring discovery or committing. The
validator is the backbone - extend it rather than growing manual steps it
could cover.

1. Trust-but-verify the tool once per session:
   `python3 scripts/validate.py --self-test`
2. Validate each touched skill: `python3 scripts/validate.py <skill-dir>`.
   This covers frontmatter shape, folder-name match, description cap, body
   length, referenced-resource existence, and compiles bundled
   `.py`/`.sh`/`.zsh` scripts.
3. Fix every FAIL and rerun until clean.
4. Manual checks the validator cannot make:
   - [ ] Description contains the literal phrases users type
   - [ ] No dangling references to renamed skills (grep old names)
   - [ ] Body read end-to-end: routing matches reality, no contradictions
         with the platform references
5. Validation proves structure, not behaviour: for evidence the skill
   triggers and works, continue to Testing & evals.

### Audit & improvement workflow

Use when a skill is reported as not triggering, when the user asks to
improve, merge, or split skills, or for periodic audits of a skill set.

1. Run the validation workflow above - clear structural faults first.
2. Trigger check: does the description carry the phrases users actually
   type plus near-miss contexts? If triggering is the complaint, jump
   straight to description optimization in `references/evals.md`.
3. Body review, reading end-to-end for:
   - Over-fitting to the example that prompted the skill - generalize; the
     skill must work for prompts nobody has typed yet
   - MUST-stacking where one sentence of "why" would survive edge cases
     better than rigid commands
   - Dead weight - cut sections that are not pulling their weight
   - Work repeated across invocations that belongs in `scripts/`
4. Structure decision:
   - Merge when two skills always trigger together or share most of their
     body; split when one skill serves two distinct trigger domains
   - An externally-installed skill overlapping a locally-managed one loses:
     the local skill wins and the external copy is removed
5. Report with this exact template:

   # [Skill name] audit
   ## Trigger check
   ## Structure findings
   ## Recommended actions

6. Close the loop: apply improvements, validate again, and for behavioural
   changes rerun the test cases (`references/evals.md`, iteration step) so
   numbers confirm the edit helped rather than assuming it did.