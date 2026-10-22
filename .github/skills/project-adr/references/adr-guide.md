# Architecture Decision Records (ADR) Guide

Comprehensive guide for evaluating architectural choices, authoring MADRs, defining automated fitness functions, and managing the supersession lifecycle.

---

## 1. The Rollback Test for ADRs

ADRs represent immutable historical records of why a specific architectural pattern, technology, or interface was adopted. They pass the **Rollback Test**:
> *"If I rolled back our application code by 6 months to fix a massive bug, should this document roll back with it?"*

If you roll back 6 months, the ADRs must roll back to describe the architecture of the codebase at that commit. Never delete or rewrite an accepted ADR in place.

---

## 2. Decision Driver Calibration

Forces must be explicitly ranked to break ties objectively:

1. **P0 (Non-Negotiables)**:
   - Security isolation & secret boundaries (e.g., least privilege, no cleartext secrets).
   - Data safety & transaction invariants (e.g., atomic operations, crash consistency).
   - Compliance & licensing constraints.
2. **P1 (Differentiators)**:
   - Performance (latency, memory footprint, throughput).
   - Agent & token economy (reducing unnecessary tool-call loops, concise outputs).
   - Developer ergonomics & maintainability.
3. **P2 (Tie-Breakers)**:
   - Ecosystem familiarity.
   - Code cleanliness and symmetry with existing repo patterns.

---

## 3. Fitness Functions

An ADR without an automated fitness function is merely wishful thinking. Every accepted ADR must declare how compliance is continuously enforced:

| Decision Type | Fitness Function Pattern | Example Command |
|---|---|---|
| **Directory / Schema Standard** | Static path & schema validator | `python3 scripts/validate.py` |
| **Dependency Restriction** | Dependency tree linter / disallowlist | `pip-audit` / `cargo-deny` |
| **Architectural Boundary** | Import boundary / layer checker | `arch-lint` / `eslint-plugin-import` |
| **Error Handling Invariant** | Static AST checker / test assertion | Unit test asserting typed exceptions |

---

## 4. Lifecycle & Supersession Rules

```text
[ Proposed ] ──► [ Accepted ] ──► [ Superseded by ADR-xxxx ]
      │
      └──► [ Rejected ]
```

### Steps to Supersede an ADR:
1. **Never edit the historical decision of the old ADR**: Keep the text intact so git history and past commits remain explainable.
2. **Author the new ADR**: Use the next sequential number (e.g. `docs/adr/0006-*.md`).
3. **Link Supersession**:
   - In the new ADR: Set `Supersedes: [ADR-0002](0002-slug.md)`.
   - In the old ADR: Update `Status: Superseded by [ADR-0006](0006-slug.md)`.
4. **Update the Index**: Update `docs/adr/README.md` to reflect the new status and link.
5. **Update Dependent Plans**: Flag any requirements in active plans referencing the old ADR as `Needs Review`.
