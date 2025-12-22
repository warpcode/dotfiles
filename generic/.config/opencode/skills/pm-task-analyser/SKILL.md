---
name: pm-task-analyser
description: Analyze and plan software tasks by providing technical briefs, story point estimates, and detailed checklists. Use for scoping work, estimating effort based on complexity/effort/uncertainty, and breaking down features into technical sub-tasks.
---

# Task Analysis and Planning

This skill analyzes tickets, estimates effort, and creates implementation plans.

## When to Use
- When scoping a ticket for technical impact.
- When estimating story points for planning.
- When breaking down a feature into a technical checklist.

## Ticket Analysis
Produce a technical brief by investigating the codebase for impacted areas.

Process:
1. Understand the story and criteria.
2. Investigate files using search tools.
3. Output a structured brief with impacted layers and risks.

Output format:
```
Technical Analysis for: [Ticket Title]

1. Executive Summary
[Overview]

2. Impacted Codebase Areas
- Database: [Changes]
- Backend: [Changes]
- Frontend: [Changes]

3. Key Risks and Considerations
[Risks]
```

## Estimation
Provide story point estimates (1,2,3,5,8,13) based on complexity, effort, and uncertainty.

Process:
1. Review the technical plan.
2. Analyze factors.
3. Output estimate with justification.

Output format:
```
Estimate: X Story Points

Justification:
- Complexity: [Level] - [Details]
- Effort: [Level] - [Details]
- Uncertainty: [Level] - [Details]
```

## Task Splitting
Generate a technical checklist of sub-tasks.

Process:
1. Acknowledge goal.
2. Investigate codebase.
3. Output categorized checklist with dependencies.

Output format:
```
Technical Checklist:
- Database: [Tasks]
- Backend: [Tasks]
- Frontend: [Tasks]
- Testing: [Tasks]

Dependencies: [Notes]
```

## ADHD Task Breakdowns

For ADHD-friendly task planning and decomposition, reference these files as needed: references/adhd-task-strategies.md for universal strategies (e.g., Pomodoro, time estimates); references/adhd-technical-task-breakdowns.md for code-related tasks; references/adhd-real-world-task-breakdowns.md for non-technical tasks. Load only when breaking down complex tasks to reduce overwhelm.

Use this skill after ticket creation to plan implementation.