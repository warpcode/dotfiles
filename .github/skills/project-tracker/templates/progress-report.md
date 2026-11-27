# Progress & Compliance Audit: `<Epic / Plan Slug>`

> **Epic / Plan**: [`<id-or-slug>`](SPEC.md) · **Audit Date**: YYYY-MM-DD · **Status**: Open | Active | Done
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

## 2. Branch / PR Stack Tree

| Issue | PR | Branch (Head) | Base | Upstream Dependency | Merged? | Sequencing Breach? |
|---|---|---|---|---|---|---|
| `#101` | `#201` | `feat/101-schema` | `master` | — | Yes | No |
| `#102` | `#202` | `feat/102-service` | `feat/101-schema` | `#101` | No | No |

---

## 3. Milestone Health & Deliverable Status

| Milestone | Status | Tasks (Done/Total) | Points (Done/Total) | Progress | Exit Criteria Fulfilled? |
|---|---|---|---|---|---|
| `M-001`: <Title> | <Status> | <d>/<t> | <x>/<y> pt | <% > | Yes / No / Blocked: <reason> |

---

## 4. Requirement Verification & Acceptance Criteria Matrix

| Requirement / Issue | Priority | Child Tasks (Done/Total) | Acceptance Criteria (Met/Total) | Code Visibility | Status |
|---|---|---|---|---|---|
| `REQ-001` / `#101`: <Title> | P0 | <d>/<t> | <m>/<tot> | Visible / Partially visible / Not visible / External | In Progress / Complete |

### Acceptance Criteria Breakdown
- **`REQ-001` / `#101`**:
  - [x] Given <state>, when <action>, then <outcome> — *Verified in `<test_file>:<line>`*
  - [ ] Given <edge case>, when <action>, then <fallback> — *Missing in code / test*

---

## 5. Violations & Guardrail Audits

### Non-Goal (`NG-*`) Violations
- [x] **No Non-Goal violations detected.**
*(Or: ⚠️ `<Issue / Commit / Code>` contradicts Non-Goal `NG-xxx`: `<details>`)*

### Architecture & Decision (`ADR-*`, `REJ-*`) Violations
- [x] **No Architecture or Decision violations detected.**
*(Or: ⚠️ `<Issue / Code>` violates decision `ADR-xxx` / attempts rejected alternative `REJ-xxx`: `<details>`)*

### Sequencing & Dependency Breaches
- [x] **All dependency sequences and PR bases verified.**
*(Or: ⚠️ `<#102 / TSK-xxx>` is `In Progress`/`Done` or targets `master` while upstream `<#101>` is `<Status>`)*

### Stub / Unwired Code
- [x] **No stub or unwired implementations detected.**
*(Or: ⚠️ `<symbol>` in `<file:line>` is not called or registered in active execution paths)*

### Scope Creep / Unplanned Work
- [x] **Zero unmapped issues or untracked changes detected.**
*(Or: ⚠️ `<n>` issues / files lack epic or plan provenance: `<List of external IDs or files>`)*

---

## 6. Documentation Accuracy & Ground-Truth Drift

### State Discrepancies (Tracker vs Branch/PR Tree vs Code)
- `<Item ID>`: Tracker says `<Tracker Status>`, Branch/PR tree shows `<PR/Base State>`, Code shows `<Code Status>` (Optional SPEC: `<Plan Status>`).

### Target Files & Evidence Link Verification
- [ ] `<TSK-xxx>`: Expected target file `<path>` does not exist in code path.
- [ ] `<TSK-yyy>`: Task marked Done but missing verified Evidence link (PR / Commit / Ticket).

### Governance Invariants
- **Unvalidated Assumptions**: `ASM-xxx` validation pending while dependent `REQ-yyy` is active.
- **Open Blocking Questions**: `Q-xxx` remains open, blocking `REQ-yyy`.
- **Unmitigated High Risks**: `RSK-xxx` has impact High with no mitigation plan.

---

## 7. Actionable Reconciliation Plan

Checklist of exact edits required to align documentation with reality:

- [ ] Update Plan: Mark `TSK-xxx` as `[Done]`
- [ ] Backfill Evidence: Record PR #`<n>`, Commit `<sha>`, and Ticket `<id>` on `TSK-xxx`
- [ ] Update Plan: Check off verified AC `<n>` in `REQ-xxx`
- [ ] Resolve or log architectural violation `<ref>` in `docs/adr/`
- [ ] Append row with Evidence links to plan's `## Revision Log`
