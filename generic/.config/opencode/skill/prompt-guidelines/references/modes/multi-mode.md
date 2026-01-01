# MULTI-MODE HANDLING

## PURPOSE
Define how to combine multiple operational modes coherently.

## PRINCIPLES
- Prompts can activate multiple modes simultaneously
- Design outputs to combine modes coherently
- Maintain clarity when presenting multi-mode outputs
- Order modes logically (e.g., Analyse → Review → Plan → Write)

## COMMON PATTERNS

### Pattern 1: Analyse → Review → Plan
**Use Case**: Comprehensive analysis with recommendations
```markdown
## Analysis (Analyse Mode)
[Analysis findings...]

## Review (Review Mode)
**Summary**: PARTIAL - Issues found
[Issues with severity...]

## Plan (Plan Mode)
**Recommendation Plan**:
1. Fix Critical Issues [2 days]
2. Address High Priority [1 week]
3. Implement Improvements [2 weeks]
```

### Pattern 2: Analyse → Write
**Use Case**: Analysis followed by implementation
```markdown
## Analysis (Analyse Mode)
[Current state analysis...]

## Changes (Write Mode)
**Summary**: Implemented fixes based on analysis
[Change details...]
```

### Pattern 3: Teach → Analyse
**Use Case**: Educational explanation with analysis
```markdown
## Concept Overview (Teach Mode)
[Educational content...]

## Code Analysis (Analyse Mode)
[Code-specific analysis applying concepts...]
```

### Pattern 4: Review → Write
**Use Case**: Review findings then implement fixes
```markdown
## Review (Review Mode)
**Summary**: FAIL - Critical issues found
[Issues with severity...]
**Recommendations**: [Descriptive corrections...]

## Changes (Write Mode)
**Summary**: Implemented recommended fixes
[Change details...]
```

## GUIDELINES FOR MULTI-MODE OUTPUTS

### Structure
- Clearly separate each mode with headers
- Use consistent mode labels in headers
- Ensure transitions between modes are logical
- Avoid redundancy across modes
- Each mode section should stand alone

### Mode-Specific Integrity
- **Analyse**: Read-only, information extraction, no modifications
- **Write**: Changes, confirmations, before/after comparisons
- **Review**: Severity hierarchy, descriptive recommendations only
- **Plan**: Objectives, dependencies, risks, no implementation details
- **Teach**: Rationale, examples, anti-patterns, WHY not just WHAT/HOW

### Transitions
- Provide bridge sentences between modes
- Explain why next mode is relevant
- Reference findings from previous modes
- Maintain narrative flow

### Validation
- Each mode section follows its specific requirements
- Mode constraints respected in each section
- Transitions are logical and clear
- No redundant information across modes
