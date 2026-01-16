# Comprehensive Agent Guidelines

## Overview

Comprehensive agents handle complex, multi-domain expertise requiring deep architectural knowledge and extensive technical detail. These agents typically span 150-280+ lines and include 8-12 required sections. They are used for complex architectural, operational, and design roles.

## Required Sections (in order)

### 1. YAML Frontmatter
```yaml
---
name: [agent-name]
description: [150-300 chars following 4-part structure]
model: [opus|sonnet]
---
```

**Guidelines:**
- `name`: kebab-case, lowercase
- `description`: Expert [role] specializing in [domains]. Masters [skills]. Handles [tasks]. Use [PROACTIVELY/IMMEDIATELY] for [use cases].
- `model`: `opus` for complex architectural work, `sonnet` for moderate complexity

### 2. Opening Statement
```
You are a [role] specializing in [domain].
```
**Single sentence, present tense, identity-establishing.**

### 3. Purpose (2-3 sentences)
Expert [domain] with comprehensive knowledge of [areas]. Masters [skills] and [capabilities]. Specializes in [focus] that are [qualities].

### 4. Core Philosophy (optional, 1-2 sentences)
Articulate guiding principles and design philosophy.

### 5. Capabilities (8-15 categories, 40-80 subcategories)
```
## Capabilities

### [Category 1]
- **[Subcategory 1]**: [item1], [item2], [item3], [item4]
- **[Subcategory 2]**: [item1], [item2], [item3]
...
```

**Requirements:**
- 8-15 top-level categories
- 3-8 subcategories per category
- 3-7 items per subcategory (comma-separated, Oxford comma)
- Format: `**[Bold Subcategory]**: [items]`

### 6. Behavioral Traits (8-12 items)
- Third-person present tense
- Starts with action verbs (Prioritizes, Implements, Follows)
- Prescriptive guidelines for agent behavior

### 7. Workflow Position (optional)
- **Before**: [agents this precedes]
- **Complements**: [agents this works with]
- **Enables**: [work this enables]

### 8. Knowledge Base (6-12 broad domains)
Bullet list of noun phrases summarizing expertise areas.

### 9. Response Approach (6-10 numbered phases)
```
1. **[Phase 1]**: [Action description]
2. **[Phase 2]**: [Action description]
...
```
Imperative mood, logical workflow progression.

### 10. Example Interactions (8-15 quoted prompts)
Cover all major capability areas with representative user interactions.

### 11. Output Examples (optional, 8-15 deliverables)
Specify artifacts the agent produces.

### 12. Key Distinctions (optional, 2-5 comparisons)
Clarify scope vs similar agents:
- **vs [agent]**: [distinction]

## Section Ordering Rules

Sections must follow this strict order:

1. YAML Frontmatter
2. Opening Statement
3. Purpose
4. Core Philosophy (if present)
5. Capabilities
6. Behavioral Traits
7. Workflow Position (if present)
8. Knowledge Base
9. Response Approach
10. Example Interactions
11. Output Examples (if present)
12. Key Distinctions (if present)

## Content Guidelines by Section

### Purpose Section Structure
```
Sentence 1: Expertise statement ("Expert [role] with comprehensive knowledge of [domains]")
Sentence 2: Mastery statement ("Masters [skills]")
Sentence 3: Specialization statement ("Specializes in [focus] that are [qualities]")
```

### Capabilities Section Categories
Common patterns include:
- Core Technology Expertise
- Architecture Patterns
- Design Patterns
- Security & Compliance
- Performance Optimization
- Testing & Quality Assurance
- DevOps & Deployment
- Monitoring & Observability

### Behavioral Traits Patterns
| Category | Verbs | Examples |
|----------|--------|----------|
| Quality | Prioritizes, Emphasizes | Prioritizes code quality |
| Implementation | Implements, Uses | Implements security controls |
| Best Practices | Follows, Adheres | Follows industry standards |
| User Focus | Considers, Designs for | Considers accessibility |
| Pragmatism | Values, Balances | Values simplicity over complexity |

### Response Approach Phases
Typical workflow:
1. Analysis/Understanding phase
2. Design/Planning phases
3. Implementation phases
4. Testing/Validation phases
5. Documentation phase

## Quality Validation Checklist

### Frontmatter Validation
- [ ] `name` is kebab-case
- [ ] `description` is 150-300 characters
- [ ] `description` follows 4-part structure
- [ ] `model` is appropriate for complexity

### Content Validation
- [ ] Purpose has 2-3 sentences following pattern
- [ ] Capabilities has 8-15 categories
- [ ] Each category has 3-8 subcategories with 3-7 items
- [ ] Behavioral traits has 8-12 items (third-person present)
- [ ] Knowledge base has 6-12 items
- [ ] Response approach has 6-10 phases
- [ ] Example interactions has 8-15 items
- [ ] Sections follow standard ordering
- [ ] Total length is 150-280+ lines

## Common Pitfalls

- **Insufficient Detail**: Ensure 40-80 subcategories across categories
- **Weak Behavioral Traits**: Include 8-12 prescriptive traits
- **Poor Example Coverage**: Provide 8-15 diverse interactions
- **Scope Overlap**: Include Key Distinctions when needed
- **Section Ordering**: Follow strict ordering rules

## Success Criteria

A comprehensive agent is successful when:
- Follows Comprehensive Pattern (150-280+ lines)
- Includes all required sections in correct order
- Has 8-15 capability categories with 40-80 subcategories
- Behavioral traits use third-person present tense
- Response approach has 6-10 phases
- Example interactions cover major capability areas
- Passes all quality validation checks
- Clearly defines scope and boundaries
