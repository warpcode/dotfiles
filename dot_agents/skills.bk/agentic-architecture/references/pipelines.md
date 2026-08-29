# Standalone pipelines reference

## What a standalone pipeline is

A standalone pipeline is a process that runs entirely outside any AI agent's
context window. It is a Python script, a Node.js program, a cron job — invoked
from a shell, a scheduler, or a webhook. No AI assistant reads it or loads it
into context. It orchestrates its own LLM calls (if any) via the API directly.

## LangChain — the key clarification

LangChain is a Python (or JS) framework for orchestrating LLM pipelines. It is
NOT a tool Claude calls. It is NOT loaded into context. It does NOT integrate
with skills or MCP servers.

```
Claude Code / Gemini CLI / VS Code Copilot
        │
        │  shell out (Bash tool or terminal)
        ▼
  python pipeline.py --url "https://..."
        │
        │  LangChain orchestrates internally
        ▼
  [fetch] → [chunk] → [embed] → [LLM call] → [write output]
```

An agent can invoke a pipeline by running a shell command via the Bash tool.
A skill can instruct Claude to run `python pipeline.py` with appropriate
arguments. But LangChain itself runs as a separate OS process.

Gemini CLI, VS Code Copilot, and Aider all invoke pipelines the same way:
by executing a shell command. None of them "call" LangChain natively.

## `claude -p` (non-interactive mode) — also a pipeline pattern

`claude -p` invokes the Claude CLI as a subprocess. This is headless/
non-interactive mode — the CLI runs, processes a prompt, and exits. It is
NOT the same as a Claude Code subagent (which is a `.claude/agents/*.md` file
running inside Claude Code's native delegation system).

Use `claude -p` for:
- CI/CD pipelines that need Claude to perform a task as part of a build step
- Automation scripts that call Claude without a human in the loop
- Chaining Claude invocations from shell scripts

This is a standalone pipeline pattern, not a subagent. See `references/subagents.md`
for the correct subagent definition.

## When to use a standalone pipeline

Use a standalone pipeline WHEN:
- The workflow MUST run unattended, on a schedule, or without a human in the loop
- The orchestration logic is complex enough to warrant version-controlled code
- You need LangChain-specific features: persistent vector stores, retrieval
  chains, document loaders, agent memory across sessions
- The pipeline will be triggered by external events (webhooks, cron, CI)
- You want to run the same pipeline from multiple different agents or tools

SHOULD NOT use a standalone pipeline WHEN:
- A skill + MCP server + subagent covers the requirement with less complexity
- The pipeline will only ever be triggered interactively by a human in Claude Code

## When standalone pipeline beats subagent

| Factor | Standalone pipeline | Subagent |
|---|---|---|
| Runs on a schedule | Yes | No |
| Runs without any AI agent present | Yes | No |
| Needs persistent vector store / memory | Yes | No |
| Triggered by webhook or CI event | Yes | No |
| Complex retrieval chain | Yes | Sometimes |
| One-off isolated task | No | Yes |
| Spawned by a main agent at runtime | No | Yes |

## Invoking a pipeline from an agent

A skill can instruct Claude to shell out to a pipeline:

```bash
python ingest.py \
  --url "{{URL}}" \
  --vault "{{VAULT_PATH}}" \
  --output-format json
```

The agent runs this, captures stdout, and uses the result. The pipeline is
responsible for its own LLM calls, chunking, embedding, and storage — the
agent just hands it inputs and receives outputs.

## Deciding between LangChain and plain SDK

Use LangChain WHEN:
- You need its built-in document loaders, text splitters, or vector store integrations
- You are building retrieval-augmented generation (RAG) with an existing chain
- Team members are already familiar with LangChain's abstractions

Use the plain Anthropic SDK WHEN:
- The pipeline is simple (fetch → summarise → write)
- You want minimal dependencies and full control
- LangChain's abstractions add more complexity than they remove

For the Obsidian web ingestion use case: the plain SDK is sufficient. LangChain
earns its keep when you need a persistent vector index or complex RAG — neither
of which is required for structured note generation.

## Minimal pipeline skeleton (plain SDK)

```python
import anthropic
import sys

client = anthropic.Anthropic()

def ingest(url: str, vault_path: str) -> dict:
    content = fetch(url)
    note = generate_note(client, content)
    links = resolve_links(client, note, vault_path)
    write_note(vault_path, note, links)
    return {"status": "ok", "path": note["path"]}

def generate_note(client, content: str) -> dict:
    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=2000,
        messages=[{"role": "user", "content": f"Generate a note from:\n\n{content}"}]
    )
    return parse_note(response.content[0].text)

if __name__ == "__main__":
    result = ingest(sys.argv[1], sys.argv[2])
    print(result)
```
