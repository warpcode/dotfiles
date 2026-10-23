# [EPIC]: [Component / Feature Name]

| Metadata | Details |
|---|---|
| **Status** | Open \| In Progress \| Closed |
| **Spec Reference** | [`docs/plans/YYYY-MM-DD-slug/SPEC.md`](../docs/plans/YYYY-MM-DD-slug/SPEC.md) |
| **Related ADRs** | [`ADR-000x`](../docs/adr/000x-slug.md) |
| **Target Milestone** | [Milestone / Release / Sprint] |
| **Owner / Lead** | [Engineer / Agent] |

---

## 1. Executive Summary & Problem Statement
[High-level overview of the feature or architectural initiative. What capability does this deliver and what pain point does it solve?]

---

## 2. Goals & Measurable Outcomes
- **`G-001`**: [Measurable target metric, e.g. "p95 latency < 50ms, 0 unhandled exceptions"]
- **`G-002`**: [Secondary outcome]

---

## 3. Explicit Non-Goals (Boundaries)
- **`NG-001`**: [Explicit exclusion]
- **`NG-002`**: [Deferred capability]

---

## 4. Child Stories & Tasks Breakdown
| ID | Title | Estimate | Depends On | Status |
|---|---|---|---|---|
| [PROJ-101] | [Story: Core data model & migration] | 2.0 pt | — | Ready |
| [PROJ-102] | [Story: Service layer implementation] | 1.0 pt | PROJ-101 | Blocked |
| [PROJ-103] | [Story: CLI interface & flags] | 1.0 pt | PROJ-102 | Blocked |
| [PROJ-104] | [Task: Benchmark & verification suite] | 1.0 pt | PROJ-103 | Blocked |

---

## 5. Epic Completion (Exit Criteria)
- [ ] All child stories and tasks closed with merged PR evidence.
- [ ] Automated regression tests passing in CI.
- [ ] Documentation updated in `docs/architecture/` and `docs/runbooks/`.
- [ ] Plan status in `docs/plans/` marked `Done`.
