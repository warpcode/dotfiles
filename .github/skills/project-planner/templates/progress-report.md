# Progress & Compliance Audit: `<Plan Slug>`

> **Plan**: [`<slug>`](SPEC.md) · **Audit Date**: YYYY-MM-DD · **Plan Status**: Draft | Active | Done
> **Code Path**: `<path-to-repo-or-worktree>` or "None provided"
> **Issue Dump**: `<source or record count>` or "None provided"

---

## 1. Executive Progress Summary

| Metric | Count | Points | Percentage |
|---|---|---|---|
| **Done** | <n> | <x.x> pt | <%> |
| **In Progress** | <n> | <x.x> pt | — |
| **Open / Backlog** | <n> | <x.x> pt | — |
| **Blocked** | <n> | <x.x> pt | — |
| **Total Scope** | **<n>** | **<x.x> pt** | **100.0%** |

---

## 2. Milestone Health & Deliverable Status

| Milestone | Status | Tasks (Done/Total) | Points (Done/Total) | Progress | Exit Criteria Fulfilled? |
|---|---|---|---|---|---|
| `M-001`: <Title> | <Status> | <d>/<t> | <x>/<y> pt | <% > | Yes / No / Blocked: <reason> |

---

## 3. Requirement Verification & Acceptance Criteria Matrix

| Requirement | Priority | Child Tasks (Done/Total) | Acceptance Criteria (Met/Total) | Code Visibility | Status |
|---|---|---|---|---|---|
| `REQ-001`: <Title> | P0 | <d>/<t> | <m>/<tot> | Met in Code / Partial / Unverified | In Progress / Complete |

### Acceptance Criteria Breakdown
- **`REQ-001`**:
  - [x] Given <state>, when <action>, then <outcome> — *Verified in `<test_file>:<line>`*
  - [ ] Given <edge case>, when <action>, then <fallback> — *Missing in code / test*

---

## 4. Violations & Guardrail Audits

### Non-Goal (`NG-*`) Violations
- [x] **No Non-Goal violations detected.**
*(Or: ⚠️ `<Issue / Commit / Code>` contradicts Non-Goal `NG-xxx`: `<details>`)*

### Architecture & Decision (`ADR-*`, `REJ-*`) Violations
- [x] **No Architecture or Decision violations detected.**
*(Or: ⚠️ `<Issue / Code>` violates decision `ADR-xxx` / attempts rejected alternative `REJ-xxx`: `<details>`)*

### Sequencing & Prerequisite Violations
- [x] **All dependency sequences verified.**
*(Or: ⚠️ `<TSK-xxx>` marked In Progress/Done, but prerequisite `<TSK-yyy>` is `<Status>`)*

### Scope Creep / Unplanned Work
- [x] **Zero unmapped issues or untracked changes detected.**
*(Or: ⚠️ `<n>` issues / files lack plan provenance: `<List of external IDs or files>`)*

---

## 5. Documentation Accuracy & Ground-Truth Drift

### State Discrepancies (Plan vs Tracker vs Code)
- `<Item ID>`: Plan says `<Plan Status>`, tracker says `<Tracker Status>`, code shows `<Code Status>`.

### Target Files & Done Command Verification
- [ ] `<TSK-xxx>`: Expected target file `<path>` does not exist in code path.
- [ ] `<TSK-yyy>`: Done command `<command>` failed with exit code `<n>`.

### Governance Invariants
- **Unvalidated Assumptions**: `ASM-xxx` validation pending while dependent `REQ-yyy` is active.
- **Open Blocking Questions**: `Q-xxx` remains open, blocking `REQ-yyy`.
- **Unmitigated High Risks**: `RSK-xxx` has impact High with no mitigation plan.

---

## 6. Actionable Reconciliation Plan

Checklist of exact edits required to align documentation with reality:

- [ ] Update `SPEC.md`: Mark `TSK-xxx` as `[Done]`
- [ ] Update `SPEC.md`: Check off verified AC `<n>` in `REQ-xxx`
- [ ] Update `DECISIONS.md`: Resolve or log architectural violation `<ref>`
- [ ] Append row to `REVISIONS.md` recording progress audit and changes made
