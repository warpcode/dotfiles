---
mode: all
temperature: 0.2
tools:
  read: true
  glob: true
  grep: true
  context7: true
permission: {}
description: >
  Authoritative template for all agent.md files.
  Use this as reference when creating or standardising agents.
  Do not use this file as an actual agent.
---

# AGENT_NAME

## IDENTITY [MANDATORY]
**Role**: [Agent role]
**Goal**: [Agent goal]

## CAPABILITIES [OPTIONAL]
✓ CAN: [Capability 1, Capability 2]
✗ CANNOT: [Limitation 1, Limitation 2]

## DEPENDENCIES [OPTIONAL]
- skill(skill-id): [purpose]
- tool-name: [purpose]

## METHOD [MANDATORY]

### Phase 1: Clarification [MANDATORY]
[Clarification logic]
IF requirements != complete -> List(Questions) -> Wait(User_Input)

### Phase 2: Planning [MANDATORY]
[Planning logic with <thinking> tag usage]
Propose plan -> IF impact > Low -> Wait(User_Confirm)

### Phase 3: Execution [MANDATORY]
[Execution logic]
Execute atomic steps. Validate result after EACH step.

### Phase 4: Validation [MANDATORY]
[Validation logic]
Final_Checklist: [Check items]. IF Fail -> Self_Correct.

## COGNITIVE PROCESS [OPTIONAL]

### Chain of Thought
[CoT rules]

### The Critic
[Critic role rules]

### Variable Binding
[Output mode and constraints]

## SECURITY & VALIDATION [OPTIONAL]

### Threat Model
[Threat model rules]

### Validation Layers
[Validation layers 1-4]

### Threat Controls
[Control rules]

## OUTPUT FORMAT [OPTIONAL]
[Output format rules]

## CONSTRAINTS [OPTIONAL]
1. [Constraint 1]
2. [Constraint 2]

## EXAMPLES [RECOMMENDED]

### Example 1: [Description]
[Example details]

### Example 2: [Description]
[Example details]

## GLOSSARY [RECOMMENDED when abbreviations exist]

**TERM1**: [Definition]
**TERM2**: [Definition]
