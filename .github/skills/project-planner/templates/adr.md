# ADR-[NUMBER]: [Title]

| Metadata | Details |
|---|---|
| **Status** | Proposed | Accepted | Superseded by `ADR-xxx` |
| **Date** | YYYY-MM-DD |
| **Deciders** | [Author / Deciders] |
| **Depends On** | `REQ-xxx` |
| **Reversibility** | One-way | Two-way |

---

## 1. Context and Problem Statement

[Describe the context and problem in 2–4 sentences. What technical, architectural, or business forces drive this decision?]

## 2. Decision Drivers

- **P0 (Non-Negotiables)**: [Security, isolation, data integrity, compliance constraints]
- **P1 (Differentiators)**: [Performance, developer ergonomics, maintainability]
- **P2 (Tie-Breakers)**: [Familiarity, ecosystem conventions]

---

## 3. Considered Options

1. **Option 1**: [Chosen Option Name]
2. **Option 2**: [Alternative A]
3. **Option 3**: [Alternative B / Do Nothing]

---

## 4. Decision Outcome

**Chosen option**: **Option 1 ([Name])**, because [primary rationale tying back to P0/P1 drivers].

> *In the context of [scope/component], facing [forces], we decided to [chosen option] to achieve [primary benefit], accepting [trade-off].*

### Positive Consequences
- [Capability unlocked or performance/maintainability benefit]

### Negative Consequences / Trade-offs
- [Trade-off, operational overhead, or complexity cost accepted]

---

## 5. Pros and Cons of the Options

### Option 1: [Chosen Option]
- Good, because [pro 1]
- Bad, because [trade-off / cost]

### Option 2: [Alternative A]
- Good, because [pro 1]
- Bad, because [reason rejected / ruled out]

### Option 3: [Do Nothing / Alternative B]
- Good, because [minimal effort]
- Bad, because [fails drivers]

---

## 6. Fitness Function & Validation

- **Fitness Function**: [Exact automated test, linter, or architectural check that proves compliance]
- **Enforcement**: [`./validate.sh`, CI pipeline, or static test suite]
