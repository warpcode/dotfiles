---
name: <prefix>-<workflow-name>
description: >
  Triggers when [exact trigger/action]. Use to run [procedure] and produce
  verifiable evidence of completion.
---

# Workflow / SOP template

Use for multi-stage procedures that must run in order.

### Objective
Provide a repeatable procedure to [outcome], producing physical evidence.

### When to Use
- Triggered when: [task context]
- File scopes: [paths/extensions]

### Procedural Phases
Execute in linear order; do not skip phases. Give each phase a one-line why —
agents skip steps whose purpose is unclear.

#### Phase 1: Setup
1. [Discovery/setup steps]

#### Phase 2: Execution
1. [SOP steps, third-person imperative]

#### Phase 3: Validation
1. Run [validation command].
2. [Self-audit checks]

### What NOT to Do (Anti-Rationalization)
Rebuttals must carry the reason, not just the command:
- Excuse: "Too simple to validate." → Rebuttal: "Small changes break integration points silently; run Phase 3 unconditionally."
- Excuse: "I'll refactor adjacent code while here." → Rebuttal: "Unreviewed scope creep is the top source of regressions; touch only what was asked."

### Examples (optional)
- Input: [realistic invocation] → Output: [expected result]

### Gotchas
- [Quirks/failures discovered through testing]

### Exit Criteria
- [Evidence proportionate to verifiability: logs/checklist output for objective
  outcomes; a structured qualitative review for subjective ones]
