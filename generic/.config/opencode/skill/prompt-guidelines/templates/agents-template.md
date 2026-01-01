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
  [One-line purpose]
  Scope: [key areas]
---

# AGENT_NAME

## ROUTING_PROTOCOL

### Mode Detection
IF "analyze" OR "explain" OR "show" detected THEN
  READ FILE: @references/modes/analyse.md
END

IF "create" OR "write" OR "edit" OR "update" detected THEN
  READ FILE: @references/modes/write.md
END

IF "review" OR "check" OR "audit" OR "validate" OR "compliance" detected THEN
  READ FILE: @references/modes/review.md
END

IF "plan" OR "design" OR "breakdown" OR "estimate" detected THEN
  READ FILE: @references/modes/plan.md
END

IF "teach" OR "explain" OR "guide" OR "tutorial" detected THEN
  READ FILE: @references/modes/teach.md
END

### Domain-Specific Routing
IF [domain keyword 1] detected THEN
  READ FILE: @references/domains/[domain1].md
END

### Security Context
IF destructive OR "sudo" OR "rm" OR "security" detected THEN
  READ FILE: @references/core/security.md
  READ FILE: @references/core/validation.md
END

## IDENTITY [MANDATORY]
**Role**: [Agent role]
**Goal**: [Agent goal]

## CAPABILITIES [OPTIONAL]
✓ CAN: [Capability 1, Capability 2]
✗ CANNOT: [Limitation 1, Limitation 2]

## DEPENDENCIES [OPTIONAL]

### Skills
- skill(skill-id): [purpose]

### Tools
- tool-name: [purpose]

### Dependency Validation

IF skill required THEN
  Load skill(skill-id)
  Verify skill availability
  Error if skill not found
END

IF tool required THEN
  Check tool availability
  Verify tool version
  Warn if version mismatch
END

IF dependency missing THEN
  Error(Dependency not available)
  List missing dependency
  Abort operation
END

## GLOSSARY [RECOMMENDED when abbreviations exist]

**TERM1**: [Definition]
**TERM2**: [Definition]
