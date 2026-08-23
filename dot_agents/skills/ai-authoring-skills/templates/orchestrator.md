---
name: <task>-orchestrator
description: >
  Dispatches subtasks to specialized subagents for [scenario]. Triggers when
  evaluating [complex multi-part work].
---

# Subagent orchestrator template

Use for coordinating parallel subagents and synthesizing their output.

### Objective
Decompose a complex task, dispatch to specialists, synthesize one report.

### Delegation Workflow

#### Step 1: Decompose
1. Build a manifest of resources; order by dependency.

#### Step 2: Handoff
1. Spawn the matching subagent via your platform's subagent mechanism,
   injecting only the target file(s) + specialist skill — minimal context
   keeps results independent and the parent's context window small.

#### Step 3: Synthesize
1. Collect findings in a fixed schema:
   ```json
   {"file": "path", "severity": "critical|high|medium|low", "finding": "..."}
   ```
2. Merge into a single report/dashboard.

### Exclusion Rules
- Subagents never spawn nested subagents (recursion is uncontrollable and
  burns tokens).
- Never pass parent history into subagent prompts (it bloats context and
  biases independent judgment).

### Exit Criteria
- All results consolidated into one artifact; every dispatched file accounted for.
