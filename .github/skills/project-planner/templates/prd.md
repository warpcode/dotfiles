# PRD: [Product / Feature Name]

| Metadata | Details |
|---|---|
| **Author / Team** | [Author / Team] |
| **Status** | Draft | In Review | Approved | In Development | Complete |
| **Target Date** | YYYY-MM-DD |
| **Target Milestone** | [Milestone / Release] |

---

## 1. Problem Statement & Target Outcome
- **Problem**: [Who is affected, what is the pain point, and why solve this now?]
- **Outcome / Value**: [Measurable success metric and target outcome unlocked]

---

## 2. Goals & Non-Goals
- **Goals (`G-*`)**:
  - `G-001`: [Measurable outcome and target metric]
  - `G-002`: [Secondary objective]
- **Non-Goals (`NG-*`)**:
  - `NG-001`: [Explicitly out of scope capability]
  - `NG-002`: [Deferred consideration]

---

## 3. User Journeys & Flows
**As a** [user persona],  
**I want to** [perform specific action],  
**So that** [achieve desired outcome].

### Core Flow
1. **Entry**: User accesses [entrypoint / interface].
2. **Action**: User provides [input / triggers operation].
3. **Outcome**: System processes request and returns [verifiable result].
4. **Edge / Error**: If [condition fails], system provides [deterministic fallback / error].

---

## 4. Requirements & Acceptance Criteria
### Functional Requirements
- **`REQ-001`** [P0]: WHEN [trigger], the [component] SHALL [response].
  - [ ] Given [precondition], when [action], then [outcome].
  - [ ] Given [invalid input], when [action], then [error].
- **`REQ-002`** [P1]: The [component] SHALL [behavior].

### Non-Functional Requirements (NFRs)
- **Performance**: Latency < [target] ms, throughput $\ge$ [target].
- **Security & Secrets**: [Authz, credential handling, isolation boundaries].
- **Reliability & Observability**: [Error logging, fallback behavior, metrics].

---

## 5. Milestones & Tasks
- **`M-001`**: [Phase 1 Title] — Exit criteria: [Checkable condition]
  - `TSK-001`: [Task Title] (Target files: `path/to/file`, Done command: `./validate.sh`)

---

## 6. Open Questions & Assumptions
- **`ASM-001`**: [Key assumption] (Validation: [How verified], If false: [Impact])
- **`Q-001`**: [Blocking / Non-blocking open question]
