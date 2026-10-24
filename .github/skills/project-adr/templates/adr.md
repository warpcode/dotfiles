# [ADR-0000]: [Short Title of Solved Problem / Choice]

| Metadata | Details |
|---|---|
| **Status** | Proposed \| Accepted \| Superseded by [ADR-0000](0000-slug.md) \| Deprecated |
| **Date** | YYYY-MM-DD |
| **Deciders** | [Names / Team / Agent] |
| **Reversibility** | One-way door (costly/irreversible) \| Two-way door (reversible) |
| **Depends On** | [`REQ-000x`](../plans/YYYY-MM-DD-slug/SPEC.md#req-000x) or None |
| **Supersedes** | [ADR-0000](0000-slug.md) or None |

---

## 1. Context & Problem Statement
[What is the context, what problem are we solving, and what forces are driving this decision? 1–2 paragraphs.]

---

## 2. Decision Drivers (Forces)
Rank the forces acting on this choice:
- **P0 (Non-Negotiables)**: [Security, isolation boundaries, data integrity, regulatory compliance]
- **P1 (Differentiators)**: [Latency, throughput, token/tool-call economy, developer ergonomics]
- **P2 (Tie-Breakers)**: [Familiarity, community momentum, ecosystem conventions]

---

## 3. Considered Options
- **Option 1**: [Description]
- **Option 2**: [Description]
- **Option 3**: [Do Nothing / Status Quo]

---

## 4. Decision Outcome
**Chosen Option**: **Option [X]** because [primary reason aligned with P0/P1 forces].

### Canonical Statement
> *In the context of **[system/module scope]**, facing **[decision drivers / constraints]**, we decided to **[chosen option]** to achieve **[primary benefit]**, accepting **[consequence / trade-off]**.*

### Consequences & Trade-offs
- **Positive**: [What is unlocked or improved]
- **Negative / Costs**: [Overhead, complexity, operational burden accepted]
- **Risks**: [Failure modes and mitigation strategy]

---

## 5. Automated Fitness Function
Every accepted ADR must define an automated check proving ongoing repository compliance:
- **Check Type**: Linter \| Static Check \| Unit Test \| Integration Suite
- **Command**: `[Exact verification command, e.g. ./validate.sh --lint-only]`
- **Failure Condition**: [What specific signal fails CI if this decision is violated]

---

## 6. Pros and Cons of the Options

### Option 1: [Name]
- Good, because [argument]
- Bad, because [argument]

### Option 2: [Name]
- Good, because [argument]
- Bad, because [argument]

### Option 3: Do Nothing
- Good, because [no immediate implementation cost]
- Bad, because [problem remains unsolved, tech debt accumulates]
