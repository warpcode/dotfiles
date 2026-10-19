# `YYYY-MM-DD-<slug>` — <Plan Title>

> **Status**: Draft | Active | Done | Abandoned | Superseded by `<plan>`
> **Created**: YYYY-MM-DD · **Parent**: `<parent plan folder>` or none
> **Charter**: <Problem, who is affected, why now, target outcome — one paragraph>
> **Sources**: <links to tickets, PRs, docs; or "none">

## Goals
### `G-001`: <Title> [Accepted]
- **Statement**: <Outcome unlocked>
- **Success Metric**: <Measurable signal and target, e.g. "p95 < 200 ms">
- **Rationale**: <Why it matters>

## Non-Goals (Explicitly Out of Scope)
### `NG-001`: <Title> [Accepted]
- **Statement**: <What will NOT be done>
- **Rationale**: <Why this boundary exists>

## Assumptions
### `ASM-001`: <Title> [Accepted]
- **Statement**: <What we believe to be true>
- **Validation**: <How/when it will be checked, or `TSK-xxx`> · **If false**: <Impact>

## Requirements
### `REQ-001`: <Title> [Accepted] — P0
- **Depends On**: `G-001`
- **Statement**: <EARS: WHEN <trigger>, the <component> SHALL <response>.>
- **Acceptance Criteria**:
  - [ ] Given <state>, when <action>, then <verifiable outcome>
  - [ ] Given <invalid input>, when <action>, then <exact error/fallback>
- **Rationale**: <Why>

## NFR Checklist
| Area | Covered by / N/A reason |
|---|---|
| Security & authz | |
| Privacy / secrets | |
| Performance & scale | |
| Reliability & failure handling | |
| Observability | |
| Migration, compatibility & rollback | |
| Accessibility | |
| Cross-platform (Linux/macOS) | |
| Docs & communication | |
| Testing strategy | |

## Risks
### `RSK-001`: <Title> [Accepted]
- **Affects**: `REQ-001` · **Likelihood**: Low/Med/High · **Impact**: Low/Med/High
- **Mitigation**: <Action or `TSK-xxx`> · **Owner**: <who>

## Open Questions
### `Q-001`: <Question> [Open | Answered]
- **Blocking**: Yes/No · **Blocks**: `REQ-xxx` · **Answer**: <when answered, with date>

## Milestones
### `M-001`: <Phase title> [Accepted]
- **Depends On**: `REQ-001`
- **Deliverables**: <What ships>
- **Exit Criteria**: <Checkable conditions>

## Tasks
### `TSK-001`: <Title> [Proposed] — 1.0 pt
- **Depends On**: `REQ-001`, `ADR-001` · **Milestone**: `M-001`
- **Target Files**: `path/to/file`
- **Done Command**: `./validate.sh` (or exact probe)

## Features
- [`features/YYYY-MM-DD-<slug>`](features/YYYY-MM-DD-<slug>/SPEC.md) — <summary> · <status>
