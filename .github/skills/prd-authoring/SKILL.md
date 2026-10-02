---
name: prd-authoring
description: >
  Author comprehensive, testable Product Requirements Documents (PRDs) for new features
  and product initiatives. Use when creating a PRD, authoring product requirements,
  defining feature specs, drafting user journeys, specifying functional and non-functional
  requirements, establishing success metrics and KPIs, or converting feature ideas into
  structured product specs before engineering execution.
---

# Product Requirements Document (PRD) Authoring Skill

Standard Operating Procedure for translating business initiatives and feature requests into rigorous, testable Product Requirements Documents (PRDs) with clear scope boundaries, persona alignment, MoSCoW prioritization, and release gating criteria.

## When to use

- Authoring a new Product Requirements Document (PRD) for a greenfield feature or major capability.
- Formulating unambiguous functional (FR) and non-functional requirements (NFRs).
- Defining user personas, user journeys, and concrete 5-state UI interactions.
- Establishing quantifiable success metrics, instrumentation events, and HEART indicators.
- Slicing release milestones, feature flags, and phased rollout/rollback criteria.
- Scoping out-of-scope non-goals to defend engineering teams against mid-sprint scope creep.

## PRD Authoring Workflow

```mermaid
flowchart LR
    A["1. Discovery & Problem Alignment"] --> B["2. Scope & Requirement Definition"]
    B --> C["3. UX Journey & Contract Modeling"]
    C --> D["4. Non-Functional & Release Gates"]
```

### Phase 1: Problem Alignment & Persona Discovery
1. Frame the core problem statement focusing on affected populations, impediments, and quantifiable friction.
2. Define user personas, their context, jobs-to-be-done (JTBD), and success criteria.
3. Establish explicit **Goals** (measurable business/user outcomes) and **Non-Goals** (features deliberately out of scope).
4. Read `@references/problem-discovery.md`.

### Phase 2: Requirement Specification & MoSCoW Prioritization
1. Enforce clear requirement syntax using normative keywords (MUST, SHOULD, COULD, WON'T) or EARS patterns.
2. Partition functional requirements using MoSCoW prioritization:
   - **Must Have (P0)**: Non-negotiable minimum viable core.
   - **Should Have (P1)**: High-value items with viable interim workarounds.
   - **Could Have (P2)**: Desirable delighters to cut first under schedule pressure.
   - **Won't Have (P3)**: Agreed out-of-scope items deferred to future milestones.
3. Read `@references/requirements-and-moscow.md`.

### Phase 3: UX Journeys & Interface Contracts
1. Map end-to-end user journeys from entry/trigger to successful resolution.
2. Specify the 5 UI States: Ideal/Active, Empty, Loading, Partial, and Error/Fault.
3. Draft interface contracts (API JSON schemas, error dictionaries, data models).
4. Read `@references/user-journeys-and-ux.md`.

### Phase 4: Non-Functional Requirements & Launch Readiness
1. Document NFR targets: Performance (P95 latency, throughput), Security/Privacy (RBAC, encryption), Accessibility (WCAG 2.1 AA), and SLA reliability.
2. Formulate success KPIs and telemetry events using the HEART framework.
3. Detail feature flag configuration, canary rollout stages, and rollback thresholds.
4. Read `@references/nfrs-and-release-criteria.md`.

## Templates & Tooling

| Resource | Path | Purpose |
|---|---|---|
| **Full PRD Template** | `templates/prd-full.md` | Comprehensive PRD template for major capabilities and products |
| **Lightweight PRD Template** | `templates/prd-lightweight.md` | Lean PRD template for targeted enhancements and minor features |
| **PRD Generator Script** | `@scripts/create-prd.py` | CLI scaffold utility (`python3 <skill-dir>/scripts/create-prd.py --title "..."`) |

## Script Invocation

Scaffold a new PRD using the bundled helper:

```bash
# Full feature PRD
python3 <skill-dir>/scripts/create-prd.py --title "Real-Time Activity Feeds" --template full

# Lightweight enhancement PRD
python3 <skill-dir>/scripts/create-prd.py --title "Export Invoice to CSV" --template lightweight -o docs/prd/invoice-csv.md
```
