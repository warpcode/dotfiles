# [EPIC]: [Component / Feature Name]

| Metadata | Details |
|---|---|
| **Status** | Open \| In Progress \| Closed |
| **Parent Initiative** | [Parent #id / Key] or None |
| **Spec Reference (Optional)** | [`docs/plans/YYYY-MM-DD-slug/SPEC.md`](../docs/plans/YYYY-MM-DD-slug/SPEC.md) or N/A (Issue-First) |
| **Related ADRs** | [`ADR-000x`](../docs/adr/000x-slug.md) or None |
| **Branch Strategy** | Trunk Streaming \| `epic/<id>` Tree \| Stacked Branches |
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

## 4. Child Sub-Issues & Dependency DAG
| ID | Title | Estimate | Depends On / Blocked By | Blocks | Frontier / Status |
|---|---|---|---|---|---|
| [PROJ-101 / #101] | [Story: Core data model & migration] | 2.0 pt | — | PROJ-102 | Ready |
| [PROJ-102 / #102] | [Story: Service layer implementation] | 1.0 pt | PROJ-101 | PROJ-103 | Blocked |
| [PROJ-103 / #103] | [Story: CLI interface & flags] | 1.0 pt | PROJ-102 | PROJ-104 | Blocked |
| [PROJ-104 / #104] | [Task: Benchmark & verification suite] | 1.0 pt | PROJ-103 | — | Blocked |

### Sub-Issue Checklist (Optional GitHub Tasklist)
- [ ] `#101` — Core data model & migration
- [ ] `#102` — Service layer implementation (`Depends on #101`)
- [ ] `#103` — CLI interface & flags (`Depends on #102`)
- [ ] `#104` — Benchmark & verification suite (`Depends on #103`)

---

## 5. Epic Completion (Exit Criteria)
- [ ] All child stories and tasks closed with merged PR evidence.
- [ ] Automated regression tests passing in CI.
- [ ] Documentation updated in `docs/architecture/` and `docs/runbooks/`.
- [ ] Plan status in `docs/plans/` marked `Done`.
