---
name: pm-task-writer
description: Create and refine project tickets by generating user stories from epics and writing testable acceptance criteria in Gherkin format. Use when breaking down features into actionable user stories or defining 'done' states with clear success/failure scenarios.
---

# Task Writing and Refinement

This skill handles the creation and refinement of project tasks, including generating user stories and defining acceptance criteria.

## When to Use
- When you need to break down an epic into user stories.
- When defining acceptance criteria for a user story to ensure testable requirements.

## Ticket Creation
Translate a feature idea or epic into structured user stories using the "As a [type of user], I want [an action] so that [a benefit]" format.

Process:
1. Confirm the goal.
2. Generate user stories with descriptions.
3. Recommend follow-ups (e.g., acceptance criteria writing).

Output format:
```
Ticket 1: [Story Title]
- User Story: As a [user type], I want to [action], so that [benefit].
- Description: [Context and details].
```

## Acceptance Criteria Writing
Generate testable acceptance criteria in Gherkin format (Given/When/Then) for user stories.

Process:
1. Restate the user story.
2. Write scenarios covering happy paths, edge cases, and failures.
3. Suggest next steps (e.g., technical analysis).

Output format:
```
Scenario 1: Successful [Action]
- Given [context]
- When [action]
- Then [outcome]
```

Use this skill early in planning to clarify requirements.