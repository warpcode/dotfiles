# Architecture Decision Records (ADRs) & Decision Trees Guide

Guidelines for formulating architectural decisions (`ADR-*`), classification trees (`DT-*`), and rejected alternatives (`REJ-*`) in `DECISIONS.md`.

---

## 1. Decision Drivers & Prioritization

Before selecting an architectural option, rank the forces acting on the system:
- **P0 (Non-Negotiables)**: Hard security, isolation, compliance, or platform constraints (e.g., zero host filesystem mounts, no secret leakage into logs).
- **P1 (Differentiators)**: Token efficiency, latency, maintainability, developer ergonomics.
- **P2 (Tie-Breakers)**: Familiarity, ecosystem conventions.

---

## 2. Canonical ADR Formulation

Every `ADR-*` item in `DECISIONS.md` should follow the canonical decision statement:

> *In the context of **[scope / component]**, facing **[constraints / forces]**, we decided to **[chosen option]** to achieve **[primary benefit]**, accepting **[trade-off / cost]**.*

### Required Fields for an `ADR-*` entry (see `templates/DECISIONS.md`)
1. **Title**: Action-oriented noun phrase (e.g., `Ephemeral Stdio MCP Containers Over Persistent Daemons`).
2. **Statement**: The canonical decision sentence and strict invariant rule.
3. **Rationale**: The P0/P1 drivers.
4. **Fitness Function**: The automated test, linter, or check that proves compliance.
5. **Rejected / Ruled Out**: Every viable alternative considered (including "do nothing") and the concrete reason it was ruled out.
6. **Reversibility**: One-way doors (costly to undo) always need an ADR; two-way doors may not.

---

## 3. Decision Trees (`DT-*`)

Use a `DT-*` entry when establishing a repeatable classification rule (for example, routing capabilities between **Skills**, **MCP Servers**, and **Isolated Agents**).
- Express the branching logic deterministically (`IF <condition> -> <target>; ELSE IF <condition> -> <target>; ELSE -> <default>`).
- Downstream items list the tree in **Depends On** (`DT-001`) so that changing the rule surfaces them in the Workflow B blast-radius check.

---

## 4. Lifecycle States & Supersession

- **`Proposed`**: Under active scrutiny; not yet binding.
- **`Accepted`**: Active constraint enforced across the plan and all its `features/` children.
- **`Accepted (Retrospective)`**: Extracted from existing work, with a **Source** link (file, commit, ticket).
- **`Superseded by ADR-xxx`**: Never edit an accepted ADR's decision in place. Add a new ADR with the next ID, mark the old one `Superseded by ADR-xxx`, mark its dependents `Needs Review`, and append a `REVISIONS.md` row. Superseded entries stay in `DECISIONS.md` for history but are no longer binding.
