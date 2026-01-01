# EXECUTION PROTOCOL

## PURPOSE
Define mandatory 4-phase execution structure for all components.

## PHASE 1: CLARIFICATION (Ask)
- **Logic**: Ambiguity > 0 -> Stop && Ask.
- **Instruction**:
  ```
  Check task completeness
    Validate requirements
    Validate context
    Validate constraints

  IF requirements != complete THEN
    List missing requirements
    Wait(User_Input)
  END

  IF context ambiguous THEN
    Clarify platform, framework, environment
    Wait(User_Input)
  END

  IF all validations pass
    Proceed to Phase 2
  ```

## PHASE 2: PLANNING (Think)
- **Logic**: Task -> Plan -> Approval.
- **Instruction**:
  ```
  Analyze task
    Identify steps needed
    Map dependencies
    Assess impacts

  IF impact > Low THEN
    Propose plan (Steps + Files + Impacts)
    Wait(User_Confirm)
  ELSE
    Execute plan directly
  END

  IF complex task
    Break down into subtasks
  ```

## PHASE 3: EXECUTION (Do)
- **Logic**: Step_1 -> Verify -> Step_2.
- **Instruction**:
  ```
  For each step
    Execute action
    Validate result

    IF validation fails THEN
      Identify failure point
      Apply fix strategy
      Re-validate
    END
  ```

## PHASE 4: VALIDATION (Check)
- **Logic**: Result -> Checklist -> Done.
- **Instruction**:
  ```
  Run final checklist
    Verify requirements met
    Verify quality standards
    Verify safety checks

  IF checklist fails THEN
    Identify failed checks
    Apply corrections
    Re-run checklist
  END

  IF checklist passes
    Complete task
  ```

## LOGIC CHAIN RULES (CRITICAL)
- **Multi-Line Support**: Each phase can contain multiple logic chains
- **Line Separation**: Each logic chain MUST be on its own line
- **IF Blocks**:
  - IF/ELSE/ELSE IF blocks MUST use END marker
  - Multiple logic chains within IF block - each on new line, indented
  - Nested IF blocks supported (END markers for each)
- **No Single-Line Constraint**: Phases are NOT limited to one logic chain
