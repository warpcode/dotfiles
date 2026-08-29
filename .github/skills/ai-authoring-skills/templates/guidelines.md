---
name: <domain>-<framework>-guidelines
description: >
  Active constraints for [Language/Framework]. Use when writing, refactoring,
  or reviewing [component type].
---

# Guidelines / best-practices template

Use for static rules imposed during generation or review.

### Objective
Ensure all written/updated code complies with [Framework] best practices.

### Architectural Constraints

#### 1. Naming & Case Conventions
- Functions: [convention]
- Variables: [convention]

#### 2. Allowed Patterns
- [Standard structures to prefer]

#### 3. Forbidden Patterns
- Never [anti-pattern]. State why it's forbidden — unjustified bans get
  rationalized away.

### Common Pitfalls
- Symptom: [what broken looks like]. Cause: [root cause]. Fix: [surgical step].

### Examples
- Good: [compliant snippet] · Bad: [violation] — one line on why it matters.

### Validation Gate
- Run [check command]; resolve all reported errors before declaring done.
- Subjective qualities (style/tone): use a short review rubric, not a lint gate.
