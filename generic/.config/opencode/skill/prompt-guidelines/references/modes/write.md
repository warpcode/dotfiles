# MODE: WRITE/EDIT/UPDATE

## PURPOSE
Confirm creation/modification with clear change summary. Focus on change visibility and confirmation.

## WHEN TO USE
- Create new files or content
- Edit existing files
- Generate code, documentation, configurations
- Implement features or bug fixes

## PERMISSIONS
- Write/edit tools allowed
- User confirmation required for destructive operations
- Execute atomic steps with validation

## BEHAVIORAL INTEGRATION

### Cognitive Process (Generative)
- **Mental Model**: What needs to exist? How do I create it?
- **Approach**: Problem decomposition, synthesis, refinement
- **Thought Process**: Understand requirement → Design solution → Generate → Validate → Refine

### Workflow Structure (Iterative)
```
Requirement → Design → Generate → Validate → Refine → Finalize
```
- Multiple refinement cycles
- Self-correction during generation
- Validation: Functionality, correctness, style

### Validation Framework (Functional)
- **Correctness**: Does it solve the problem?
- **Style**: Does it follow conventions?
- **Integration**: Does it integrate with existing code?
- **Testing**: Does it pass tests?

### Interaction Patterns (Confirmatory)
- **Style**: Multi-step with confirmations
- **User Provides**: Requirements
- **LLM Provides**: Proposed changes → User confirms → Execute
- **User Confirmation Required**: For destructive operations

### Success Criteria (Functional Implementation)
- Requirement is fulfilled (code works, solves the problem)
- Changes are documented
- No unintended side effects
- Integration is clean

### Context Handling (Integration)
- Read existing code, integrate changes
- Load patterns, best practices before writing
- Progressive Disclosure: Load references as needed

## OUTPUT FORMAT

```markdown
**Summary**: [Action taken] - [Files affected]

**Changes**:
- `[file:line]`: [Change description]
- `[file:line]`: [Change description]

**Example Change**:
```language
Before:
[original code]

After:
[modified code]
```

**Validation**: [Checklist passed]
```

### Requirements
- Show all files modified
- Before/after comparison for significant changes
- Line number references
- User confirmation for destructive operations
- Execute steps atomically

### Validation
- All changes documented
- Line references accurate
- User confirmed (if destructive)
- No unintended modifications
