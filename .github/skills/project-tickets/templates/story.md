# [STORY]: [Component] [Action] [Target Outcome]

| Metadata | Details |
|---|---|
| **Parent Epic** | [PROJ-100](url) or [`SPEC.md`](../docs/plans/YYYY-MM-DD-slug/SPEC.md) |
| **Estimate** | 1.0 pt \| 2.0 pt \| 3.0 pt (max) |
| **Plan Link** | `Plan: <slug>:<TSK-xxx>` |
| **Depends On** | [PROJ-xxx] or None |

---

## 1. User Story / Context
**As an** [engineer / user / operator],  
**I want to** [execute specific capability],  
**So that** [unblock measurable benefit / eliminate failure mode].

---

## 2. Acceptance Criteria (Given / When / Then)
Every criterion must be testable without human ambiguity:

- **AC-1 (Happy Path)**:
  - **Given** [system precondition and valid state],
  - **When** [action or trigger occurs],
  - **Then** [expected state change and output returned].
- **AC-2 (Edge Case / Error Path)**:
  - **Given** [invalid input, expired token, or degraded dependency],
  - **When** [action is attempted],
  - **Then** [deterministic error code/message returned without crash].

---

## 3. Technical Guidance & Boundaries
- **Target Files / Packages**: `path/to/source.ext`, `path/to/test.ext`
- **Architectural Invariants**: Must obey [`ADR-000x`](../docs/adr/000x-slug.md).
- **Out of Scope**: Do NOT touch [unrelated modules or broad refactoring].

---

## 4. Definition of Done Checklist
- [ ] Code implemented against named target files.
- [ ] Unit or regression test added verifying all AC.
- [ ] Pull request authored with trailer `Plan: <slug>:<TSK-xxx>`.
- [ ] CI validation passes (`./validate.sh`).
