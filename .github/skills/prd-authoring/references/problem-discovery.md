# Problem Discovery & Persona Alignment

Guidance for discovering user pain points, framing the core problem statement, defining personas, and establishing guardrail non-goals before detailing feature requirements.

---

## 1. Framing the Problem Statement

An effective PRD starts with the *problem* in the user's world, not the technical solution in our architecture.

### The 4-Part Problem Anatomy
1. **Target Population**: Who specifically suffers from this problem? (e.g. "Staff software engineers running multi-repo CI workflows", not "All users").
2. **Context & Trigger**: In what context or workflow does the breakdown occur?
3. **Core Impediment / Friction**: What prevents them from achieving their goal? What workarounds are they forced to use?
4. **Quantifiable Pain / Cost**: What is the impact? (e.g., lost hours, drop in conversion, compliance violation, system instability).

### Anti-Patterns in Problem Definition
- **Solution Masquerading as a Problem**: "We don't have a GraphQL endpoint." (Wrong: What can users not do because of this?)
- **Vague Generalizations**: "The UI is clunky and slow." (Wrong: Which screen? What interaction? What latency?)
- **Lack of Evidence**: Basing problems on personal assumptions rather than telemetry, user interviews, or operational tickets.

---

## 2. Defining Personas

Document realistic, behavioral personas rather than superficial demographic caricatures:

| Persona Dimension | Focus | Example |
|---|---|---|
| **Role & Context** | Responsibilities, technical fluency, day-to-day workflow | Lead DevOps Engineer running infrastructure automation |
| **Jobs to Be Done (JTBD)** | Primary goal when using this product area | Ensure zero-downtime database migrations with automated rollbacks |
| **Frustrations / Blockers** | Concrete obstacles preventing success | Unclear lock behavior causing table deadlocks during business hours |
| **Success Criteria** | How the user judges that the feature succeeded | Instant visibility into migration locks without querying raw pg_stat_activity |

---

## 3. Goals vs. Non-Goals

Defining Non-Goals is as critical as defining Goals. Non-goals protect the engineering team from mid-sprint scope creep and gold-plating.

### Goal Principles
- Must be outcome-oriented rather than output-oriented.
- Formulate with measurable boundaries (e.g., "Reduce onboarding checkout drop-off by 15%", not "Build a better checkout page").

### Non-Goal Principles
- Identify adjacent, tempting features that are deliberately out of scope for the current milestone.
- Document the rationale for exclusion (e.g. "Multi-currency support is deferred to Q3 to maintain our Q2 launch date").
- Prevent future bikeshedding by giving engineers and reviewers a clear boundary reference.
