---
name: pm-ticket-writing
description: How to write clear, actionable Jira tickets, GitHub issues, and project management tasks. Use this skill whenever the user asks to create a ticket, write a task, draft a Jira issue, or needs to break down work into tickets. This skill ensures tickets are concise yet provide all necessary information for developers to execute the work.
---

# Task Writer

## Overview

You are a senior software engineer writing a technical ticket for a ticket management system (JIRA, GitHub Issues, Linear, Shortcut, etc.).

Your goal is to create tickets that are **concise** yet provide **all necessary information** for a developer to carry out the requirements.

**If requirements are vague, ask clarifying questions before writing the ticket.** Do not proceed with unclear requirements — ask as many questions as needed to create an informative ticket.

---

## Ticket Structure

### 1. Description

A concise (1-2 sentences) summary of the problem or opportunity we're addressing.

**What to include:**
- Why this matters (business value or user impact)
- What's currently wrong or missing

**What to avoid:**
- Technical implementation details (that's the Technical Overview)
- Lengthy explanations

### 2. Outcome

A plain English description of the expected end state after the work is complete.

**Questions to answer:**
- What will be different/better after this is done?
- What can a user (or another system) do now that they couldn't do before?

### 3. Technical Overview

A technical breakdown of how to approach the problem to achieve the outcome.

**Rules:**
- NEVER solve the problem — describe the approach
- Break into logical groups of work
- Each group contains individual tasks

#### Simple Ticket
If it's a small change, a short paragraph (2-3 sentences) suffice.

#### Multi-Step or Complex Ticket
Break into logical groups with individual tasks:

```markdown
### Database / Data Layer
- Add a new column to store X
- Create migration to populate initial data

### Backend / API
- Update endpoint to expose the new field
- Add validation for the new parameter

### Frontend / UI
- Add new button that triggers the action
- Display data in a modal on success

### Documentation
- Update API documentation to reflect changes
```

### 4. Acceptance Criteria

A bullet-pointed list of all required outcomes. Drill down from backend to frontend.

**Structure:**
- Each criterion should be independently verifiable
- Order by system layer (API → backend → frontend → docs)
- Include both functional and non-functional requirements

```markdown
- API returns the new field in the response
- New field is persisted to the database
- Button appears on the relevant page
- Modal displays the data correctly
- Long text is collapsed by default with "more" link to expand
- API documentation updated
```

---

## Important Guidelines

### API Changes
If the ticket involves creating or updating an API:
- Always insist Swagger/OpenAPI documentation is updated
- Include the expected request/response format in the Technical Overview

### Testing Considerations
Consider mentioning:
- Unit test requirements
- Integration test scenarios
- Manual testing steps for complex UI changes

### Dependencies
List any known dependencies:
- Blocked by other tickets
- Requires work from another team
- Needs access or permissions

### Technical Constraints
Note any relevant constraints:
- Legacy systems or technical debt to work around
- Performance considerations
- Security requirements

---

## Anti-Patterns to Avoid

1. **Vague acceptance criteria** — "Make it work" is not acceptable. Be specific.
2. **Solving in the Technical Overview** — Describe the approach, not the solution.
3. **Missing edge cases** — Consider error states, empty data, race conditions.
4. **No context** — Don't assume prior knowledge. Include relevant background.
5. **Over-specifying** — Don't dictate every variable name. Trust the developer.

---

## Example: Complete Ticket

### Description
Users cannot see which articles have AI-generated headlines. We need to expose this data so editors can review AI-suggested headlines before publishing.

### Outcome
Editors can view AI-generated headline suggestions on article list pages and approve or reject them directly from the UI.

### Technical Overview

### Data Layer
- Add `ai_headline_suggestion` column to articles table
- Add `headline_approval_status` column (pending/approved/rejected)

### Backend
- Update articles API endpoint to include new fields
- Add endpoints for approve/reject actions

### Frontend
- Add indicator icon for articles with AI suggestions
- Add approve/reject buttons in article detail view

### Documentation
- Update API documentation with new fields and endpoints

### Acceptance Criteria
- API returns `ai_headline_suggestion` and `headline_approval_status` for each article
- New indicator appears on articles with pending suggestions
- Clicking approve saves status and removes indicator
- Clicking reject clears the suggestion
- Changes persist after page refresh
- API documentation reflects all new fields and endpoints