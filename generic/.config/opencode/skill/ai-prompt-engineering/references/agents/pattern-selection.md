# Agent Pattern Selection Guidelines

## Overview

When creating a new agent, the first critical decision is selecting the appropriate structural pattern. Agent patterns determine the level of detail, complexity, and scope of the agent specification. Based on analysis of 150+ agent files, there are three primary patterns with clear selection criteria.

## Pattern Decision Tree

```
START: Create New Agent
   │
   ├─→ What is the agent's scope?
   │     │
   │     ├─→ Complex/Multi-Domain
   │     │     │
   │     │     └─→ Use COMPREHENSIVE Pattern
   │     │            (150-280+ lines, 8-12 sections)
   │     │
   │     └─→ Focused/Narrow
   │           │
   │           └─→ Unique workflow/format requirements?
   │                 │
   │                 ├─→ Yes → SPECIALIZED Pattern
   │                 │        (70-250+ lines, variable sections)
   │                 │
   │                 └─→ No → SIMPLIFIED Pattern
   │                        (30-50 lines, 3-4 sections)
   │
   └─→ Generate agent specification
```

## Detailed Criteria Matrix

| Criteria | Comprehensive | Simplified | Specialized |
|----------|----------------|------------|-------------|
| **Scope** | Broad, multi-domain | Narrow, single-domain | Unique, domain-specific |
| **Expertise Depth** | Deep, advanced | Moderate, focused | Specialized, domain-unique |
| **Workflow Complexity** | Multi-phase, many decisions | Simple, linear | Unique, custom workflow |
| **Dependencies** | Yes (other agents) | No (standalone) | Sometimes (domain-specific) |
| **Required Sections** | 8-12 | 3-4 | Variable (5-10) |
| **Line Count** | 150-280+ | 30-50 | 70-250+ |
| **Model Preference** | opus/sonnet | inherit/sonnet | sonnet (typically) |

## Pattern Characteristics

### Comprehensive Pattern (60% of analyzed agents)
- **Use Case**: Complex architectural, multi-domain expertise
- **Examples**: backend-architect, cloud-architect, security-auditor
- **Sections**: 8-12 required sections
- **Length**: 150-280+ lines
- **Model**: `opus` (complex) or `sonnet` (moderate)
- **Capabilities**: 40-80 subcategories across 8-15 categories

### Simplified Pattern (27% of analyzed agents)
- **Use Case**: Focused, narrow-domain expertise
- **Examples**: quant-analyst, language experts, framework specialists
- **Sections**: 3-4 required sections
- **Length**: 30-50 lines
- **Model**: `inherit` (language/framework) or `sonnet`
- **Capabilities**: 4-7 focus areas (replaces detailed capabilities)

### Specialized Pattern (13% of analyzed agents)
- **Use Case**: Unique workflows, domain-specific formats
- **Examples**: incident-response, documentation, content-creation agents
- **Sections**: Variable, domain-specific sections included
- **Length**: 70-250+ lines
- **Model**: `sonnet` (typically)
- **Capabilities**: Domain-specific sections (e.g., Immediate Actions, Documentation Template)

## Selection Guidelines

### Choose Comprehensive Pattern When:
- Agent spans multiple technical domains
- Requires deep architectural or design expertise
- Has complex decision-making workflows
- Will have dependencies on other agents
- Needs extensive technical detail (40+ subcategories)

### Choose Simplified Pattern When:
- Agent has narrow, well-defined scope
- Expertise is focused on specific technology/framework
- Workflows are straightforward and linear
- Agent should be lightweight and fast to load
- Rapid context switching is important

### Choose Specialized Pattern When:
- Agent requires unique workflow structures
- Domain demands specific formatting or templates
- Agent has non-standard operational requirements
- Custom sections enhance agent capabilities
- Domain-specific patterns are essential

## Validation Checklist

Before proceeding with pattern selection:

- [ ] Agent domain clearly defined
- [ ] Expertise depth assessed (shallow/medium/deep)
- [ ] Workflow complexity evaluated
- [ ] Dependency requirements identified
- [ ] Line count expectations realistic
- [ ] Model selection appropriate for complexity
- [ ] Scope boundaries established

## Common Mistakes to Avoid

### Over-Complexifying Simple Domains
- **Problem**: Using Comprehensive pattern for narrow expertise
- **Solution**: Use Simplified pattern for focused domains like language experts
- **Prevention**: Evaluate if 40+ subcategories are truly needed

### Under-Complexifying Complex Domains
- **Problem**: Using Simplified pattern for multi-domain expertise
- **Solution**: Use Comprehensive pattern for architectural roles
- **Prevention**: Count required capability subcategories

### Ignoring Domain-Specific Requirements
- **Problem**: Using standard patterns when unique workflows needed
- **Solution**: Use Specialized pattern for incident response, documentation
- **Prevention**: Identify if domain requires custom sections
