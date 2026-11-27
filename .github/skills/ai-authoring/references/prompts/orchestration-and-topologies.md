# Orchestration Topologies & Multi-Agent Coordination

Architectural patterns for orchestrating single-agent, multi-agent, and human-in-the-loop workflows across AI artifacts.

---

## 1. Topologies Overview

```mermaid
flowchart TD
    subgraph Patterns["Orchestration Topologies"]
        P1["1. Supervisor / Workers<br/>(Centralized breakdown &amp; rollup)"]
        P2["2. Sequential Pipeline<br/>(Step-by-step handoff A &rarr; B &rarr; C)"]
        P3["3. Router / Classifier<br/>(Classify intent &rarr; dispatch specialist)"]
        P4["4. Evaluator-Optimizer<br/>(Iterative generate &harr; critique loop)"]
        P5["5. Fan-Out / Fan-In<br/>(Parallel batch execution &rarr; merge)"]
        P6["6. Human Checkpoint<br/>(Explicit gate before destructive action)"]
    end
```

---

## 2. Detailed Topology Patterns

### Pattern 1: Supervisor / Coordinator-Workers

A central coordinator decomposes a complex goal into discrete tasks, delegates them to specialized workers (subagents or tool calls), and synthesizes the outputs into a coherent final result.

```mermaid
flowchart TD
    User["User Request"] --> Coord["Coordinator Agent"]
    Coord -->|Delegates Task 1| W1["Worker: Researcher (read-only)"]
    Coord -->|Delegates Task 2| W2["Worker: Implementer"]
    Coord -->|Delegates Task 3| W3["Worker: Reviewer (strict)"]
    W1 -->|Returns Findings| Coord
    W2 -->|Returns Code Diff| Coord
    W3 -->|Returns Audit Report| Coord
    Coord --> Result["Final Synthesis / Response"]
```

- **Best For**: End-to-end features, full-stack migrations, complex refactors.
- **Key Directive**: The coordinator maintains high-level state and never performs high-noise exploration itself. Workers return structured summaries.
- **Context Isolation Rule**: Each worker prompt MUST be context-complete (file paths, constraints, expected output format) because subagents do not inherit coordinator chat history.

---

### Pattern 2: Sequential Pipeline

Linear multi-stage process where the output of phase $N$ becomes the input context for phase $N+1$.

```mermaid
flowchart LR
    Plan["Phase 1: Planning<br/>Requirements &amp; Architecture"] --> Code["Phase 2: Implementation<br/>Surgical Code Edits"]
    Code --> Test["Phase 3: Verification<br/>Run Test Suites"]
    Test --> Review["Phase 4: Review<br/>PR Ready Report"]
```

- **Best For**: Strict CI/CD lifecycles, release workflows, ticket resolution pipelines.
- **Key Directive**: Define clear exit gates between each phase. A phase MUST NOT start until the previous phase passes verification.

---

### Pattern 3: Router / Intent Classifier

A lightweight classification step inspects the input query and routes it to the optimal specialized persona or skill.

```mermaid
flowchart TD
    Query["User Input"] --> Router{"Router / Classifier"}
    Router -->|Bug Report / Crash| Bug["Debug Specialist"]
    Router -->|Feature Request| Arch["Feature Architect"]
    Router -->|Security / Auth| Sec["Security Auditor"]
    Router -->|Documentation / Docs| Doc["Technical Writer"]
```

- **Best For**: Triage agents, customer support bots, multi-domain developer CLIs.
- **Key Directive**: Keep the classifier prompt zero-shot and lightweight. Return a typed category identifier.

---

### Pattern 4: Evaluator-Optimizer (Critic-Refiner)

An iterative loop where a Generator produces candidate content, an Evaluator critiques it against strict rubrics, and the Generator refines it until quality thresholds are satisfied.

```mermaid
flowchart TD
    Goal["Task Objective"] --> Gen["Generator Agent<br/>(Drafts solution)"]
    Gen --> Eval{"Evaluator / Critic<br/>(Audits against rubric)"}
    Eval -->|Issues Found &amp; Iterations &lt; Max| Refine["Refinement Directive"]
    Refine --> Gen
    Eval -->|Passes All Checks| Complete["Final Approved Output"]
```

- **Best For**: High-stakes code generation, security audits, technical document authoring.
- **Key Directive**: Cap iterations (e.g. max 2–3 loops) to prevent infinite refinement cycles.

---

### Pattern 5: Fan-Out / Fan-In (Parallel Map-Reduce)

Concurrently dispatching identical or partitioned tasks across multiple isolated workers, followed by an aggregation step.

```mermaid
flowchart TD
    Batch["Input List: [Item 1..N]"] --> Split["Fan-Out Dispatcher"]
    Split --> S1["Worker 1 (Item 1)"]
    Split --> S2["Worker 2 (Item 2)"]
    Split --> S3["Worker 3 (Item 3)"]
    S1 --> Join["Fan-In Aggregator"]
    S2 --> Join
    S3 --> Join
    Join --> Summary["Consolidated Rollup Report"]
```

- **Best For**: Linting across 50 repositories, surveying large directories, benchmark evaluation suites.
- **Key Directive**: Workers must output token-efficient structured JSON or markdown rows so the aggregator can easily reduce the dataset.

---

### Pattern 6: Human-in-the-Loop Checkpoint Gate

A guardrail pattern that pauses execution before destructive, state-mutating, or high-risk operations to request explicit human approval.

```mermaid
flowchart TD
    Plan["Generate Implementation Plan"] --> Gate{"Human Approval Gate<br/>(Review Plan &amp; Diffs)"}
    Gate -->|Approved| Exec["Execute Destructive Mutation<br/>(Git push, file deletion, DB drop)"]
    Gate -->|Rejected / Feedback| Adjust["Adjust Plan per Feedback"]
    Adjust --> Plan
```

- **Best For**: Database migrations, live deployments, git rebase/push operations, deleting files.
- **Key Directive**: Clearly state: `**STOP & PROMPT**: Present plan and request explicit user confirmation before proceeding.`
