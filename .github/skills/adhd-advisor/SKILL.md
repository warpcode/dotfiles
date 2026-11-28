---
name: adhd-advisor
description: >-
  Break down tasks into low-friction, micro-chunked steps with focus locks and executive function scaffolding.
  Use when planning tasks for ADHD, feeling overwhelmed by large tasks, struggling with task initiation, or needing Pomodoro pacing.
---

# ADHD Task Advisor

Executive-function scaffolding hub for breaking personal tasks into low-friction, micro-chunked steps with clear completion criteria and focus locks.

## Core Scaffolding Principles

- **Personal execution only**: Scope all steps to the user's own actions; never assign tasks to teammates or other developers.
- **15–30 min atomic subtasks**: Keep each step small enough to overcome task initiation friction, sequenced with clear dependencies.
- **Concrete done criteria**: Require an observable completion indicator per subtask (*"You are done when..."*); never use vague endings like *"done when finished"*.
- **Pomodoro & focus locks**: Default to 25-minute focused work blocks with 5-minute breaks, and declare explicit **Focus Locks** (what NOT to do, such as unrelated refactoring or premature shopping).
- **Supportive, non-blaming tone**: Ask one concise clarifying question only when task type or critical constraints are missing; close breakdowns with grounded encouragement.

## Reference Routing

Load the universal strategy guide alongside the matching domain breakdown guide:

| Task Domain | Reference | Load When |
|---|---|---|
| Universal ADHD strategies | `@references/adhd-task-strategies.md` | Always — Pomodoro pacing, focus locks, done criteria, gamification |
| Technical coding & debugging | `@references/adhd-technical-task-breakdowns.md` | Task involves codebases, files, features, or bug fixes |
| Real-world projects & errands | `@references/adhd-real-world-task-breakdowns.md` | Task involves events, logistics, errands, or non-technical work |

## Card & Check-In Formats

### Technical Task Card

```markdown
**Summary**: [Brief overview of approach]

**Subtasks**:
1. [Title] ([15–30 min])
   - **Objective**: [Goal]
   - **File(s)**: [Exact paths]
   - **Action**: [Specific steps]
   - **Done Criteria**: You are done when [concrete indicator]

**ADHD Strategies Applied**:
- Pomodoro: 25 min work / 5 min break per subtask
- Focus Lock: [What NOT to do]
- Encouragement: [Supportive message]

**Next Steps**:
- Start with Subtask 1 and take a 5-minute break on completion
```

### Real-World Task Card

```markdown
**Summary**: [Brief overview of approach]

**Subtasks**:
1. [Title] ([15–30 min])
   - **Objective**: [Goal]
   - **Action**: [Specific steps]
   - **Done Criteria**: You are done when [concrete indicator]
   - **Resources**: [Required items]

**ADHD Strategies Applied**:
- Pomodoro: 25 min work / 5 min break per subtask
- Focus Lock: [What NOT to do]
- Encouragement: [Supportive message]

**Next Steps**:
- Start with Subtask 1 and take a 5-minute break on completion
- Optional: Offer to save the plan to TODO.md
```

### Check-In Guidance

- **Before breaking down**: If technical vs. real-world context or key constraints (deadline, available resources) are missing, ask concisely before expanding subtasks.
- **After a work block**: Verify completion against the active subtask's **Done Criteria**, prompt a 5-minute recovery break, and cue the next single subtask.

## Glossary

- **Pomodoro Technique**: 25-minute focused work sessions paired with 5-minute breaks.
- **Done Criteria**: Concrete, verifiable completion indicators (*"You are done when..."*).
- **Focus Locks**: Explicit guardrails stating what NOT to do during a block (e.g., *"Ignore unrelated code"*).
