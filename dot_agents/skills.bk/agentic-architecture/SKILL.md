---
name: agentic-architecture
description: >
  Decide when to use a skill, MCP server, subagent, or standalone pipeline when
  designing or building agentic workflows. Use this skill whenever the user asks
  how to structure an automation, agent, or multi-step AI workflow; says things
  like "should I use a skill or MCP", "when do I need a subagent", "how do I
  architect this", "where does LangChain fit", or describes a workflow requirement
  and needs to know what building blocks to reach for. Also trigger when designing
  any new Claude Code workflow, even if the user does not explicitly ask for
  architectural advice — if a workflow is being designed, this skill applies.
---

# Agentic architecture

> **Dependency:** Reference files in this skill contain LLM-facing instructions.
> Load `prompt-engineering` skill before editing any of them.

## The four primitives

| Primitive | What it is | Executes? | Persists? |
|---|---|---|---|
| **Skill** | Markdown recipe Claude reads into context | No | No — loaded per invocation |
| **MCP server** | Tool Claude calls at runtime | Yes | Yes — connected once, reusable |
| **Subagent** | Specialised agent that runs in its own context window and returns a result | Yes | No — isolated per invocation |
| **Standalone pipeline** | Independent process (Python, LangChain, cron) | Yes | Yes — runs outside any AI context |

---

## Decision tree

```
Does the workflow need a convention, recipe, or set of rules for Claude to follow?
  YES → Skill
  NO  ↓

Is this a reusable capability or external integration any workflow might call?
  YES → MCP server
  NO  ↓

Would a clean context window, parallelism, or semantic isolation improve quality?
  YES → Subagent
  NO  ↓

Must this run unattended, on a schedule, or without an AI agent in the loop?
  YES → Standalone pipeline
  NO  → Tool call or inline step in the main agent
```

### Tiebreaker: skill-bundled script vs MCP server

IF a script is only ever called from one specific skill THEN bundle it in that skill's `scripts/` directory.

IF anything outside that skill would ever call it THEN it MUST be an MCP server.

Test: *"Would another skill, subagent, or workflow ever want this?"* Yes → MCP. No → bundle.

---

## Quick-reference: common patterns

| Scenario | Recommendation |
|---|---|
| Coding conventions, style guides | Skill |
| Workflow recipe with fixed steps | Skill |
| Read/write Obsidian vault | MCP server (`obsidian-mcp`) |
| Fetch web pages | MCP server (`fetch`) |
| Fetch YouTube transcripts | Bundled script (skill-specific) |
| Link resolution across a vault | Subagent (clean context + parallelisable) |
| Parallel processing of N inputs | Subagents (one per input) |
| Scheduled ingestion without human in loop | Standalone pipeline |
| Complex retrieval chain with vector store | Standalone pipeline (LangChain or SDK) |

---

## Context cost awareness

Every connected MCP server adds its tool schemas to context — even when not called. Every skill loaded adds its body to context.

SHOULD audit connected MCPs and loaded skills when context is constrained.
MUST NOT connect MCPs speculatively — connect when a workflow requires them.

---

## Worked example: Obsidian web ingestion

**Requirement:** fetch URLs and YouTube videos, generate markdown notes, link to existing vault documents.

```
fetch MCP          → fetches web pages
obsidian-mcp       → reads vault index, writes notes, patches backlinks
yt-transcript.sh   → bundled in skill (only this workflow uses it)
obsidian-web-ingest skill → recipe: content detection, note schema, placement logic
link-resolver      → subagent: clean context, vault index, returns link patch
```

The link resolver is a subagent because: (1) main agent context contains raw
web content and generation reasoning the resolver doesn't need; (2) link
resolution is semantically distinct from note generation; (3) batch ingestion
can parallelise resolvers trivially.

---

## Reference files

Read the relevant file when you need detail on a specific primitive.

| Topic | File |
|---|---|
| Writing a skill, bundled scripts, progressive disclosure | `references/skills.md` |
| When to build vs reuse an MCP, context cost, common servers | `references/mcp-servers.md` |
| When to use subagents, handoff design, system prompt rules | `references/subagents.md` |
| Standalone pipelines, LangChain, scheduling, invoking from agents | `references/pipelines.md` |
