# Decision Formulation & Criteria

Guidance for articulating the decisive choice, establishing clear rationale, and documenting dissenting perspectives.

---

## 1. The Decision Formulation Formula

The decision outcome must be concise, declarative, and directly linked to the driving forces.

### The Canonical Formula
> *"In the context of **[Context / Problem]**, facing **[Key Decision Drivers]**, we decided to choose **[Chosen Option]** to achieve **[Primary Benefit]**, accepting **[Key Trade-Off / Consequence]**."*

### Example Formulations
- **Strong**: *"In the context of processing 50,000 webhook events per minute, facing burst traffic spikes and strict at-least-once delivery requirements, we decided to adopt Apache Kafka over RabbitMQ to achieve partitioned high-throughput durability, accepting the operational complexity of managing ZooKeeper/KRaft metadata clusters."*
- **Weak**: *"We decided to use Kafka because it is fast and modern."* (Lacks context, drivers, and admitted trade-offs).

---

## 2. Decision Criteria Checklist

Before moving an ADR from `Draft` to `Proposed`:
- [ ] Does the decision solve the root problem stated in Context?
- [ ] Are the trade-offs of the chosen option explicitly documented?
- [ ] Is the scope of the decision clearly bounded (what it does NOT apply to)?
- [ ] Can an engineer reading this in 3 years understand *why* this choice was made over the alternatives available at the time?

---

## 3. Recording Dissent and Non-Consensus

Architectural consensus is not always unanimous. When senior engineers or architects hold dissenting views:
- Document the alternative proposal fairly under Considered Options.
- In the Decision Outcome or Notes, record the dissenting perspective respectfully:
  *"Dissenting View: Team members raised concerns regarding memory pressure under extreme workloads. We agreed to mitigate this by implementing strict heap bounds and synthetic canary load tests."*
- This preserves organizational trust and ensures past objections can be cleanly re-evaluated if conditions change.
