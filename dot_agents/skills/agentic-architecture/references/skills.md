# Skills reference

## What a skill is

A skill is a markdown file Claude reads into its context window. It contains
instructions, conventions, recipes, and decision logic written in natural
language. It does not execute. It changes how Claude reasons and acts.

Skills use a three-level loading system:

1. **Metadata** (name + description) — always in context, ~100 words
2. **SKILL.md body** — loaded when the skill triggers, target <500 lines
3. **Bundled resources** — read on demand; scripts can execute without loading

## Anatomy

```
skill-name/
├── SKILL.md              ← required; frontmatter + instructions
├── scripts/              ← executable helpers tightly coupled to this skill
├── references/           ← reference docs loaded as needed
└── assets/               ← templates, fonts, static files used in output
```

## When to use a skill

- Coding conventions or style guides Claude should follow
- Workflow recipes: fixed sequences of steps, decision logic
- Domain-specific rules that apply within a bounded context
- Anything that shapes *how Claude behaves*, not what it can call

MUST NOT use a skill for capabilities that other workflows need — use MCP instead.

## Bundled scripts

A script belongs in `scripts/` IF AND ONLY IF:
- It is only ever invoked from this skill's workflow
- Nothing outside this skill would call it
- It performs a bounded, deterministic operation (transform, extract, render)

IF a script has broader utility THEN extract it to an MCP server.

### Example: appropriate bundled script

`yt-transcript.sh` in `obsidian-web-ingest/scripts/` — wraps `yt-dlp` to
extract transcripts. Only the web ingestion workflow calls it. Correct as
a bundled script.

### Example: should be MCP instead

A script that reads and writes Obsidian vault files. Multiple workflows
(note creation, link resolution, search) need vault access. MUST be MCP.

## Progressive disclosure

Keep `SKILL.md` body under 500 lines. When approaching that limit:

- Move detailed reference material to `references/`
- Add a table in SKILL.md pointing to each reference file and when to read it
- Move large examples to `references/` with a summary inline

Claude reads only the reference files it needs for the current task.

## Writing good skill instructions

> **Dependency:** Load `/mnt/skills/user/prompt-engineering/SKILL.md` before
> writing or editing skill instructions.

Key rules that apply directly to skill content:

- Use `MUST` / `SHOULD` / `MAY` for obligation levels — not "please" or "try to"
- Every `MUST NOT` MUST be paired with the replacement behaviour
- Use IF/THEN for conditional logic; pseudocode if nesting exceeds 2 levels
- State each rule once — duplication in skills causes conflicting behaviour
- Put trigger conditions in the frontmatter `description`, not the body

## Skill description (frontmatter)

The description is the primary trigger mechanism. Claude decides whether to
load a skill based on this field alone.

MUST include: what the skill does AND specific contexts that should trigger it.
SHOULD be slightly "pushy" — name the concrete phrases that should trigger it.
MUST NOT put "when to use" logic in the body — it belongs in the description.

## Multi-domain skills

When a skill covers multiple variants (e.g. AWS vs GCP, bash vs zsh), organise
by variant in `references/`:

```
cloud-deploy/
├── SKILL.md          ← workflow + selection logic
└── references/
    ├── aws.md
    ├── gcp.md
    └── azure.md
```

SKILL.md selects the relevant reference; Claude reads only that file.
