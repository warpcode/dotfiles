# Specialized Agent Guidelines

## Overview

Specialized agents handle unique workflows, domain-specific formats, or non-standard operational requirements. These agents vary in length (70-250+ lines) and include domain-specific sections alongside standard components. They are used for incident response, documentation, content creation, and other specialized roles.

## Required Sections (in order)

### 1. YAML Frontmatter
```yaml
---
name: [agent-name]
description: [150-300 chars following 4-part structure]
model: [sonnet]
---
```

**Guidelines:**
- `name`: kebab-case, lowercase
- `description`: Expert [role] specializing in [domains]. Masters [skills]. Handles [tasks]. Use [IMMEDIATELY] for [use cases].
- `model`: Typically `sonnet`, sometimes `opus` for complex domains

### 2. Opening Statement
```
You are a [role] specializing in [domain].
```
**Single sentence, present tense, identity-establishing.**

### 3. Purpose (2-3 sentences)
Expert [domain] with comprehensive knowledge of [areas]. Masters [skills] and [capabilities]. Specializes in [focus] that are [qualities].

### 4. Domain-Specific Sections (variable)
Custom sections unique to the agent's domain and workflow requirements.

### 5. Behavioral Traits (8-12 items)
Third-person present tense, prescriptive guidelines.

### 6. Workflow Position (optional)
Dependencies and relationships with other agents.

### 7. Knowledge Base (6-12 broad domains)
Bullet list of expertise areas.

### 8. Response Approach (6-10 phases)
Numbered workflow phases.

### 9. Example Interactions (5-10 quoted prompts)
Representative user interactions.

### 10. Output Examples (optional)
Artifacts the agent produces.

### 11. Key Distinctions (optional)
Scope clarification vs similar agents.

## Domain-Specific Section Patterns

### Incident Response Agents
```
## Immediate Actions (First 5 minutes)

### 1. [Action Category]
- **[Sub-action]**: [Description]
- **[Sub-action]**: [Description]

## Modern Investigation Protocol
- **[Technique]**: [Description]

## Communication Strategy
### Internal Communication
- **[Method]**: [Description]

### External Communication
- **[Method]**: [Description]

## Resolution & Recovery
- **[Phase]**: [Description]

## Post-Incident Process
- **[Step]**: [Description]

## Modern Severity Classification
- **P0**: [Criteria]
- **P1**: [Criteria]
```

### Documentation Agents
```
## Documentation Process
1. **[Phase]**: [Description]
2. **[Phase]**: [Description]

## Documentation Template
When creating [document type], follow this structure:

```markdown
# [Document Title]

## [Section 1]
[Content structure]

## [Section 2]
[Content structure]
```
```

### Content Creation Agents
```
## Content Creation Framework

**Introduction (50-100 words):**
- [Requirement]
- [Requirement]

**Body Content:**
- [Requirement]
- [Requirement]

**Conclusion:**
- [Requirement]

## Quality Standards
- **[Standard]**: [Description]

## Output Characteristics
- **[Characteristic]**: [Description]
```

### C4 Architecture Agents
```
## Documentation Template
When creating C4 diagrams, provide:

```markdown
# [System Name] Architecture

## Context Diagram (C4 Level 1)
[Diagram description]

## Container Diagram (C4 Level 2)
[Diagram description]

## Component Diagram (C4 Level 3)
[Diagram description]
```

## Diagram Templates
### Context Diagram Template
```
[PlantUML/Mermaid template]
```

### Container Diagram Template
```
[PlantUML/Mermaid template]
```
```

## Section Ordering Rules

Sections follow this flexible order:

1. YAML Frontmatter
2. Opening Statement
3. Purpose
4. [Domain-specific sections] (variable placement)
5. Behavioral Traits
6. Workflow Position (if present)
7. Knowledge Base
8. Response Approach
9. Example Interactions
10. Output Examples (if present)
11. Key Distinctions (if present)

**Note:** Domain-specific sections (4) are flexible and agent-dependent.

## Content Guidelines by Section

### Purpose Section
Same structure as comprehensive agents:
- Sentence 1: Expertise
- Sentence 2: Mastery
- Sentence 3: Specialization

### Domain-Specific Sections
- Must enhance agent capabilities
- Should be relevant to domain requirements
- Can include templates, frameworks, or protocols
- Variable in number and structure

### Behavioral Traits
- 8-12 items
- Third-person present tense
- Domain-appropriate prescriptive guidelines

### Response Approach
- 6-10 phases
- Imperative mood
- Include domain-specific workflow steps

### Example Interactions
- 5-10 items (fewer than comprehensive)
- Cover domain-specific use cases
- Representative of specialized workflows

## Quality Validation Checklist

### Frontmatter Validation
- [ ] `name` is kebab-case
- [ ] `description` is 150-300 characters
- [ ] `description` follows 4-part structure
- [ ] `model` is appropriate (typically `sonnet`)

### Content Validation
- [ ] Purpose has 2-3 sentences
- [ ] Domain-specific sections appropriate for agent type
- [ ] Domain-specific sections enhance capabilities
- [ ] Behavioral traits has 8-12 items
- [ ] Knowledge base has 6-12 items
- [ ] Response approach has 6-10 phases
- [ ] Example interactions has 5-10 items
- [ ] Sections follow specialized ordering

### Domain-Specific Validation
- [ ] Domain sections are relevant to agent type
- [ ] Templates/frameworks are practical and usable
- [ ] Workflow protocols are clear and actionable
- [ ] Special requirements are properly addressed

## Success Criteria

A specialized agent is successful when:
- Follows Specialized Pattern (70-250+ lines)
- Includes domain-specific sections appropriate for type
- Domain-specific sections enhance agent capabilities
- Maintains consistency with universal components
- Has 5-10 example interactions covering domain use cases
- Behavioral traits use third-person present tense
- Response approach has 6-10 phases with domain integration
- Clearly defines agent's unique workflow/requirements
- Passes all quality validation checks

## Common Patterns and Templates

### Incident Response Template
- Immediate Actions (first 5 minutes)
- Investigation Protocol
- Communication Strategy
- Resolution & Recovery
- Post-Incident Process
- Severity Classification

### Documentation Template
- Documentation Process
- Documentation Template (structure)
- Content Guidelines
- Quality Standards

### Content Creation Template
- Content Creation Framework
- Quality Standards
- Output Characteristics
- Editorial Guidelines

### Architecture Template
- Documentation Template
- Diagram Templates
- Architectural Guidelines
- Decision Frameworks

## Common Pitfalls

- **Over-Generalization**: Ensure domain-specific sections are truly unique
- **Weak Domain Integration**: Domain sections must enhance, not just add bulk
- **Inconsistent Structure**: Maintain core agent structure alongside domain sections
- **Poor Template Quality**: Templates must be practical and immediately usable
- **Scope Confusion**: Clearly differentiate from comprehensive agents
