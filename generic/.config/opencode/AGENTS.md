## Rules (MANDATORY)
- Rule 1 — Agent Priority: Prefer specialized agents (subagents) over manual work where appropriate.
- Rule 2 — Agent Verification: Verify a specialist/subagent fits the task before starting manual work.
- Rule 3 — Skill Loading: Search for and load relevant skills/tools before any task.
- Rule 4 — Git Safety: Do NOT commit or push without explicit user consent.
- Rule 5 — Rule Citation: Cite the specific rule(s) relied upon when making decisions.
- Rule 6 — Skill Prompt Fidelity: If a loaded skill returns a prompt/instruction, read and understand it before acting; follow any referenced file-read instructions.
- Rule 7 — Reference Verification: When a skill/doc is used, explicitly read referenced files (using the Read tool) and record the exact paths in your pre-task checklist.
- Rule 8 — Concise Responses: Reply concisely; avoid unnecessary repetition unless the user requests more detail.

## Enforcement
- Mandatory rule checks: Before any task, state which rule(s) apply and include the pre-task checklist (see below).
- Skill loading: Load and confirm required skills/tools before making changes.
- Agent verification: Evaluate whether a specialist agent should run the task and prefer it when applicable.
- Audit trail: When a skill or file is consulted, list file paths read and brief notes of what was learned.
- User oversight: Users may request compliance checks at any time (see Commands below).

## Commands
- "Check rules before proceeding"
- "Which rule applies here? Cite it"
- "Verify compliance"
- "Reload skills per Rule 3"
- "Show refs read"

## Pre-Task Checklist (MANDATORY)
Agents MUST include the following, concisely, as the first step of any task that reads or edits files:
1. Rules applied: (comma-separated rule numbers)
2. Skills/tools to use: (names)
3. Agents to be used: (subagent names or "none")
4. Compliance verification: (files/repo docs reviewed and method)
5. Skill references to read: (absolute file paths and 1-line note of what was learned from each)

Notes:
- The checklist must appear in an agent's first message that performs file reads or edits.
- Keep entries short — one-line items are preferred.

## Scope
- This file applies to the directory tree rooted at `~/.config/opencode`.
- More deeply nested `AGENTS.md` files override conflicting guidance.
- Repository-level and user-level AGENTS.md (if present) provide additional constraints and must be considered.

## Example
- Rules applied: Rule 1, Rule 3, Rule 4
- Skills/tools to load: `read`, `write`
- Agents to be used: none


