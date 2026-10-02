---
name: adr-authoring
description: >
  Record, evaluate, and track Architecture Decision Records (ADRs) across system design,
  technology evaluation, and codebase refactoring. Use when creating an ADR,
  documenting architectural decisions, evaluating technical trade-offs, recording
  technology stack choices, proposing design alterations, tracking architectural
  compliance, or establishing MADR records.
---

# Architecture Decision Record (ADR) Authoring Skill

Standard Operating Procedure for capturing, reviewing, and tracking architectural decisions through immutable Architecture Decision Records (ADRs) with explicit decision drivers, balanced trade-off matrices, and compliance fitness functions.

## When to use

- Documenting significant architectural choices (frameworks, databases, protocols, service boundaries).
- Recording technical trade-offs and options considered during design discussions or RFCs.
- Proposing changes to established technical conventions or system topologies.
- Establishing sequential MADR (Markdown Architecture Decision Record) or Nygard formatted records.
- Deprecating or superseding past architectural decisions as requirements evolve.
- Defining automated fitness functions to verify architecture compliance over time.

## ADR Lifecycle Workflow

```mermaid
flowchart LR
    A["1. Context & Forces Discovery"] --> B["2. Option Matrix & Trade-off Analysis"]
    B --> C["3. Decision Formulation"]
    C --> D["4. Consequence & Verification Mapping"]
```

### Phase 1: Context & Forces Discovery
1. Document the current technical state, architectural constraint, or business trigger.
2. Formulate prioritized **Decision Drivers** (P0 non-negotiables, P1 differentiators, P2 tie-breakers).
3. Confirm ADR lifecycle state (`Draft`, `Proposed`, `Accepted`, `Rejected`, `Deprecated`, `Superseded`).
4. Read `@references/adr-lifecycle-and-structure.md`.

### Phase 2: Options & Trade-off Evaluation
1. Enumerate 2–3 viable candidate options (including the status quo baseline).
2. Construct a weighted comparison matrix evaluating options against decision drivers.
3. Detail honest pros and cons for each option without minimizing drawbacks.
4. Read `@references/options-and-tradeoffs.md`.

### Phase 3: Decision Formulation
1. Articulate the decision using the canonical formula: *In the context of [X], facing [forces], we decided to [option] to achieve [benefit], accepting [trade-off].*
2. Ensure the scope and non-applicability boundaries of the decision are explicit.
3. Record dissenting perspectives respectfully to maintain architectural transparency.
4. Read `@references/decision-criteria.md`.

### Phase 4: Consequences & Compliance Mapping
1. Map positive capabilities unlocked, negative trade-offs/debt accepted, and neutral side effects.
2. Establish automated **Architectural Fitness Functions** (linters, boundary tests, CI checks).
3. Define specific review triggers (scale thresholds or date-based checkpoints).
4. Read `@references/consequences-and-compliance.md`.

## Templates & Tooling

| Resource | Path | Purpose |
|---|---|---|
| **MADR Template** | `templates/adr-madr.md` | Rich MADR format with decision drivers, options matrix, and pros/cons |
| **Nygard Template** | `templates/adr-nygard.md` | Classic lightweight format (Context, Decision, Consequences) |
| **Scaffold Script** | `@scripts/create-adr.py` | Auto-detects next sequential number and renders template |
| **List Script** | `@scripts/list-adrs.py` | Scans ADR directory and outputs formatted index or JSON |

## Script Invocations

Scaffold or index ADRs using the bundled helpers:

```bash
# Scaffold next sequential ADR using MADR template
python3 <skill-dir>/scripts/create-adr.py --title "Adopt OpenTelemetry for Distributed Tracing" --template madr

# Scaffold lightweight Nygard ADR superseding a previous record
python3 <skill-dir>/scripts/create-adr.py --title "Switch Cache Store to Redis Cluster" --template nygard --supersedes 0004

# List all ADRs in the current repository
python3 <skill-dir>/scripts/list-adrs.py --dir docs/adr
```
