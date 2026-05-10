# MCP servers reference

## What an MCP server is

An MCP server exposes tools Claude can call at runtime. Tool schemas are loaded
into context when the server is connected; the tools execute only when called.
MCP servers are persistent, reusable, and decoupled from any particular skill
or workflow.

## When to use an MCP server

- External integrations: file systems, APIs, databases, browsers
- Capabilities multiple workflows or agents need independently
- Operations that need to persist state between calls (e.g. a session, a cache)
- Any tool where "would anything else ever call this?" answers YES

## When NOT to use an MCP server

- The operation is only ever called from one specific skill → bundle as script
- The operation is a one-off shell command with no reuse → shell out directly
- You are describing rules or conventions → use a skill instead

## Context cost

Every connected MCP server adds its tool schemas to Claude's context window —
even when no tools are called. This is non-trivial for servers with many tools.

MUST NOT connect MCP servers speculatively.
SHOULD disconnect servers not needed for the current workflow.
SHOULD prefer narrow, focused MCP servers over broad ones when context is constrained.

## Common servers

| Server | Purpose | Notes |
|---|---|---|
| `fetch` | Fetch web pages and URLs | Standard, built into Claude Code |
| `obsidian-mcp` | Read/write Obsidian vault | Install separately |
| `github` | Repo operations, PRs, issues | Official GitHub MCP |
| `filesystem` | Local file read/write | Use carefully — broad access |
| `brave-search` | Web search | Alternative to fetch for discovery |
| `puppeteer` / `playwright` | Browser automation | For JS-rendered pages |

## Building a new MCP server

Build a new MCP server WHEN:
- No existing server covers the integration you need
- The capability would be called by more than one workflow

SHOULD NOT build a new server for a one-workflow operation — use a bundled
script until a second caller emerges, then extract.

### Minimal MCP server structure (Node.js)

```js
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

const server = new Server({ name: 'my-server', version: '1.0.0' });

server.setRequestHandler('tools/list', async () => ({
  tools: [{
    name: 'my_tool',
    description: 'What this tool does, one sentence.',
    inputSchema: {
      type: 'object',
      properties: { param: { type: 'string', description: 'What param is' } },
      required: ['param']
    }
  }]
}));

server.setRequestHandler('tools/call', async (req) => {
  if (req.params.name === 'my_tool') {
    const result = doWork(req.params.arguments.param);
    return { content: [{ type: 'text', text: result }] };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

### Tool description quality

Tool descriptions are LLM-facing text. Apply prompt engineering rules:

> **Dependency:** Load `/mnt/skills/user/prompt-engineering/SKILL.md` before
> writing tool descriptions.

Key rules:
- One sentence per tool description — what it does and when to call it
- Parameter descriptions MUST state type, format, and constraints explicitly
- MUST NOT duplicate parameter names in description prose — the schema already has them
