---
name: task-planner
description: >-
  Guidelines for transforming descriptive tasks into technical breakdowns with main tasks (product-focused, well-formatted JIRA tickets) and subtasks (implementation-focused, technical chunks).
  Scope: task generation, consolidation, FE/BE separation, point estimation (0.1-5 scale), acceptance criteria.
  Triggers: "task", "breakdown", "subtask", "main task", "ticket", "JIRA", "estimation", "point".
---

# Task Planner

## METHOD

### Phase 1: Clarification
Detect task type from user input:
- "Create task", "task", or "main task" → **Main Task Mode**
- "Breakdown", "subtask", or "breakdown of task" → **Subtask Mode**
- Default: "task" alone → **Main Task Mode**
- IF description missing OR ambiguous → Ask for clarification

### Phase 2: Planning
IF Main Task Mode → READ FILE: @references/main-task-structure.md → Generate ticket structure → Generate acceptance criteria → Ask user for format choice.
IF Subtask Mode → READ FILE: @references/subtask-guidelines.md → Generate subtasks → READ FILE: @references/estimation-rubric.md → Estimate points → READ FILE: @references/consolidation-rules.md → Validate.

### Phase 3: Execution
#### Main Task Workflow
1. Detect ticket type (User Story / Technical Ticket / Bug Report).
2. Generate well-formatted ticket structure.
3. Generate Gherkin scenarios (if applicable).
4. Ask user: Acceptance criteria format (Gherkin OR Checklist OR Custom).
5. Ask user: Resources section (auto-fill codebase search OR manual).
6. Output final main task.

#### Subtask Workflow
1. Generate subtasks with title and description (technical, granular).
2. Estimate points (0.1-5 scale: Complexity + Effort + Uncertainty).
3. Validate consolidation/breakdown (target ≤3 points).
4. READ FILE: @references/fe-be-separation.md → Separate FE/BE.
5. Output subtask list (format: **Title** [X points] - Description).

### Phase 4: Validation
Verify: Main tasks contain required sections (Title, Overview, Description, Acceptance Criteria, Technical Brief, Resources).
Verify: Subtasks ≤3 points (rarely 5).
Verify: FE/BE separation applied.
Verify: Point estimates follow rubric.

## EXAMPLES

### Example 1: Create main task
User: "Create main task for daily data export cron job"
Agent: Generates well-formatted JIRA ticket with:
- Title: "Implement cron script for daily data export"
- Overview: User story format
- Description: Requirements, scope, constraints
- Technical Brief: Executive Summary, Impacted Areas, Risks
- Acceptance Criteria: Gherkin scenarios (pending user confirmation)
- Resources: Ask user (auto-fill OR manual)

### Example 2: Break down task
User: "Break down cron export task into subtasks"
Agent: Generates subtasks:
## Backend
- **Add export jobs table** [1 point]
  - Add `export_jobs` table with columns: id, user_id, status, file_path, created_at
- **Create export trigger endpoint** [1 point]
  - Implement POST /api/exports/trigger endpoint with user permission validation

## Frontend
- **Create export status page** [1 point]
  - Create page component with export history table and pagination
- **Add export trigger button** [0.5 points]
  - Add button to manually trigger export with loading state

## CONSTRAINTS

1. Main tasks: Well-formatted JIRA tickets with required sections.
2. Subtasks: Technical, granular, ≤3 points, with title and description for every subtask.
3. Point scale: 0.1, 0.5, 1, 2, 3, 4, 5 (1 point = 1 day).
4. FE/BE: Always separate frontend and backend subtasks (NEVER share).
5. Consolidation: Merge related work to avoid excessive granularity.
6. Validation: Check subtask points → consolidate IF >3 OR split IF <0.1.
