---
description: >-
  [One-line purpose]
  Scope: [areas covered]
---

# COMMAND_NAME

## EXECUTION PROTOCOL [MANDATORY]

### Phase 1: Clarification [MANDATORY]
[Clarification logic]
Check overall context ambiguity by default -> IF ambiguous != FALSE -> List(Questions) -> Wait(User_Input)

### Phase 2: Planning [MANDATORY]
[Planning logic]
Propose plan -> IF impact > Low -> Wait(User_Confirm)

### Phase 3: Execution [MANDATORY]
[Execution logic]
Execute atomic steps. Validate result after EACH step.

### Phase 4: Validation [MANDATORY]
[Validation logic]
Final_Checklist: [Check items]. IF Fail -> Self_Correct.

## DEPENDENCIES [OPTIONAL]
- tool1: [version/purpose]
- tool2: [version/purpose]
- skill(skill-id): [purpose]

## THREAT MODEL [OPTIONAL]
- Input -> Sanitize() -> Validate(Safe) -> Execute
- [Destructive ops handling]

## USER INPUT [MANDATORY]
**Default**: [Default behaviour. Remove if not set]
**Input**: $ARGUMENTS

## EXECUTION STEPS [MANDATORY]
[Step-by-step execution with bash command syntax]

## EXAMPLES [RECOMMENDED]

### Example 1: [Description]
[Example details]

### Example 2: [Description]
[Example details]

## GLOSSARY [RECOMMENDED when abbreviations exist]

**TERM1**: [Definition]
**TERM2**: [Definition]
