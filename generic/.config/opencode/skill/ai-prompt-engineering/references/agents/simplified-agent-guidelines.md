# Simplified Agent Guidelines

## Overview

Simplified agents handle focused, narrow-domain expertise where rapid context switching and lightweight specifications are important. These agents typically span 30-50 lines and include only 3-4 required sections. They are used for language experts, framework specialists, and other focused technical roles.

## Required Sections (in order)

### 1. YAML Frontmatter
```yaml
---
name: [agent-name]
description: [150-300 chars following 4-part structure]
model: [inherit|sonnet]
---
```

**Guidelines:**
- `name`: kebab-case, lowercase
- `description`: Expert [role] specializing in [domains]. Masters [skills]. Handles [tasks]. Use PROACTIVELY for [use cases].
- `model`: `inherit` for language/framework experts, `sonnet` for other focused roles

### 2. Opening Statement
```
You are a [role] specializing in [domain].
```
**Single sentence, present tense, identity-establishing.**

### 3. Focus Areas (4-7 bullet points)
- Replaces Purpose + Capabilities sections
- Concise, action-oriented noun phrases
- Covers key specialization areas

### 4. Approach (3-6 numbered principles)
- Replaces Behavioral Traits + Response Approach
- Numbered list of workflow steps
- Action-oriented, principle-based

### 5. Output (3-6 deliverables)
- Bullet list of what the agent produces
- Replaces Output Examples
- Specific, tangible deliverables

## Optional Sections

### Closing Statement (1-2 sentences)
- Final guidance or tool recommendations
- Present in ~30% of simplified agents

## Prohibited Sections

The following sections are never used in simplified agents:
- ❌ Purpose (use Focus Areas instead)
- ❌ Capabilities (too detailed)
- ❌ Behavioral Traits (implied in Approach)
- ❌ Knowledge Base
- ❌ Response Approach (use Approach instead)
- ❌ Workflow Position
- ❌ Key Distinctions
- ❌ Output Examples (use Output instead)
- ❌ Core Philosophy

## Section Ordering Rules

Sections must follow this strict order:

1. YAML Frontmatter
2. Opening Statement
3. Focus Areas
4. Approach
5. Output (and optional Closing)

## Content Guidelines by Section

### Focus Areas Structure
```
- [Area 1 noun phrase]
- [Area 2 noun phrase]
- [Area 3 noun phrase]
...
```

**Examples:**
- Modern Python 3.8+ features and type hints
- Asynchronous programming with asyncio
- Data science with pandas, numpy, and scikit-learn

### Approach Structure
```
1. [Principle 1]
2. [Principle 2]
3. [Principle 3]
...
```

**Examples:**
1. Use type hints and modern Python idioms
2. Implement comprehensive testing with pytest
3. Optimize for performance and memory usage

### Output Structure
```
- [Deliverable 1]
- [Deliverable 2]
- [Deliverable 3]
...
```

**Examples:**
- Production-ready Python code with type hints
- Comprehensive test suite with pytest
- Performance profiling reports

## Quality Validation Checklist

### Frontmatter Validation
- [ ] `name` is kebab-case
- [ ] `description` is 150-300 characters
- [ ] `description` follows 4-part structure
- [ ] `model` is `inherit` or `sonnet`

### Content Validation
- [ ] Focus areas has 4-7 items
- [ ] Approach has 3-6 principles
- [ ] Output has 3-6 deliverables
- [ ] No prohibited sections present
- [ ] Total length is 30-50 lines

### Style Validation
- [ ] Tone is authoritative and instructional
- [ ] Sections follow strict ordering
- [ ] No complex sections included

## Common Patterns by Domain

### Language Experts
**Pattern:** Simplified (typically)
**Structure:**
- Focus Areas: Modern features, async, testing, performance, deployment
- Approach: Idioms, testing, optimization, documentation
- Output: Production code, tests, profiling, Docker config

### Framework Specialists
**Pattern:** Simplified (typically)
**Structure:**
- Focus Areas: Core concepts, advanced patterns, integration, optimization
- Approach: Best practices, patterns, testing, performance
- Output: Framework code, tests, documentation, configurations

### Domain Specialists
**Pattern:** Simplified when focused
**Structure:**
- Focus Areas: Core domain concepts, tools, methodologies
- Approach: Systematic application, validation, optimization
- Output: Domain artifacts, analyses, recommendations

## Success Criteria

A simplified agent is successful when:
- Follows Simplified Pattern (30-50 lines)
- Includes all required sections (3-4 sections)
- Focus areas are specific and actionable (4-7 items)
- Approach provides clear principles (3-6 items)
- Output defines tangible deliverables (3-6 items)
- No prohibited sections are present
- Total length stays within 30-50 lines
- Clearly defines narrow domain scope
- Passes all quality validation checks

## Common Pitfalls

- **Over-Complexification**: Avoid adding detailed sections
- **Insufficient Focus**: Ensure areas are truly focused
- **Weak Approach**: Make principles actionable and specific
- **Scope Creep**: Keep within narrow domain boundaries
- **Length Issues**: Stay under 50 lines total
