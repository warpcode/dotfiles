---
applyTo: "**"
description: "Core security, governance, and least-privilege guardrails for AI agents and automated pipelines."
---

<!-- Source: https://github.com/github/awesome-copilot/blob/main/instructions/agent-safety.instructions.md -->

# Agent Safety & Governance

## Core Principles

- **Fail Closed**: If a governance policy check is ambiguous or encounters an error, deny the action rather than allowing it.
- **Least Privilege**: Grant the minimum tool access, environment variables, and shell permissions required for the immediate task.
- **Immutable Audit**: Never modify, overwrite, or delete audit trails, command history, or decision logs.
- **Zero Secret Exposure**: Never write plaintext secrets, API keys, credentials, or session tokens into source files, commit messages, or chat responses.

## Tool Access Controls

- Explicitly allowlist tools for each agent role; never provide unrestricted shell or file execution by default.
- Gate high-impact actions (file deletion, remote database mutations, force pushing, deploying) behind explicit user confirmation.
- Filter and sanitize shell command strings to prevent command injection and accidental recursion.

## Multi-Agent Boundaries

- When an orchestrator delegates to a subagent, the subagent must operate under the most restrictive policy of either agent.
- Subagents must not spawn further nested subagents unless explicitly architected as a hierarchical supervisor.
- Tasks passed to subagents must be self-contained with concrete file paths and strict output schemas.
