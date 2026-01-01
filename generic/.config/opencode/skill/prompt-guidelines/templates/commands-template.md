---
description: >-
  [One-line purpose]
  Scope: [areas covered]
---

# COMMAND_NAME

## EXECUTION PROTOCOL

### Phase 1: Clarification [MANDATORY]
- **Rule**: Multiple logic chains supported. Each on new line.
- **Logic**:
  Check overall context ambiguity
    Validate arguments provided
    Validate command dependencies
    Validate permissions

  IF arguments ambiguous THEN
    List required arguments
    Wait(User_Input)
  END

  IF dependencies missing THEN
    List required tools/commands
    Wait(User_Input)
  END

  IF all validations pass
    Proceed to Phase 2

### Phase 2: Planning [MANDATORY]
- **Rule**: Multiple logic chains supported. Each on new line.
- **Logic**:
  Analyze command requirements
    Identify execution steps
    Map dependencies
    Assess impacts

  IF impact > Low THEN
    Propose plan (Steps + Bash Commands + Impacts)
    Wait(User_Confirm)
  ELSE
    Execute plan directly
  END

### Phase 3: Execution [MANDATORY]
- **Rule**: Multiple logic chains supported. Each on new line.
- **Logic**:
  For each step
    Execute bash command
    Validate result

    IF result fails THEN
      Identify failure point
      Apply error handling
      Retry with fallback
    END

### Phase 4: Validation [MANDATORY]
- **Rule**: Multiple logic chains supported. Each on new line.
- **Logic**:
  Run final checklist
    Verify command executed successfully
    Verify output matches expected format
    Verify no side effects

  IF checklist fails THEN
    Identify failed checks
    Apply corrections
    Re-run checklist
  END

  IF checklist passes
    Complete command execution

## USER INPUT [MANDATORY]
**Default**: [Default behaviour. Remove if not set]
**Input**: $ARGUMENTS

## EXECUTION STEPS [MANDATORY]

### Execution Pattern
Execute bash commands step by step

IF step fails THEN
  Identify failure point
  Apply error handling
  Retry with fallback
  Abort if cannot recover
END

### Conditional Execution

IF environment variable set THEN
  Use variable value
  Apply environment-specific logic
ELSE
  Use default value
  Apply default logic
END

### Multi-Step Execution

Execute step 1
  Validate result
  IF result invalid THEN
    Apply fix
    Re-validate
  END

Execute step 2
  Validate result
  IF result invalid THEN
    Apply fix
    Re-validate
  END

Continue until all steps complete

### Error Handling

IF command fails THEN
  Check exit code
  Display meaningful error
  Suggest resolution
  Exit with error code
END

## THREAT MODEL [OPTIONAL]

### Input Validation
Input -> Sanitize() -> Validate(Safe) -> Execute

IF input contains shell metacharacters THEN
  Sanitize input
  Validate schema
  Reject if validation fails
END

IF path traversal detected THEN
  Reject absolute paths
  Validate against whitelist
  Error if path invalid
END

### Destructive Operations

IF destructive operation requested THEN
  Require User_Confirm
  Display operation details
  Display impact assessment
  Wait(User_Confirm)
END

IF operation is rm OR sudo OR chmod 777 THEN
  Require User_Confirm
  Display warning message
  Wait(User_Confirm)
END

## DEPENDENCIES [OPTIONAL]

### External Tools
- tool1: [version/purpose]
- tool2: [version/purpose]

### Skills
- skill(skill-id): [purpose]

### Dependency Validation

IF tool required THEN
  Check tool availability
  Validate tool version
  Error if tool not installed
END

IF skill required THEN
  Load skill(skill-id)
  Verify skill availability
  Error if skill not found
END

IF dependency missing THEN
  Error(Dependency not available)
  List missing dependency
  Abort command execution
END

## GLOSSARY [RECOMMENDED when abbreviations exist]

**TERM1**: [Definition]
**TERM2**: [Definition]
