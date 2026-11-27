---
name: <domain>-<topic>
description: >
  Domain knowledge centre for [Topic/Tool]. Use when [literal user trigger
  phrases, file types, or CLI workflows].
---

# <Domain> Knowledge Centre

Concise routing hub for [Topic/Tool]. Deep reference material lives in `@references/` and deterministic operations live in `@scripts/`.

## Core Invariants

- [Invariant 1 — e.g., never mutate state before verifying current target]
- [Invariant 2 — e.g., prefer bundled black-box script over multi-call shell chains]
- [Invariant 3 — e.g., report unreadable fields as gaps rather than inferring pass]

## Routing Hub

| Need | Resource | Load / Run When |
|---|---|---|
| Architecture & domain rules | `@references/<topic>.md` | Designing, refactoring, or reviewing `<domain>` |
| Platform / API specifics | `@references/<api-or-platform>.md` | Checking flags, schemas, or edge cases |
| Deterministic data gather / action | `@scripts/<name>.py` | Gathering state or applying a repeatable check |
| Structured output schema | `templates/<output>.md` | Producing a report, diff, or audit summary |

## Black-Box Scripts

*(Omit this section for pure Knowledge Centre skills with no bundled scripts.)*

Run scripts relative to `<skill-dir>/scripts/` with `--help` before inventing ad-hoc commands:

| Script | Invocation | Purpose |
|---|---|---|
| `<name>.py` | `python3 <skill-dir>/scripts/<name>.py --help` | [Single-call gather or deterministic check; report-only by default] |

## Common Pitfalls

Keep entries timeless (no dated session logs or chronological anecdotes):

- **Symptom**: [Observable failure] — **Cause**: [Underlying mechanism] — **Fix**: [Surgical resolution or script flag]

## Validation Gate

- Run `[project validation or test command]` and verify zero errors before declaring done.
