---
name: pm-planning
description: >
  Break down feature requests into structured JIRA/GitHub tickets, user stories,
  technical tasks, acceptance criteria, and story point estimates. Use when
  planning a new feature, writing technical specifications, creating issue
  tickets, or organizing agile sprint backlogs.
---

# Product & Technical Planning Skill

Standard Operating Procedure for translating business requirements and feature requests into actionable user stories, technical task decompositions, and Jira/GitHub tickets.

## When to use

- Decomposing a high-level feature request or PRD into technical work units.
- Authoring well-structured GitHub Issues, Jira Epics, Stories, and Subtasks.
- Defining testable Acceptance Criteria (Given-When-Then / Gherkin format).
- Estimating engineering complexity and story points (Fibonacci or 0.1–5 scale).
- Clarifying frontend, backend, database, and DevOps task dependencies.

## Planning Workflow

```
┌─────────────────┐     ┌──────────────────────┐     ┌─────────────────────┐
│ 1. Requirements │ ──► │ 2. Technical Task    │ ──► │ 3. Ticket Drafting  │
│    Decomposition│     │    Boundary Mapping  │     │    & Estimation     │
└─────────────────┘     └──────────────────────┘     └─────────────────────┘
```

### Phase 1: Requirements Decomposition & User Story Framing
1. Identify the core user persona, goal, and business value.
2. Frame the user story: *As a [persona], I want [goal], so that [value].*
3. Formulate clear, non-ambiguous Acceptance Criteria.
4. Read `@references/ticket-format.md`.

### Phase 2: Technical Task & Boundary Mapping
1. Break down the story across functional layers:
   - **Database**: Migrations, schema updates, seeders, index additions.
   - **Backend**: API endpoints, controllers, domain services, validation rules.
   - **Frontend**: UI components, state stores, API clients, form handling.
   - **DevOps / Infra**: Environment variables, background workers, queues.
2. Read `@references/task-decomposition.md`.

### Phase 3: Complexity Estimation & Ticket Drafting
1. Assign complexity estimates using the calibrated scale (0.5 = trivial/config, 1 = straightforward single-layer change, 2 = multi-layer change, 3 = complex multi-system feature, 5 = high-risk architectural epic).
2. Output formatted markdown ready for GitHub Issue or Jira creation.

## Output Contract: Issue Specification

```markdown
# [Feature / Ticket Title]

## Context & User Story
**As a** [user persona],
**I want to** [action/capability],
**So that** [business benefit or outcome].

## Acceptance Criteria
- [ ] **AC 1**: Given [context], when [action occurs], then [expected outcome].
- [ ] **AC 2**: Given [invalid input], when [submission attempted], then [validation error returned].

## Technical Tasks
- [ ] **[BE] Database & API**: Create migration, model, and REST endpoint (`POST /api/v1/...`). *(Est: 1.0 pt)*
- [ ] **[FE] Component & State**: Build UI view and integrate with API client. *(Est: 1.0 pt)*
- [ ] **[QA] Automated Tests**: Write unit and integration regression tests. *(Est: 0.5 pt)*

## Edge Cases & Considerations
- Security/auth requirements.
- Backward compatibility or migration notes.
```
