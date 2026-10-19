# `YYYY-MM-DD-<slug>` — Decisions, Decision Trees & Rejected Ideas

## Architecture Decision Records
### `ADR-001`: <Decision Title> [Proposed | Accepted | Superseded by `ADR-xxx`]
- **Date**: YYYY-MM-DD · **Depends On**: `REQ-001` · **Reversibility**: One-way | Two-way
- **Statement**: In the context of <X>, facing <forces>, we decided to <choice> to achieve <benefit>, accepting <trade-off>.
- **Rationale**: <P0/P1 drivers>
- **Fitness Function**: <Test, lint or check that proves compliance>
- **Rejected / Ruled Out**: <Alternative A — why>; <Alternative B — why>; <Do nothing — why>

## Decision Trees
### `DT-001`: <Rule Title> [Accepted]
- **Depends On**: `ADR-001`
- **Rule**: IF <condition> → <target>; ELSE IF <condition> → <target>; ELSE → <default>
- **Rationale**: <Why the rule exists>

## Rejected Proposals
### `REJ-001`: <Proposal Title> [Rejected]
- **Date**: YYYY-MM-DD · **Conflicts With**: `NG-001`, `ADR-001`
- **Proposal**: <What was proposed>
- **Rationale**: <Why rejected; what new evidence would reopen it>
