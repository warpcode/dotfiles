# OUTPUT FORMAT: JIRA STRUCTURE

## PURPOSE
Define structured output format for JIRA ticket creation in Plan/Design mode.

## WHEN TO USE
- JIRA ticket creation
- Task breakdown and estimation
- Point estimation required
- Complex task planning
- Team coordination

## OUTPUT FORMAT

```markdown
## [Ticket Title]

**Summary**: [Brief overview of ticket purpose]

**Objectives**:
- [Objective 1]
- [Objective 2]
- [Objective 3]

## [Category] Subtasks

### 1. [Subtask Title] [Point Estimate]
- **Objective**: [Specific goal of this subtask]
- **Requirements**: [What's needed to complete]
- **Dependencies**: [What this depends on]
- **Risks**: [Potential issues or blockers]
- **Acceptance Criteria**:
  - [ ] [Criteria 1]
  - [ ] [Criteria 2]

### 2. [Subtask Title] [Point Estimate]
- **Objective**: [Specific goal of this subtask]
- **Requirements**: [What's needed to complete]
- **Dependencies**: [What this depends on]
- **Risks**: [Potential issues or blockers]
- **Acceptance Criteria**:
  - [ ] [Criteria 1]
  - [ ] [Criteria 2]

## Resources Required
- [Resource 1]
- [Resource 2]

## Dependencies
- [External dependency 1]
- [External dependency 2]

## Success Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Implementation Notes
[Optional: Technical details, considerations, edge cases]

## Testing Strategy
- [Unit tests]: [What needs testing]
- [Integration tests]: [How to verify integration]
- [Acceptance testing]: [How to validate success criteria]
```

## REQUIREMENTS

### Mandatory Fields
- **Ticket Title**: Clear, concise description
- **Summary**: Brief overview (1-2 sentences)
- **Objectives**: What the ticket achieves
- **Subtasks**: Breakdown of work with point estimates
- **Success Criteria**: Measurable completion criteria

### Recommended Fields
- **Resources Required**: People, tools, systems needed
- **Dependencies**: External blockers, prerequisites
- **Implementation Notes**: Technical considerations
- **Testing Strategy**: How to verify implementation

### Optional Fields
- **Risk Assessment**: Potential blockers
- **Timeline**: Estimated completion date
- **Stakeholders**: Who needs to be involved

## POINT ESTIMATION GUIDELINES

### Fibonacci Scale (Common)
- 1: Trivial (minutes)
- 2: Small (1-2 hours)
- 3: Medium (half-day)
- 5: Large (full day)
- 8: Extra Large (2-3 days)
- 13: Very Large (3-5 days)
- 21: Epic (1-2 weeks)

### Estimation Principles
- **Relative Size**: Compare to previous work, not absolute time
- **Complexity**: Consider technical difficulty, not just hours
- **Uncertainty**: Account for unknowns, research needed
- **Break Down**: If > 13 points, break into smaller tickets
- **Consensus**: Team agreement preferred

### When NOT to Include Points
- Pure research/exploration tasks
- Undefined requirements
- Spikes (investigation tasks)
- Administrative tasks

## SUBTASK BREAKDOWN GUIDELINES

### Break Down When
- Subtask > 8 points (too large)
- Multiple concerns in one subtask
- Can be done independently
- Different skill sets required

### Subtask Naming
- **Action-Oriented**: "Implement login form" (not "Login form")
- **Specific**: "Add password validation to registration" (not "Registration")
- **Measurable**: "Create 5 unit tests for user model" (not "Tests")

### Acceptance Criteria
- **Specific**: Clear, testable condition
- **Measurable**: Can be verified as done/not done
- **Achievable**: Realistic within estimate
- **Relevant**: Contributes to ticket objectives
- **Time-Bound**: Can be completed in reasonable time

### Example Acceptance Criteria
- [ ] User can register with email and password
- [ ] Password must be at least 8 characters
- [ ] Password must contain one uppercase letter
- [ ] Validation error displayed for invalid inputs
- [ ] Success email sent after registration

## VALIDATION CHECKLIST
- [ ] Title is clear and concise
- [ ] Summary provides good overview
- [ ] Objectives are specific and achievable
- [ ] Subtasks have reasonable point estimates
- [ ] Each subtask has acceptance criteria
- [ ] Dependencies are identified
- [ ] Success criteria are measurable
- [ ] Resources are listed if applicable
- [ ] Testing strategy is defined
- [ ] No implementation details included (this is PLAN mode)
