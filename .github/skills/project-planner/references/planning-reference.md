# Project Planning Reference Guide

Unified reference for formulating requirements, architectural decisions, tasks, and retrospective context in `SPEC.md` and `DECISIONS.md`.

---

## 1. Requirements Syntax (RFC 2119 & EARS)

When formulating `REQ-*` items, use unambiguous EARS (Easy Approach to Requirements Syntax) patterns with normative keywords (`SHALL`, `MUST`, `SHALL NOT`):

| Pattern | Template | Example |
|---|---|---|
| **Ubiquitous** (Always Active) | `The <component> SHALL <behavior>.` | The daemon SHALL log all requests in JSON. |
| **Event-Driven** (Triggered) | `WHEN <trigger>, the <component> SHALL <response>.` | WHEN a token expires, the client SHALL refresh credentials. |
| **State-Driven** (While in Condition) | `WHILE <in state>, the <component> SHALL <behavior>.` | WHILE connected to battery, the service SHALL poll every 60s. |
| **Unwanted Behavior** (Guardrail / Fault) | `IF <fault or invalid input>, THEN the <component> SHALL <action>.` | IF the payload exceeds 10 MB, THEN the server SHALL reject with 413. |

### MoSCoW Prioritization
- **`[P0 / Must Have]`**: Non-negotiable core capability required for milestone exit.
- **`[P1 / Should Have]`**: High-value feature with a viable short-term workaround.
- **`[P2 / Could Have]`**: Desirable enhancement; first to be cut under pressure.
- **`[Won't Have]`**: Record as an explicit `NG-*` (Non-Goal), not an active requirement.

---

## 2. Architecture Decisions & Decision Trees

### Decision Drivers
Rank the forces acting on the system before choosing an option:
- **P0 (Non-Negotiables)**: Hard security, isolation, data integrity, or compliance constraints.
- **P1 (Differentiators)**: Token economy, latency, maintainability, developer ergonomics.
- **P2 (Tie-Breakers)**: Familiarity, ecosystem conventions.

### Canonical ADR Statement
Every `ADR-*` under `docs/adr/` follows the canonical MADR statement:
> *In the context of **[scope / component]**, facing **[constraints / forces]**, we decided to **[chosen option]** to achieve **[primary benefit]**, accepting **[trade-off / cost]**.*

### Required Fields for `ADR-*`
1. **Depends On**: Upstream `REQ-*` that forces this decision.
2. **Reversibility**: One-way door (costly/irreversible) vs. two-way door.
3. **Fitness Function**: Exact automated test, linter, or check proving ongoing compliance.
4. **Rejected / Ruled Out**: Every viable alternative (including "do nothing") and why it was rejected.

### Decision Trees (`DT-*`)
Use when defining deterministic branching rules:
- `IF <condition> -> <target>; ELSE IF <condition> -> <target>; ELSE -> <default>`.
- Downstream tasks reference `DT-*` in their `Depends On` field.

### ADR Lifecycle & Supersession Rules
- **`Proposed`**: Under active scrutiny or awaiting plan approval; not yet binding.
- **`Accepted`**: Binding constraint enforced across all current and future plans.
- **`Accepted (Retrospective)`**: Extracted from existing code/history with source provenance.
- **`Superseded by ADR-xxxx`**: Never edit an accepted ADR's decision in place. Author a new ADR with the next sequential number, mark the old one `Superseded by ADR-xxxx`, flag all dependent requirements `Needs Review`, and append a revision entry.
- **Durability**: Plans finish and are archived, but accepted ADRs remain permanently active repository law until explicitly superseded.

---

## 3. Context-Free Tasks & Sizing (`TSK-*`)

Every task must be executable by an isolated engineer or subagent without prior conversational context:
1. **Explicit File Targets**: Name exact repository paths, scripts, or schemas.
2. **Traceability**: Link to the `REQ-*` it fulfills and the `ADR-*` it obeys.
3. **Evidence Tracking**: Record `- **Evidence**: [PR #...](url) · Commit `sha` · [Ticket ...](url)` upon completion. PRs and issue tracker tickets should be formatted as clickable markdown links; Git commit SHAs are recorded as code literals (no link needed).
4. **Git Trailer Linking**: Tag commit messages and PR bodies with `Plan: <slug>:<TSK-xxx>` to enable zero-hunting auto-discovery.

### 3-Factor Sizing Heuristic (Complexity, Effort, Uncertainty)

| Complexity | Effort | Uncertainty | Estimate | Action |
|---|---|---|---|---|
| Low | Small | Low | **0.5 pt** | Consolidate into parent task if trivial. |
| Low–Med | Small–Med | Low | **1.0 pt** | Ideal single-PR vertical slice. |
| Medium | Medium | Low–Med | **2.0–3.0 pt** | Multi-file slice; keep within one milestone. |
| Any | Large | High | **5.0+ pt** | **Too large**: split into a spike (`ADR`/`DT`) + smaller tasks. |

---

## 4. Retrospective Context Extraction

When documenting existing work retrospectively (Workflow C), extract evidence without guessing:

| Evidence Source | Extracted Field | Maps To |
|---|---|---|
| Epics, roadmap docs, READMEs | Problem statement, intended outcomes | Charter, `G-*` |
| "Won't do" / closed tickets, README limitations | Explicit exclusions | `NG-*` |
| Feature tickets, user stories, specs | Behavior and acceptance criteria | `REQ-*` |
| Design docs, PR discussions, commit rationales | Choice made and alternatives | `ADR-*` (with Rejected field) |
| Closed unmerged PRs, rejected RFCs | Ruled-out proposals | `REJ-*` |
| Releases, tags, milestone boards | Phases and what shipped | `M-*` |
| Open tickets / TODOs | Remaining work | `TSK-*` or `Q-*` |
| Incidents, bug clusters, known limitations | Hazards | `RSK-*` |

- Cite **Source** for every item (`jira://KEY-123`, `gh://owner/repo#45`, commit SHA).
- Mark items as `Accepted (Retrospective)`. Gaps (missing AC, unverified assumptions) become `Q-*` items.
