---
name: project-adr
description: >
  Author, evaluate, and maintain Architecture Decision Records (ADRs) using the
  MADR standard in docs/adr/. Use when making architectural choices, evaluating
  technical trade-offs, defining automated fitness functions, recording one-way
  doors, superseding existing ADRs, or maintaining the ADR registry.
user-invocable: false
---

# Project ADR

A procedure-only skill for authoring, evaluating, and maintaining Architecture Decision Records
(ADRs) in `<repo>/docs/adr/`. ADRs represent immutable historical records of why a specific
architectural choice was made and evolve with the codebase under version control.

## 1. The Role of ADRs

ADRs pass the **Rollback Test**:
> *"If I rolled back our application code by 6 months to fix a massive bug, should this document roll back with it?"*

- **ADRs outlive individual plans**: Plans are created, implemented, and archived. Accepted ADRs
  remain active repository law indefinitely until explicitly superseded.
- **One-Way vs. Two-Way Doors**: Any irreversible or costly technical choice (dependency selection,
  database engine, network boundaries, storage schemas) requires an accepted ADR before implementation.

## 2. Directory Layout & Numbering

All ADRs live in `docs/adr/` numbered sequentially with 4-digit zero-padding:

```text
docs/adr/
├── README.md                              # Registry table of all ADRs
├── 0001-record-architecture-decisions.md  # Foundational decision to record ADRs
├── 0002-standardize-on-madr.md            # Markdown Architectural Decision Records
└── 0003-static-warning-gate-for-evals.md
```

### Registry Table Format (`docs/adr/README.md`)

```markdown
| ADR | Status | Date | Title |
|---|---|---|---|
| [0001](0001-record-architecture-decisions.md) | Accepted | 2026-10-19 | Record architecture decisions |
| [0002](0002-standardize-on-madr.md) | Accepted | 2026-10-20 | Standardize on MADR |
```

Valid statuses: `Proposed`, `Accepted`, `Superseded by ADR-xxxx`, `Deprecated`.

## 3. Authoring Workflow (Step-by-Step)

### Step 1: Scan Existing Decisions
Before proposing a new architectural choice, read `docs/adr/README.md` to ensure the decision
does not conflict with or duplicate an accepted ADR.

### Step 2: Determine Next Sequential Number
Find the highest existing number in `docs/adr/` (e.g. `0005`) and increment it (e.g. `0006`).
Format file name as `0006-<kebab-case-slug>.md`.

### Step 3: Evaluate Forces & Trade-offs
Use the MADR template (`templates/adr.md`). Rank forces objectively:
1. **P0 (Non-Negotiables)**: Security isolation, secret handling, data integrity, compliance.
2. **P1 (Differentiators)**: Token economy, tool-call efficiency, latency, maintainability.
3. **P2 (Tie-Breakers)**: Familiarity, local conventions.

Formulate the canonical statement:
> *In the context of **[system/module scope]**, facing **[decision drivers / constraints]**, we decided to **[chosen option]** to achieve **[primary benefit]**, accepting **[consequence / trade-off]**.*

### Step 4: Define an Automated Fitness Function
Every accepted ADR must define an automated command (linter, unit test, or static check) that fails
CI if the decision is breached. Do not accept an ADR with a vague or manual verification step.

### Step 5: Update the Registry Index
Add the new ADR entry to `docs/adr/README.md`.

## 4. Superseding an ADR

When an existing decision must change:
1. **Do not rewrite the old ADR**: Past git commits rely on the old ADR to explain their rationale.
2. **Author a new ADR** with the next sequential number.
3. **Set Cross-References**:
   - In the new ADR: `Supersedes: [ADR-0002](0002-slug.md)`.
   - In the old ADR: update header to `Status: Superseded by [ADR-0006](0006-slug.md)`.
4. **Update `docs/adr/README.md`** to reflect the new status.
5. **Audit Active Plans**: Check active specifications in `docs/plans/` that depend on the old ADR
   and flag affected requirements as `Needs Review`.

## 5. Templates & References

- **Template**:
  - `templates/adr.md` — Canonical MADR template with forces, trade-offs, and fitness functions.
- **Reference**:
  - `references/adr-guide.md` — Deep dive on decision drivers, fitness functions, and supersession.
