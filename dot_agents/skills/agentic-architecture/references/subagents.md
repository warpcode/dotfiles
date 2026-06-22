# Subagents reference

## What a subagent is

A subagent is a specialised AI agent that handles a specific task within a
larger workflow. The main agent delegates work to it; the subagent runs in
its own context window, completes the task, and returns a result. The main
agent never loses its own context — only the summary comes back.

Subagents are supported natively by many agent frameworks and tools. The
concept is consistent across all of them; only the definition format and
invocation mechanism differs per tool. Consult your framework's documentation
for implementation specifics.

## When to use a subagent

Use a subagent when ANY of these hold:

**Verbose output you don't need in main context.** Running tests, fetching
docs, scanning logs — the subagent does the work and returns only the relevant
summary. The raw output never touches the main agent's context window.

**Clean context improves quality.** The main agent has accumulated context
(raw fetched content, generation reasoning, prior results) that would degrade
a focused sub-task. Give that task a fresh start with only what it needs.

**Tool or permission restriction required.** The sub-task should only be able
to read, not write — or needs access to a specific tool or MCP server that
shouldn't be available in the main session.

**Reusable specialised worker.** The same kind of task recurs across different
workflows. Define it once, describe it well, and the main agent delegates
automatically whenever that task type appears.

**Parallel work.** Multiple independent investigations or operations can run
simultaneously, with results synthesised by the main agent afterward.

## When NOT to use a subagent

- Tasks needing frequent back-and-forth or iterative refinement — keep in the
  main conversation where context is shared
- Tasks that share significant state across phases — the subagent has no
  access to the main agent's conversation history
- A single tool call or trivial operation — overhead is not justified
- When latency matters — subagents start fresh and may need time to gather
  their own context before doing useful work

Note: most frameworks do not allow subagents to spawn further subagents.
Chain them from the main agent instead.

## Designing a subagent

### System prompt

The system prompt is the subagent's only instruction source. It receives no
history from the main conversation.

> **Dependency:** Load `/mnt/skills/user/prompt-engineering/SKILL.md` before
> writing subagent system prompts.

Key rules:
- Pass only the context the subagent needs — define it explicitly in the prompt
- Specify the output schema so the main agent can parse the result without
  interpretation
- MUST NOT assume any context from the main conversation — the subagent has none
- State tool constraints and how the subagent should use them

### Description / delegation trigger

Most frameworks use a description field to decide when to delegate. This is
the primary trigger mechanism — write it to be specific about when the subagent
should run, not just what it does.

```
# Weak — too vague
description: Handles link resolution

# Strong — specific trigger condition
description: Resolves wikilinks between notes in an Obsidian vault. Use when
  a new note has been generated and needs forward and backlinks resolved
  against the existing vault. Invoke proactively after any note generation step.
```

### Handoff design

Design the interface between main agent and subagent deliberately.

**Pass in:** the minimum context the subagent needs — structured data (JSON,
markdown) rather than prose where possible.

**Receive back:** a structured result the main agent can apply directly — a
patch or diff rather than a full rewrite where appropriate.

**Example — link resolver:**
```
IN:  new note content (markdown)
     + vault index (title, path, summary per existing note)

OUT: {
       "forward_links": [{"line": 12, "link": "[[Existing Note Title]]"}],
       "backlink_patches": [{"file": "path/to/note.md",
                             "insert_after": "## References",
                             "link": "[[New Note]]"}]
     }
```

### Model selection

Many frameworks allow specifying a cheaper or faster model for subagents.
Use a lighter model for focused, well-scoped tasks (search, extraction,
classification). Reserve the full model for tasks requiring deeper reasoning.

## Subagent vs inline step vs skill

| Factor | Subagent | Inline step | Skill |
|---|---|---|---|
| Context isolation needed | Yes | No | N/A |
| Task produces verbose output | Yes | No | N/A |
| Tool or permission restrictions needed | Yes | No | No |
| Reusable specialised worker | Yes | No | No |
| Recipe / conventions for main agent | No | No | Yes |
| Single tool call | No | Yes | No |
| Runs in main agent's context | No | Yes | Yes |
