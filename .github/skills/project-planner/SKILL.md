---
name: project-planner
description: >
  Plan projects and features as dated specifications in docs/plans/. Grills and
  tests ideas through interactive Socratic questioning, exposes conflicts and
  edge cases, manages plan resumption and amendments, locks EARS requirements,
  and coordinates ADRs. Use when proposing a feature, grilling an idea,
  refining a plan, or breaking down tasks. For progress tracking, use
  project-tracker.
user-invocable: false
---

# Project Planner

A procedure-only skill: plans are plain Markdown files edited directly with zero service lock-in.
The instructions below guide human engineers and agents to grill proposals, challenge assumptions,
refine specifications across multiple sessions, and outline actionable tasks.

## 1. Documentation Boundaries & Layout

Plans, architecture, and operational records live under `<repo>/docs/`. This skill strictly manages **engineering-centric documentation** that requires version control and evolves with the code.

### The Rollback Test
When deciding whether a document belongs in the repository or in external tooling, apply the **Rollback Test**:
> *"If I rolled back our application code by 6 months to fix a massive bug, should this document roll back with it?"*

- **In-Repo (`docs/`)**: ADRs, system architecture, operational runbooks, API contracts, and dated **Technical Design Specs (RFCs)** version-controlled alongside code.
- **External Trackers (Jira, GitHub Issues, Notion, Confluence)**: Business PRDs, user stories, customer research, sprint backlogs, roadmaps, and UI/UX mockups.

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
└── plans/                                 # Technical Design Specs (RFCs) & implementation plans
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
   - **Prefix**: The date created in `YYYY-MM-DD` format (from session local time — never guessed).
   - **Slug**: Lowercase kebab-case, 2–5 words, `[a-z0-9-]` describing the outcome (`plugin-sandbox`).
   - **Single File vs. Folder**: Use `docs/plans/YYYY-MM-DD-<slug>.md` by default. Use a folder (`YYYY-MM-DD-<slug>/SPEC.md`) only when child sub-features (`features/`) or standalone diagrams/assets exist.
   - **De-duplication**: Search existing plans before creating. If a plan exists for the topic, extend it rather than duplicating.
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
| `G-*` | Goal (with measurable success metric) | `docs/plans/` (SPEC) |
| `NG-*` | Non-Goal (explicit negative boundary out of scope) | `docs/plans/` (SPEC) |
| `REQ-*` | Requirement (EARS statement + Given/When/Then AC + P0/P1/P2) | `docs/plans/` (SPEC) |
| `RSK-*` | Risk (likelihood, impact, mitigation, owner) | `docs/plans/` (SPEC) |
| `ASM-*` | Assumption (validation path + if-false impact) | `docs/plans/` (SPEC) |
| `Q-*` | Open question (blocking or non-blocking) | `docs/plans/` (SPEC) |
| `M-*` | Milestone (deliverables + exit criteria) | `docs/plans/` (SPEC) |
| `TSK-*` | Task (context-free, $\le 3$ pt, target files + evidence link) | `docs/plans/` (SPEC) |
| `ADR-NNNN` | Architecture decision (context, forces, choice, fitness function) | `docs/adr/` |
| `DT-*` | Decision tree (deterministic IF/ELSE classification rule) | `docs/adr/` or SPEC |
| `REJ-*` | Rejected proposal (conflicts with IDs + rationale) | `docs/adr/` or SPEC |

### Lifecycle & Status Rules
- **Plan Lifecycle (`docs/plans/`)**: `Draft` (in development) $\to$ `Active` (passes Definition of Ready) $\to$ `Done` (passes Definition of Done, archived) | `Abandoned` | `Superseded`. Plans are historical records.
- **ADR Lifecycle (`docs/adr/`)**: `Proposed` (under review) $\to$ `Accepted` (binding permanent constraint) $\to$ `Superseded by ADR-xxxx` | `Deprecated` | `Rejected`. ADRs outlive plans.
- **Item Lifecycle (`REQ-*`, `TSK-*`)**: `Proposed` $\to$ `Accepted` $\to$ `Done`. Only `Accepted`/`Done` items are binding.
- **Dependencies**: `Depends On` may only reference active `Accepted`/`Done` items. Never link to superseded items or introduce cycles.
- **Numbering & Immutability**: Zero-padded per plan (`REQ-001`), immutable, and **never reused or renumbered**. The next ID is highest existing $+ 1$.

## 3. Socratic Grilling & Resumption Protocol

Never rush to rubber-stamp a proposal. The primary duty of this skill is to act as an active sparring partner: grill premises, uncover edge cases, detect contradictions, and refine the plan iteratively.

### Phase 1: Active Grilling & Stress-Testing
When an idea or proposal is presented, do not simply agree or generate boilerplate:
1. **Contradiction & Conflict Check**: Read active ADRs in `docs/adr/` and existing plans. Check whether the proposal contradicts an established architectural invariant or non-goal.
2. **Edge Cases & Failure Modes**: Probe edge cases: What happens on network disconnects? Race conditions? Invalid inputs? Service timeouts? How does it behave under 10x load?
3. **Non-Goals (`NG-*`)**: Force negative boundaries: "What is explicitly out of scope for this initiative?"
4. **Targeted Probing**: Ask 2–3 high-signal, probing questions per turn. Challenge assumptions: "Why add a new dependency instead of using utility X already in the tree?"

### Phase 2: Stateful Persistence & Resumption (Walk Away & Return)
Plans are persisted in `docs/plans/YYYY-MM-DD-<slug>/SPEC.md`, recording agreed elements alongside open questions (`Q-*`) and unvalidated assumptions (`ASM-*`). The user can walk away at any time.

When returning days or weeks later to amend or expand:
1. **Ground Context**: Read the existing `SPEC.md` and related ADRs.
2. **Identify the Delta**: Compare the user's new input against the recorded plan.
3. **Resume Grilling**: Interview the user on the implications of the change: "How does this amendment impact previously agreed goal G-002?", "Does this invalidate assumption ASM-001?", "What is the blast radius on dependent components?"

### Phase 3: Final Requirements & Task Agreement
Once grilling resolves open questions and ambiguity:
1. Formulate final requirements in unambiguous EARS format with Given/When/Then acceptance criteria.
2. Outline all required tasks (`TSK-*`) for the epic or set of individual issues.
3. If one-way-door decisions exist, invoke `project-adr` to investigate trade-offs, agree on options, and approve a canonical MADR before implementation begins.


## 4. Procedures

### Workflow A — New Plan
1. Get today's local date, choose a slug (§1), and verify no duplicate plan exists.
2. Create `docs/plans/YYYY-MM-DD-<slug>.md` from `templates/SPEC.md` (or folder `YYYY-MM-DD-<slug>/SPEC.md` if child features/assets exist).
3. If the initiative introduces durable architectural decisions or one-way doors, scaffold `docs/adr/NNNN-<slug>.md` from `templates/adr.md`, add a row to `docs/adr/README.md`, and link the ADR in the plan.
4. Add the row to `docs/plans/README.md` (create index if missing).
5. Formulate charter, goals (`G-*`), non-goals (`NG-*`), requirements (`REQ-*`), decisions (`ADR-*`), and tasks (`TSK-*`) satisfying the **Definition of Ready** (§5).

### Workflow B — Scrutinize Every New Idea or Change (Mandatory)
Before agreeing to any new idea, scope change, or architectural pivot:
1. **Read & Check Constraints**: Review the active plan and all active ADRs in `docs/adr/`. Search `NG-*`, `REJ-*`, and ADR *Rejected* sections.
2. **Run Impact & Contradiction Check**:
   - **Premise**: Which `G-*`/`REQ-*` gap does this close? (If none, flag as scope creep).
   - **Contradictions**: Any active `NG-*` or global `ADR-*` it violates?
   - **Prior Art**: Was this previously rejected (`REJ-*`)? Reopening requires new evidence.
   - **Blast Radius**: Every item whose `Depends On` graph transitively includes the changed item.
   - **Alternatives & Pre-Mortem**: Cheapest alternative, "do nothing", and failure mode ("This failed because...").
   - **Reversibility**: One-way door vs. two-way door (one-way doors require an `ADR-*` in `docs/adr/`).
3. **Seek Approval**: Present the check via `ask_question` (recommended option first).
4. **Record Outcome**:
   - Approved: Add new ID or supersede existing item (`Superseded by <ID>`), mark dependents `Needs Review`, append revision entry. If architectural, create or supersede the relevant ADR in `docs/adr/`.
   - Rejected: Record a `REJ-*` entry with *Conflicts With* IDs and rationale.

### Workflow C — Retrospective Documentation
Documenting existing work without service lock-in (see `references/planning-reference.md`):
1. Extract evidence from git history, PRs, Jira dumps, or docs via provider skills (`git-expert`, `github-cli`, `jira-api`).
2. Use the date of the earliest evidence as the folder prefix; note today's documentation date in the SPEC header.
3. Mark imported items `Accepted (Retrospective)` with explicit `Source:` provenance links. Record unverified items as `Q-*` or `ASM-*`.

### Workflow D — Handoff to ADRs, Tickets & Tracking
Once a plan passes the **Definition of Ready** (§5):
1. **Architectural Decisions**: For any one-way door choices or structural patterns, invoke `project-adr` to formalize decisions in `docs/adr/` with automated fitness functions.
2. **Ticket Decomposition**: Invoke `project-tickets` to decompose requirements into vertical slices with Given/When/Then acceptance criteria and batch-create issues in Jira or GitHub Issues.
3. **Task Execution**: Engineers or subagents execute slices against target files, tagging commits and PRs with `Plan: <slug>:<TSK-xxx>`.
4. **Progress Auditing**: To audit code ground truth against ticket tracker dumps and detect scope drift, invoke `project-tracker`.


## 5. Quality Gate: Definition of Ready

Before declaring a plan ready for implementation, verify:
- [ ] **Charter & Scope**: Problem, affected users, and why now clearly defined; $\ge 1$ `G-*` with measurable metric; $\ge 1$ `NG-*` defining explicit negative boundaries.
- [ ] **Requirements**: Every `REQ-*` links to a `G-*`, uses EARS syntax, sets priority (`P0`/`P1`/`P2`), and specifies $\ge 1$ Given/When/Then acceptance criterion.
- [ ] **NFR Coverage**: 10-dimension NFR checklist evaluated (Security, Privacy, Performance, Reliability, Observability, Compatibility/Rollback, Accessibility, Cross-platform, Docs, Testing).
- [ ] **Decisions & Governance**: One-way doors have an `ADR-*` with fitness function and rejected alternatives; no blocking `Q-*` open; unvalidated `ASM-*` have validation tasks.
- [ ] **Actionable Tasks**: Every P0/P1 requirement is broken into context-free `TSK-*` items sized $\le 3$ pt with explicit `Target Files`.
- [ ] **Plan Integrity**: No dependency cycles, no links to superseded items, `README.md` index updated.

## 6. Templates & References

- **Core Plan Files**:
  - `templates/SPEC.md` — Charter, goals, non-goals, requirements, NFR checklist, risks, tasks
  - `templates/DECISIONS.md` — ADRs, decision trees, rejected proposals (when using folder layout)
  - `templates/REVISIONS.md` — Append-only change log (when using folder layout)
- **Standalone Exports**:
  - `templates/tech-spec.md` — Standalone Technical Design Spec (RFC) for in-repo plans
  - `templates/ticket-task.md` — Standalone context-free task specification
  - `templates/prd.md` — Product Requirements Document (for external trackers: Jira/Notion)
  - `templates/adr.md` — Standalone Architecture Decision Record (MADR format for `docs/adr/`)
- **Reference Guide**:
  - `references/planning-reference.md` — EARS requirements, MoSCoW, ADR drivers, 3-factor sizing, retrospective mapping

