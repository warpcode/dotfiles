# Task Decomposition, 3-Factor Estimation & Lifecycle Gates

Guidelines for decomposing specifications into Milestones (`M-*`) and Context-Free Tasks (`TSK-*`), and coordinating project lifecycle gates.

---

## 1. Context-Free Task Principle (`TSK-*`)

Every `TSK-*` item in a sub-project `SPEC.md` must be executable by an engineer or isolated subagent without prior conversational history:
1. **Explicit File & Symbol Targets**: Name exact repository paths, scripts, or schemas.
2. **Traceability (`--depends-on`)**: Link every task to the `REQ-*` it fulfills and the `ADR-*` constraints it must obey.
3. **Deterministic Done Criteria**: State the exact command (`./validate.sh`, `unittest`, or probe) that proves completion.

---

## 2. 3-Factor Sizing Heuristic

Calibrate task size across **Complexity (C)**, **Effort (E)**, and **Uncertainty (U)**:

| Complexity | Effort | Uncertainty | Estimate | Action |
|---|---|---|---|---|
| Low | Small | Low | **0.5 pt** | Consolidate into parent task. |
| Low–Med | Small–Med | Low | **1.0 pt** | Ideal single-PR vertical slice. |
| Medium | Medium | Low–Med | **2.0–3.0 pt** | Multi-file slice; keep within one sub-project. |
| Any | Large | High | **5.0+ pt** | **Too large**: split into a timeboxed spike (`ADR`/`DT`) + smaller `TSK-*` items. |

---

## 3. End-to-End Project Lifecycle Gates

Coordinate only the phases requested by the user; external ticket creation, PR creation, and merges are always opt-in:

1. **Gate 1 — Discovery & Scrutiny (Workflow B)**: Verify the premise against existing `NG-*`, `ADR-*`, and `REJ-*`.
2. **Gate 2 — Specification & Decision Lock**: Lock `G-*`, `NG-*`, `REQ-*`, `RSK-*`, and `ADR-*` in `SPEC.md` and `DECISIONS.md` after user approval.
3. **Gate 3 — Milestone & Sub-Project Slicing (`M-*`, `TSK-*`)**: Sequence phases by risk/dependency order; keep future phases as compact stubs until the active phase completes.
4. **Gate 4 — Implementation, Progress Tracking & Compliance (Workflow D)**: Execute `TSK-*` slices, verify code ground truth, audit violations and documentation drift against issue dumps and worktrees (see `references/progress-and-compliance.md`), and run repository validation (`./validate.sh`).
