# Agent Model Selection Guidelines

## Overview

Model selection determines which Claude model (opus, sonnet, or inherit) an agent uses. The choice affects complexity handling, response quality, and token efficiency. Based on analysis of 150+ agents, model selection follows clear complexity-based criteria.

## Model Options

### Opus (`opus`)
- **Complexity Level**: High (architectural, multi-domain)
- **Use Cases**: Complex architectural decisions, comprehensive expertise
- **Examples**: `backend-architect`, `security-auditor`, `cloud-architect`
- **Token Budget**: Higher tolerance for detailed responses
- **Strengths**: Deep reasoning, comprehensive analysis, complex problem-solving

### Sonnet (`sonnet`)
- **Complexity Level**: Medium (operational, domain-specific)
- **Use Cases**: Operational tasks, incident response, documentation
- **Examples**: `incident-responder`, `docs-architect`, `qa-engineer`
- **Token Budget**: Balanced efficiency and capability
- **Strengths**: Fast responses, good reasoning, practical solutions

### Inherit (`inherit`)
- **Complexity Level**: Focused (language/framework experts)
- **Use Cases**: Language-specific, framework-focused expertise
- **Examples**: `python-pro`, `react-pro`, `golang-expert`
- **Token Budget**: Optimized for technical precision
- **Strengths**: Domain depth, technical accuracy, specialized knowledge

## Selection Decision Framework

### Complexity Assessment Matrix

| Factor | Opus Criteria | Sonnet Criteria | Inherit Criteria |
|--------|----------------|-----------------|------------------|
| **Domain Breadth** | Multi-domain, architectural | Domain-specific, operational | Single technology/framework |
| **Decision Complexity** | High (trade-offs, alternatives) | Medium (process, procedures) | Low (technical implementation) |
| **Expertise Depth** | Deep, comprehensive | Moderate, practical | Focused, specialized |
| **Workflow Dependencies** | Multiple agents, orchestration | Some dependencies | Standalone, independent |
| **Response Requirements** | Detailed analysis, alternatives | Structured outputs, guidance | Technical precision, examples |

### Pattern-Based Defaults

| Agent Pattern | Default Model | Rationale |
|---------------|----------------|-----------|
| **Comprehensive** | `opus` | Complex multi-domain expertise requires deep reasoning |
| **Simplified** | `inherit` | Language/framework focus needs technical precision |
| **Specialized** | `sonnet` | Domain-specific workflows need practical guidance |

### Exceptions and Overrides

#### Comprehensive Agents Using Sonnet
- **When**: Operational focus over architectural design
- **Examples**: `performance-engineer` (practical optimization)
- **Rationale**: Operational tasks benefit from faster, more direct responses

#### Simplified Agents Using Sonnet
- **When**: Broad domain expertise beyond single technology
- **Examples**: `quant-analyst` (finance domain, not single tool)
- **Rationale**: Domain knowledge requires balanced reasoning capability

#### Specialized Agents Using Opus
- **When**: Complex domain requirements with architectural implications
- **Examples**: Complex incident response with system-wide impact
- **Rationale**: Deep analysis needed for critical operational decisions

## Model Selection Validation

### Pre-Selection Checklist
- [ ] Agent complexity level assessed (low/medium/high)
- [ ] Domain breadth evaluated (narrow/broad)
- [ ] Workflow requirements identified
- [ ] Response expectations defined
- [ ] Token efficiency considerations reviewed

### Validation Questions
- [ ] Does the agent need deep architectural reasoning? (→ `opus`)
- [ ] Is the agent language/framework-specific? (→ `inherit`)
- [ ] Does the agent require fast, practical responses? (→ `sonnet`)
- [ ] Are there complex trade-off decisions? (→ `opus`)
- [ ] Is the domain narrow and technical? (→ `inherit`)

## Model Characteristics and Trade-offs

### Opus Characteristics
**Advantages:**
- Superior reasoning for complex problems
- Better handling of trade-offs and alternatives
- More comprehensive responses
- Stronger at architectural decisions

**Disadvantages:**
- Higher token consumption
- Potentially slower responses
- May over-engineer simple problems

### Sonnet Characteristics
**Advantages:**
- Balanced performance and efficiency
- Good for operational workflows
- Faster response times
- Practical, actionable guidance

**Disadvantages:**
- Less depth for truly complex problems
- May simplify architectural decisions
- Limited reasoning breadth

### Inherit Characteristics
**Advantages:**
- Optimized for technical precision
- Excellent for language/framework specifics
- Efficient token usage
- Deep domain expertise

**Disadvantages:**
- Limited to technical implementation
- Poor at high-level architectural decisions
- May lack broader context

## Domain-Specific Model Recommendations

### Architecture Agents
- **Backend/Frontend Architects**: `opus` (complex system design)
- **Database Architects**: `opus` (data modeling complexity)
- **Cloud Architects**: `opus` (infrastructure complexity)
- **Security Architects**: `opus` (threat modeling depth)

### Development Agents
- **Language Experts**: `inherit` (technical precision)
- **Framework Experts**: `inherit` (framework-specific knowledge)
- **Full-Stack Developers**: `sonnet` (balanced technical skills)

### Operational Agents
- **DevOps Engineers**: `sonnet` (practical operations)
- **Performance Engineers**: `sonnet` (optimization procedures)
- **QA Engineers**: `sonnet` (testing methodologies)

### Specialized Agents
- **Incident Responders**: `sonnet` (fast, practical responses)
- **Documentation Specialists**: `sonnet` (structured content creation)
- **Content Creators**: `sonnet` (practical writing guidance)

## Model Selection Validation Pseudocode

```python
def determine_model_selection(agent_type, complexity_level, domain_breadth):
    """
    Determines recommended Claude model for the agent.

    Args:
        agent_type: str - Type of agent (architect, specialist, generalist)
        complexity_level: int - 1-10 scale of complexity
        domain_breadth: str - 'narrow', 'medium', 'broad'

    Returns:
        str - 'opus', 'sonnet', or 'inherit'
    """

    # High complexity architectural agents
    if agent_type in ['architect', 'security_auditor',
                      'performance_engineer', 'database_architect',
                      'cloud_architect'] and complexity_level >= 8:
        return 'opus'

    # Medium complexity operational agents
    elif agent_type in ['incident_responder', 'documentation_specialist',
                        'seo_specialist', 'content_creator',
                        'database_admin'] and complexity_level >= 5:
        return 'sonnet'

    # Language/framework specialists
    elif agent_type in ['language_expert', 'framework_expert']:
        return 'inherit'

    # Domain-specific narrow focus
    elif domain_breadth == 'narrow' and agent_type.endswith('-expert'):
        return 'inherit'

    # Default to sonnet for medium complexity
    else:
        return 'sonnet'
```

## Model Performance Expectations

### Response Quality Metrics

| Model | Reasoning Depth | Response Speed | Token Efficiency | Practical Focus |
|-------|-----------------|----------------|------------------|-----------------|
| **Opus** | High | Medium | Low | Medium |
| **Sonnet** | Medium | High | Medium | High |
| **Inherit** | Low | High | High | High |

### Use Case Fit

| Use Case | Best Model | Rationale |
|----------|------------|-----------|
| **Architectural Design** | `opus` | Deep reasoning for complex trade-offs |
| **Code Implementation** | `inherit` | Technical precision for coding tasks |
| **Incident Response** | `sonnet` | Fast, practical operational guidance |
| **Documentation** | `sonnet` | Structured content creation |
| **Performance Tuning** | `sonnet` | Practical optimization procedures |
| **Security Review** | `opus` | Deep threat modeling and analysis |

## Model Selection Checklist

- [ ] Agent type clearly identified
- [ ] Complexity level assessed (1-10 scale)
- [ ] Domain breadth evaluated
- [ ] Primary use cases defined
- [ ] Response requirements specified
- [ ] Token efficiency considered
- [ ] Model characteristics reviewed
- [ ] Domain-specific recommendations checked
- [ ] Validation questions answered
- [ ] Final model selection justified

## Common Model Selection Mistakes

### Over-Engineering with Opus
- **Problem**: Using `opus` for simple technical tasks
- **Consequence**: Unnecessarily slow responses, higher costs
- **Solution**: Use `inherit` for language-specific tasks

### Under-Engineering with Inherit
- **Problem**: Using `inherit` for complex architectural decisions
- **Consequence**: Insufficient reasoning depth
- **Solution**: Use `opus` for architectural complexity

### Ignoring Domain Requirements
- **Problem**: Using default model without domain consideration
- **Consequence**: Suboptimal performance for specific use cases
- **Solution**: Match model to domain requirements

## Success Criteria

Model selection is successful when:
- Model matches agent complexity level
- Domain requirements are satisfied
- Response expectations are met
- Token efficiency is optimized
- Performance trade-offs are acceptable
- Use case fit is optimal
- Selection can be justified with clear rationale
