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

### Script-First Design (author this section before the phases)

**Gather first, then act.** Every phase is one script invocation, not a list of
commands the agent runs one at a time.

**The gather contract** — what must be known before anything may be judged or
changed. Write this before writing any script:

| Fact needed to act safely | Retrieved by | Gap if unavailable |
|---|---|---|
| [identity: owner/repo/ids/ref] | | |
| [current state] | | |
| [verification: checks/dependencies] | | |
| [requirements: source issue, acceptance criteria] | | |

Workflow shape: **GATHER (one script) → REASON (agent judgement) → ACT (one
confirmed call).**

| Phase | Question it answers | Script | Output schema |
|---|---|---|---|
| 1. Gather | | `<skill-dir>/scripts/<name>.sh --flags` | `{...}` |
| 2. Reason | *(agent judgement over Phase 1 output)* | — | — |
| 3. Act | | `<skill-dir>/scripts/<name>.sh --apply` | `{...}` |

Rules:
- If a phase needs ≥2 tool calls, it is one script, not a numbered list.
- No phase acts before the gather phase has run.
- Mechanical work (collect, diff, compare, classify, tally) happens in the
  script. The agent reasons over the result; it never hand-rolls the logic.
- Facts that cannot be retrieved surface as explicit gap fields. Never default
  a missing check to "passed" or an unreadable field to "empty".
- Scripts are read-only by default; mutations need an explicit flag and
  explicit user approval.
- Large output goes to `--out <dir>`; the script prints a summary and the agent
  reads ranges. Long stdout gets truncated and yields false conclusions.
- No shell loops, `jq` chains, or inline `python3 -c` in this file — ever.

### Bundled Scripts

| Script | Purpose | Output | Run when |
|---|---|---|---|
| `@scripts/<name>.sh` | [question it answers] | [schema] | [condition] |

### Procedural Phases
Execute in linear order; do not skip phases. Give each phase a one-line why —
agents skip steps whose purpose is unclear.

#### Phase 1: Setup
1. Run `bash <skill-dir>/scripts/<name>.sh` → returns [fields].
2. Agent judgment only: [what requires reasoning, not mechanical work].

#### Phase 2: Execution
1. Run [invocation] → returns [fields].
2. Agent judgment only: [decision the agent makes].

#### Phase 3: Validation
1. Run [validation command] (one call; exit code carries the verdict).
2. [Self-audit checks]

### What NOT to Do (Anti-Rationalization)
Rebuttals must carry the reason, not just the command:
- Excuse: "Too simple to validate." → Rebuttal: "Small changes break integration points silently; run Phase 3 unconditionally."
- Excuse: "I'll refactor adjacent code while here." → Rebuttal: "Unreviewed scope creep is the top source of regressions; touch only what was asked."
- Excuse: "It's only 2-3 commands, I'll just run them directly." → Rebuttal:
  "That is the pattern this skill exists to prevent. Two calls today become five
  next quarter, and the agent re-derives the sequencing logic at runtime,
  inconsistently. Write the script."
- Excuse: "I'll chain the existing `get-*.sh` and `list-*.sh` scripts instead." →
  Rebuttal: "A chain of atomic scripts is a bundle nobody wrote. It also risks
  correlating snapshots taken at different instants."

### Examples (optional)
- Input: [realistic invocation] → Output: [expected result]

### Gotchas
- [Quirks/failures discovered through testing]

### Exit Criteria
- [Evidence proportionate to verifiability: logs/checklist output for objective
  outcomes; a structured qualitative review for subjective ones]
