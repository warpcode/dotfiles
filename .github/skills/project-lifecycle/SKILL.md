---
name: project-lifecycle
description: Guide requested project work through requirements, planning, implementation, verification, and review. Use when coordinating multiple phases of a project task; create tickets, delegate, or merge only when explicitly requested.
---

# Project Lifecycle Orchestrator

Coordinate only the project phases the user requests, keeping scope, approvals,
verification, and review boundaries explicit. Do not require a particular
subagent roster: discover available agents first, delegate only to agents that
exist and are appropriate, and perform the work in the current context when none
are available. Ticket creation, external writes, and merging are opt-in phases,
not defaults.

---

## 🚀 Lifecycle Phases

### Phase 1: Requirements & Planning
1. Clarify missing requirements only when they materially affect implementation.
2. Use `task-planning` when the user asks for a plan or tickets; otherwise keep planning proportional to the request.
3. Present significant scope or external-impact decisions for approval before acting.

### Phase 2: Actionable Ticket Creation
Create tickets only when the user requests ticketing. For external issue creation,
use `github-cli` or the relevant integration and obtain approval before writing.

### Phase 3: Code Implementation
Implement only the requested changes. Use an available implementation agent if
delegation is appropriate; otherwise work in the current context. Run focused
verification after each meaningful change.

### Phase 4: Specialist Auditing & Code Review (When Requested)
1. Run a focused audit when review is requested or needed for an approved merge.
2. Load relevant skills such as `code-review`, `code-security-audit`,
   `database-architecture`, or `shell-scripting` based on the changed surface.
3. Delegate independent read-only checks only to available agents; synthesize
   findings and address issues within the approved scope.

### Phase 5: Verification & Merge (Merge Is Opt-In)
1. Verify code changes as appropriate; pre-merge checks apply when a PR exists.
2. Check local verification and, when a PR exists, inspect its CI and review state.
3. Create or merge a PR only when explicitly requested and after presenting the
   exact action for approval. Remote branch deletion requires separate approval.

---

## 🧠 Operational Guardrails
- **Strict Separation of Concerns**: Match delegated tasks to the actual agent's declared role and permissions.
- **Traceability**: Keep a concise progress record in the conversation. Create a workspace log only when requested or necessary for a multi-session project.
- **Strict Neutrality**: All communication and outputs must follow the workspace guidelines: neutral, technical tone, without conversational fluff.
