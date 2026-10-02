# Decision Drivers & Options Evaluation

Framework for identifying architectural forces, enumerating viable options, and evaluating trade-offs systematically.

---

## 1. Decision Drivers (Architectural Forces)

Architectural decisions are never made in a vacuum; they resolve competing forces and constraints:

| Category | Typical Forces | Example Driving Question |
|---|---|---|
| **Quality Attributes** | Performance, Scalability, Availability, Security | Can this option sustain P99 latency < 25ms under 10k RPS? |
| **Operational Costs** | Cloud infrastructure spend, managed vs self-hosted | What is the total cost of ownership over 18 months? |
| **Developer Velocity** | Ergonomics, cognitive load, tooling ecosystem | How steep is the learning curve for standard product engineers? |
| **Organizational Constraints** | Team expertise, vendor lock-in, compliance mandates | Does this comply with SOC2 data locality requirements? |

### Guardrail: Never Invent Unweighted Drivers
Avoid listing superficial drivers. Rank drivers in order of priority:
1. **P0 (Must satisfy)**: Strict constraints (e.g. strict consistency, compliance).
2. **P1 (High weight)**: Key differentiators (e.g. query performance, team familiarity).
3. **P2 (Tie-breakers)**: Nice-to-haves (e.g. third-party plugin availability).

---

## 2. Enumerating Viable Options

Always evaluate at least 2–3 genuine candidates:

1. **The Status Quo**: Continuing with the existing pattern or library (acts as baseline).
2. **The Leading Contender**: The newly proposed paradigm, framework, or architecture.
3. **The Minimal / Counter Alternative**: A simpler or opposing architectural alternative (e.g. pragmatic monolith modularization vs. distributed microservices).

---

## 3. Trade-off Comparison Matrix

Structure comparison tables to make trade-offs transparent across decision drivers:

| Evaluation Criterion (Driver) | Option A: In-Memory Redis Cache | Option B: PostgreSQL Materialized Views | Option C: Read Replicas |
|---|---|---|---|
| **P99 Read Latency** | ⭐⭐⭐ (< 2ms) | ⭐⭐ (< 20ms) | ⭐⭐ (< 25ms) |
| **Data Freshness / Consistency** | ⭐ (Eventual, cache invalidation complexity) | ⭐⭐ (Periodic refresh lag) | ⭐⭐⭐ (Strict replication lag < 100ms) |
| **Operational Overhead** | ⭐ (Requires Redis cluster, sentinel) | ⭐⭐⭐ (Existing DB infrastructure) | ⭐⭐ (Additional replica node management) |
| **Cost** | 💲💲 (Dedicated memory instances) | 💲 (Zero added infra) | 💲💲 (Additional instance compute) |

---

## 4. Nuanced Pros and Cons
For each option:
- Use balanced arguments ("Good, because..." and "Bad, because...").
- Acknowledge genuine drawbacks of the winning option; an ADR that claims the chosen solution has zero cons is suspect and lacks rigor.
