---
name: project-adr
description: >
  Declarative MADR schema, force-ranking rules, automated fitness function
  requirements, and supersession standards for Architecture Decision Records in
  docs/adr/. Use when authoring, evaluating, or superseding ADRs or maintaining
  the ADR registry.
user-invocable: false
---

# Project ADR

A declarative schema and compliance reference for Architecture Decision Records
(ADRs) in `<repo>/docs/adr/`. ADRs are immutable historical records of why an
architectural choice was made and evolve alongside code under version control.

## 1. The Role of ADRs

ADRs pass the **Rollback Test**:
> *"If I rolled back our application code by 6 months to fix a massive bug, should this document roll back with it?"*

- **ADRs outlive individual plans**: Plans are created, implemented, and archived; accepted ADRs remain binding repository law until explicitly superseded.
- **One-Way vs. Two-Way Doors**: Any irreversible or costly technical choice (dependency selection, storage schema, network boundary, security model) requires an accepted ADR before implementation.

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

Valid statuses: `Proposed`, `Accepted`, `Superseded by ADR-xxxx`, `Deprecated`, `Rejected`.

## 3. MADR Schema & Force Ranking

Use `templates/adr.md`. Every ADR must satisfy these structural rules:

1. **Sequential Numbering**: Assign `highest_existing + 1` formatted as `NNNN-<kebab-case-slug>.md`; verify against `docs/adr/README.md` to avoid duplicates or conflicts.
2. **Ranked Forces**: Evaluate decision drivers across three tiers:
   - **P0 (Non-Negotiables)**: Security isolation, secret handling, data integrity, compliance.
   - **P1 (Differentiators)**: Token economy, tool-call efficiency, latency, maintainability.
   - **P2 (Tie-Breakers)**: Familiarity, local conventions.
3. **Canonical Statement**:
   > *In the context of **[system/module scope]**, facing **[decision drivers / constraints]**, we decided to **[chosen option]** to achieve **[primary benefit]**, accepting **[consequence / trade-off]**.*
4. **Options Evaluated**: Compare at least two viable options (including "do nothing" when applicable) with explicit pros, cons, and rejection rationale.
5. **Automated Fitness Function**: Specify an exact executable command (linter, unit test, or static check) that fails CI if the invariant is violated. Vague or manual checks are invalid.

## 4. Superseding an ADR

When an existing decision must change:
1. **Preserve History**: Never rewrite the decision body of an accepted ADR; past commits depend on it for rationale.
2. **Author Replacement**: Create a new ADR with the next sequential number (`NNNN-<slug>.md`).
3. **Cross-Reference Both Files**:
   - In the new ADR: `Supersedes: [ADR-0002](0002-slug.md)`.
   - In the old ADR: update header to `Status: Superseded by [ADR-0006](0006-slug.md)`.
4. **Update Registry**: Update the status row and add the new row in `docs/adr/README.md`.
5. **Flag Dependent Specs/Epics**: Mark requirements or tickets depending on the superseded ADR as `Needs Review`.

## 5. ADR Acceptance Checklist

Before marking an ADR `Accepted`:
- [ ] Context and scope are bounded and cross-checked against existing `docs/adr/README.md`.
- [ ] Decision drivers are ranked explicitly under `P0` / `P1` / `P2`.
- [ ] At least two concrete options are evaluated, with rejected alternatives documented.
- [ ] Canonical MADR statement is complete and unambiguous.
- [ ] Automated fitness function specifies a runnable command (test, linter, or static check).
- [ ] Positive and negative consequences / trade-offs are recorded.
- [ ] Supersession links (`Supersedes:` / `Superseded by`) are bidirectional if replacing an older ADR.
- [ ] `docs/adr/README.md` registry index is updated.

## 6. Templates & References

- **Template**:
  - `templates/adr.md` — Canonical MADR template with forces, trade-offs, and fitness functions.
- **Reference**:
  - `references/adr-guide.md` — Deep dive on decision drivers, fitness functions, and supersession.
