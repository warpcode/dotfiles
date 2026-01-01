# OUTPUT FORMAT: COMMON STRUCTURES

## PURPOSE
Define universal output format structures applicable across all modes.

## CORE PRINCIPLES

### 1. Purpose-Driven Formats
- Each operational mode serves distinct purpose
- Design output structure to match mode intent
- Enforce mode-specific constraints

### 2. Consistency
- Same domain → Similar output structure
- Same mode → Similar schema across domains
- Headers, subsections, formatting conventions

### 3. Informative Density
- Maximize information per token
- STM format (Structured Telegraphic Markdown)
- Avoid conversational filler

### 4. Mode-Specific Constraints
- Define what MUST and MUST NOT be included
- Validate against mode requirements
- Ensure output fulfills mode purpose

## UNIVERSAL STRUCTURE PATTERNS

### Header Hierarchy
```markdown
## Main Topic (H2)
### Subsection (H3)
#### Detail (H4)
```

### Code Blocks
```language
code here
```
- Always annotate with language
- Use for code, configs, examples

### Lists
```markdown
- Item 1
- Item 2
  - Nested item
  - Another nested item
```

### Tables
```markdown
| Column 1 | Column 2 | Column 3 |
|-----------|-----------|-----------|
| Data 1    | Data 2    | Data 3    |
```

## MODE-SPECIFIC OUTPUT STRUCTURES

### Analyse Mode Structure
```markdown
## [Analysis Topic]

### Section 1
- [Item 1]
- [Item 2]

### Section 2
[code snippet]

[Optional: Next Steps / Recommendations]
```

### Write Mode Structure
```markdown
**Summary**: [Action taken] - [Files affected]

**Changes**:
- `[file:line]`: [Change description]

**Example Change**:
```language
Before: [code]
After: [code]
```

**Validation**: [Checklist passed]
```

### Review Mode Structure
```markdown
**Summary**: [PASS/FAIL/PARTIAL] - [Overall assessment]

### Critical Issues: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

### High Priority: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

### Medium Priority: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

### Low Priority: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

**Recommendations**: [Descriptive corrections only, NO implementations]
```

### Plan Mode Structure
```markdown
## [Plan/Design Topic]

**Summary**: [Brief overview]

**Objectives**:
- [Objective 1]
- [Objective 2]

**Plan Structure**:
1. [Phase 1] ([Point estimate if applicable])
   - **Objective**: [Goal]
   - **Requirements**: [What's needed]
   - **Dependencies**: [What this depends on]
   - **Risks**: [Potential issues]
   - [Subtasks if applicable]

**Resources Required**:
- [Resource 1]
- [Resource 2]

**Success Criteria**:
- [Criterion 1]
- [Criterion 2]
```

### Teach Mode Structure
```markdown
## [Topic/Concept]

### Purpose
[One-sentence description of what this achieves]

### What It Means
[Explanation of concept in clear terms]

### When to Use
- [Scenario 1]
- [Scenario 2]

### Implementation
[code example]

### Benefits
- [Benefit 1]
- [Benefit 2]

### Anti-Patterns
❌ **Bad Practice**: [Example of what NOT to do]
✓ **Good Practice**: [Example of correct approach]
```

## VALIDATION CHECKLIST (All Modes)
- [ ] Structure matches template
- [ ] No conversational filler
- [ ] STM format applied (keywords + logic)
- [ ] Headers properly formatted
- [ ] Code blocks annotated with language
- [ ] Mode(s) clearly identified
- [ ] Multi-mode sections properly separated
