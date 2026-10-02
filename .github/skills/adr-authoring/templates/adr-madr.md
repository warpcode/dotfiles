# ADR-[NUMBER]: [Title]

| Metadata | Details |
|---|---|
| **Status** | [Status] |
| **Date** | [Date] |
| **Deciders** | [Author / Deciders] |
| **Superseded By / Supersedes** | [Superseded By / Supersedes] |

---

## Context and Problem Statement

[Describe the context and problem statement in 2-4 sentences. What is the current architectural situation or constraint? What technical or business requirements drive this decision?]

## Decision Drivers

- **Driver 1**: [e.g. Requirement to scale horizontally to 50k RPS with <10ms latency]
- **Driver 2**: [e.g. Developer ergonomics and local testability without cloud dependencies]
- **Driver 3**: [e.g. Licensing, infrastructure cost, and maintenance overhead]

---

## Considered Options

1. **Option 1**: [Name of option 1]
2. **Option 2**: [Name of option 2]
3. **Option 3**: [Name of option 3]

---

## Decision Outcome

**Chosen option**: **Option 1 ([Name of option 1])**, because [clear rationale tying back to the primary decision drivers].

### Positive Consequences
- [Positive consequence 1 / key capability unlocked]
- [Positive consequence 2 / performance or maintainability improvement]

### Negative Consequences
- [Trade-off or complexity cost accepted]
- [Operational or tooling requirement introduced]

---

## Pros and Cons of the Options

### Option 1: [Name of option 1] (Chosen)
- Good, because [pro 1]
- Good, because [pro 2]
- Bad, because [con 1 / trade-off]

### Option 2: [Name of option 2]
- Good, because [pro 1]
- Bad, because [con 1]
- Bad, because [con 2]

### Option 3: [Name of option 3]
- Good, because [pro 1]
- Bad, because [con 1]

---

## Validation & Compliance Strategy

- **Architectural Fitness Functions**: [Automated unit tests, linters, or structural rules verifying compliance]
- **Enforcement Mechanism**: [CI pipeline check / PR review checklist]
- **Review Trigger**: [Conditions or scale thresholds that warrant revisiting this decision]
