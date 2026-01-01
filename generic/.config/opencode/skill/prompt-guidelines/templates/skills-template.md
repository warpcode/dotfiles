---
name: skill-name
description: >-
  [One-line purpose]
  Scope: [key capabilities]
  Excludes: [exclusions - domain skills only]
  Triggers: [keywords for routing]
---

# SKILL_NAME

## ROUTING_PROTOCOL

### Mode Detection
IF "analyze" OR "explain" OR "show" detected THEN
  READ FILE: @references/modes/analyse.md
END

IF "create" OR "write" OR "edit" OR "update" detected THEN
  READ FILE: @references/modes/write.md
  READ FILE: @references/output/common.md
END

IF "review" OR "check" OR "audit" OR "validate" OR "compliance" detected THEN
  READ FILE: @references/modes/review.md
  READ FILE: @references/output/severity-classification.md
END

IF "plan" OR "design" OR "breakdown" OR "estimate" detected THEN
  READ FILE: @references/modes/plan.md
  READ FILE: @references/output/jira-structure.md
END

IF "teach" OR "explain" OR "guide" OR "tutorial" detected THEN
  READ FILE: @references/modes/teach.md
END

### Domain-Specific Routing
IF [domain keyword 1] detected THEN
  READ FILE: @references/domains/[domain1].md
END

IF [domain keyword 2] detected THEN
  READ FILE: @references/domains/[domain2].md
END

### Context-Aware Routing
IF framework/language detected THEN
  READ FILE: @references/contexts/[framework].md
END

### Security Context
IF destructive OR "sudo" OR "rm" OR "security" OR "validation" detected THEN
  READ FILE: @references/core/security.md
  READ FILE: @references/core/validation.md
END

## GLOSSARY [RECOMMENDED when abbreviations exist]

**TERM1**: [Definition]
**TERM2**: [Definition]
