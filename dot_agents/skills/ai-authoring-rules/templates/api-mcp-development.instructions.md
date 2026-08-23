---
applyTo: "**/mcp/**/*,**/server/**/*,**/*mcp*.ts,**/*mcp*.py,**/*mcp*.php"
description: "Model Context Protocol (MCP) server design, tool declarations, transport, and error handling standards."
---

<!-- Source: https://github.com/github/awesome-copilot/blob/main/instructions/php-mcp-server.instructions.md -->

# MCP Server & Tool Development Standards

## Tool Schema Design

- **Self-Describing Schemas**: Every tool must provide clear `name`, `description`, and strictly typed JSON Schema parameter definitions.
- **Granular Tool Responsibilities**: Each tool should execute a single, well-defined capability rather than an arbitrary command runner.
- **Idempotency**: Read and query tools must be idempotent with zero side-effects.

## Error Handling & Transports

- **Transport Agnostic**: Support both `stdio` and `SSE` (Server-Sent Events) transports cleanly.
- **Meaningful Error Messages**: Return informative error strings in tool responses instead of crashing the server process.
- **Security Sandboxing**: Validate all file paths, shell arguments, and external URLs before processing to prevent path traversal or SSRF.
