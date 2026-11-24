---
name: project-planner
description: >
  Declarative schema and quality-gate reference for engineering specifications,
  RFCs, EARS requirements, NFR checklists, change impact analysis, and Definition
  of Ready. Use when authoring or validating technical specs in docs/plans/ or
  issue-first epics.
user-invocable: false
---

# Project Planner

A declarative schema and specification reference for engineering plans. Plans may
live as plain Markdown files under `<repo>/docs/plans/` (with zero service
lock-in) or be anchored in an issue-first GitHub/Jira epic when the repository
tracks work natively in issues.

> For interactive plan stress-testing and multi-turn refinement, use the
> `project-architect` agent.

## 1. Documentation Boundaries & Layout

Repository-tracked engineering documentation lives under `<repo>/docs/` and
evolves alongside code.

### The Rollback Test
Apply the **Rollback Test** to decide whether an artifact belongs in git or in an
external tracker:
> *"If I rolled back our application code by 6 months to fix a massive bug, should this document roll back with it?"*

- **In-Repo (`docs/`)**: ADRs, system architecture, operational runbooks, API contracts, and dated **Technical Design Specs (RFCs)** version-controlled alongside code.
- **External Trackers (GitHub Issues, Jira, Notion, Confluence)**: Business PRDs, user stories, customer research, sprint backlogs, roadmaps, and UI/UX mockups.
- **Issue-First Repositories**: When a GitHub or Jira epic serves as the authoritative plan of record, maintaining a separate `docs/plans/` directory is optional; durable architectural choices still belong in `docs/adr/`.

```text
docs/
├── README.md                              # Documentation guide & rollback test
├── adr/                                   # Durable repository-wide architecture decisions
│   ├── README.md                          # Index of all ADRs (number, status, title)
│   ├── 0001-record-architecture-decisions.md
│   └── 0002-standardize-on-madr.md
├── architecture/                          # System topology, module contracts, data flows
│   └── README.md
├── runbooks/                              # Operational runbooks, deployment, triage
│   └── README.md
└── plans/                                 # Optional Technical Design Specs (RFCs)
    ├── README.md                          # Index of all plans (plan link, status, summary)
    ├── 2026-10-19-plugin-sandbox.md       # Self-contained single-file plan
    └── 2026-10-25-secrets-rotation/       # Folder layout when child features/assets exist
        ├── SPEC.md
        └── features/
            └── 2026-11-02-network-policy.md
```

### Naming & Location Rules
1. **Durable Architecture Decisions (`docs/adr/`)**:
   - Numbered sequentially zero-padded: `0001-<slug>.md`.
   - Never tied to a feature date; ADRs outlive individual feature projects.
   - Formatted using the canonical MADR template (`templates/adr.md`).
2. **Technical Plans & RFCs (`docs/plans/`)**:
   - **Prefix**: Creation date in `YYYY-MM-DD` format (from session local time).
   - **Slug**: Lowercase kebab-case, 2–5 words (`[a-z0-9-]`), describing the outcome (`plugin-sandbox`).
   - **Single File vs. Folder**: Default to `docs/plans/YYYY-MM-DD-<slug>.md`. Use a folder (`YYYY-MM-DD-<slug>/SPEC.md`) only when child sub-features (`features/`) or standalone diagrams/assets exist.
   - **De-duplication**: Check existing plans before creating; extend an active plan rather than duplicating it.
   - **Plan Lifecycle**: Never delete a plan. Mark it `Done`, `Abandoned`, or `Superseded` in the header and index.

`docs/plans/README.md` index format:

```markdown
| Plan | Status | Summary |
|---|---|---|
| [2026-10-19-plugin-sandbox](2026-10-19-plugin-sandbox.md) | Active | Isolate plugin execution |
```

`docs/adr/README.md` index format:

```markdown
| ADR | Status | Date | Title |
|---|---|---|---|
| [0001](0001-record-architecture-decisions.md) | Accepted | 2026-10-19 | Record architecture decisions |
```

Status values: `Draft`, `Active`, `Done`, `Abandoned`, `Superseded`.

## 2. Item IDs & Relationships

| Kind | Meaning | Location |
|---|---|---|
| `G-*` | Goal (with measurable success metric) | `docs/plans/` (SPEC) or Epic |
| `NG-*` | Non-Goal (explicit negative boundary out of scope) | `docs/plans/` (SPEC) or Epic |
| `REQ-*` | Requirement (EARS statement + Given/When/Then AC + P0/P1/P2) | `docs/plans/` (SPEC) or Issue |
| `RSK-*` | Risk (likelihood, impact, mitigation, owner) | `docs/plans/` (SPEC) or Epic |
| `ASM-*` | Assumption (validation path + if-false impact) | `docs/plans/` (SPEC) or Epic |
| `Q-*` | Open question (blocking or non-blocking) | `docs/plans/` (SPEC) or Epic |
| `M-*` | Milestone (deliverables + exit criteria) | `docs/plans/` (SPEC) or Milestone |
| `TSK-*` | Task (context-free, $\le 3$ pt, target files + evidence link) | `docs/plans/` (SPEC) or Sub-Issue |
| `ADR-NNNN` | Architecture decision (context, forces, choice, fitness function) | `docs/adr/` |
| `DT-*` | Decision tree (deterministic IF/ELSE classification rule) | `docs/adr/` or SPEC |
| `REJ-*` | Rejected proposal (conflicts with IDs + rationale) | `docs/adr/` or SPEC |

### Lifecycle & Status Rules
- **Plan Lifecycle (`docs/plans/`)**: `Draft` $\to$ `Active` (passes Definition of Ready) $\to$ `Done` (passes Definition of Done) | `Abandoned` | `Superseded`.
- **ADR Lifecycle (`docs/adr/`)**: `Proposed` $\to$ `Accepted` $\to$ `Superseded by ADR-xxxx` | `Deprecated` | `Rejected`. ADRs outlive plans.
- **Item Lifecycle (`REQ-*`, `TSK-*`)**: `Proposed` $\to$ `Accepted` $\to$ `Done`. Only `Accepted`/`Done` items are binding.
- **Dependencies**: `Depends On` may only reference active `Accepted`/`Done` items. Never link to superseded items or introduce cycles.
- **Numbering & Immutability**: Zero-padded per plan (`REQ-001`), immutable, and **never reused or renumbered**. Next ID is highest existing $+ 1$.

## 3. Change Impact Checklist & Recording Outcomes

Evaluate any proposed addition, scope change, or architectural pivot against
these six criteria:

1. **Premise**: Which `G-*` or `REQ-*` gap does the change close? (If none, classify as scope creep.)
2. **Contradictions**: Does it conflict with any active `NG-*`, `REJ-*`, or accepted `ADR-*`?
3. **Prior Art**: Was the idea previously rejected (`REJ-*` or ADR *Rejected* section)? Reopening requires new evidence.
4. **Blast Radius**: Identify every item whose transitive `Depends On` graph includes the changed item.
5. **Alternatives & Pre-Mortem**: Document the cheapest viable alternative, the "do nothing" baseline, and the primary failure mode.
6. **Reversibility**: Classify as two-way door or one-way door (one-way doors require an `ADR-*` in `docs/adr/`).

### Recording Outcomes
- **Approved**: Add a new sequential ID or supersede the existing item (`Superseded by <ID>`), mark affected dependents `Needs Review`, and append a row to the revision log (`REVISIONS.md` or SPEC log). Create or supersede an `ADR-*` if architectural.
- **Rejected**: Record a `REJ-*` entry citing *Conflicts With* IDs and rationale.

## 4. Retrospective Documentation Schema

When capturing existing work retrospectively (see `references/planning-reference.md`):
1. Derive evidence from git history, PRs, Jira, or GitHub Issues without inventing unverified claims.
2. When creating a `docs/plans/` folder, use the earliest evidence date for the prefix and record the documentation date in the SPEC header.
3. Mark imported items `Accepted (Retrospective)` with explicit `Source:` provenance links; capture missing details as `Q-*` or `ASM-*`.

## 5. Quality Gate: Definition of Ready

Before a plan or epic is ready for implementation, verify:
- [ ] **Charter & Scope**: Problem, affected users, and motivation defined; $\ge 1$ `G-*` with measurable metric; $\ge 1$ `NG-*` explicit negative boundary.
- [ ] **Requirements**: Every `REQ-*` traces to a `G-*`, uses EARS syntax (`references/planning-reference.md`), carries priority (`P0`/`P1`/`P2`), and specifies $\ge 1$ Given/When/Then acceptance criterion.
- [ ] **NFR Coverage**: 10-dimension NFR checklist evaluated (Security, Privacy, Performance, Reliability, Observability, Compatibility/Rollback, Accessibility, Cross-platform, Docs, Testing).
- [ ] **Decisions & Governance**: One-way doors have an accepted `ADR-*` with an automated fitness function and rejected alternatives; zero open blocking `Q-*`; unvalidated `ASM-*` have validation tasks.
- [ ] **Actionable Slices**: P0/P1 requirements are decomposed into context-free tasks/sub-issues sized $\le 3$ pt with explicit `Target Files`.
- [ ] **Graph Integrity**: Dependency graph is acyclic, links no superseded items, and `README.md` index (when using `docs/plans/`) is updated.

## 6. Downstream Skill Handoff Map

| Concern | Target Skill | Role |
|---|---|---|
| One-way door decisions & fitness functions | `project-adr` | MADR schema in `docs/adr/` |
| Epic/sub-issue hierarchy, DAGs, vertical slicing | `project-tickets` | Issue-first or spec-first breakdown ($\le 3$ pt) |
| Three-way tracking & sequencing-breach audits | `project-tracker` | `Tracker <-> Branch/PR <-> Code` reconciliation |
| Interactive plan stress-testing | `project-architect` (agent) | Multi-turn interactive refinement |

## 7. Templates & References

- **Core Plan Files**:
  - `templates/SPEC.md` — Charter, goals, non-goals, requirements, NFR checklist, risks, tasks
  - `templates/DECISIONS.md` — ADRs, decision trees, rejected proposals (folder layout)
  - `templates/REVISIONS.md` — Append-only change log (folder layout)
- **Standalone Exports**:
  - `templates/tech-spec.md` — Standalone Technical Design Spec (RFC)
  - `templates/ticket-task.md` — Standalone context-free task specification
  - `templates/prd.md` — Product Requirements Document (for external trackers)
  - `templates/adr.md` — Standalone Architecture Decision Record (MADR format)
- **Reference Guide**:
  - `references/planning-reference.md` — EARS requirements, MoSCoW, ADR drivers, 3-factor sizing, retrospective mapping
