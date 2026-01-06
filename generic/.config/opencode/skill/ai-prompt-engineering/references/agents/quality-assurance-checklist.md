# Agent Quality Assurance Checklist

## Overview

This comprehensive checklist ensures agent specifications meet quality standards for consistency, reliability, and production readiness. All agents must pass validation before deployment.

## Pre-Creation Validation

### Planning Checklist
- [ ] Agent pattern selected (Comprehensive/Simplified/Specialized)
- [ ] Clear agent domain and boundaries defined
- [ ] Key capabilities identified (3-8 for simplified, 40-80 for comprehensive)
- [ ] Model selection determined (complexity-based)
- [ ] Workflow dependencies identified
- [ ] Scope overlap with existing agents checked
- [ ] Example interaction count planned
- [ ] Line count expectations realistic

## Post-Creation Validation

### Frontmatter Validation
- [ ] `name` field present and kebab-case
- [ ] `description` field present (150-300 characters)
- [ ] `description` follows 4-part structure:
  - Expert [role] specializing in [domains]
  - Masters [skills]
  - Handles [tasks]
  - Use [PROACTIVELY/IMMEDIATELY] for [use cases]
- [ ] `model` field present and valid (`opus`, `sonnet`, or `inherit`)
- [ ] `model` appropriate for agent complexity

## Content Validation by Pattern

### Comprehensive Agent Validation
- [ ] Purpose section present with 2-3 sentences
- [ ] Purpose follows 3-sentence pattern (expertise → mastery → specialization)
- [ ] Capabilities section present with 8-15 categories
- [ ] Each category has 3-8 subcategories
- [ ] Each subcategory has 3-7 items (comma-separated, Oxford comma)
- [ ] Format follows `**[Bold]**: [items]` pattern
- [ ] Behavioral traits section present with 8-12 items
- [ ] All behavioral traits use third-person present tense
- [ ] Behavioral traits start with action verbs
- [ ] Knowledge base section present with 6-12 items
- [ ] Response approach section present with 6-10 phases
- [ ] Response approach uses imperative mood
- [ ] Response approach follows logical workflow progression
- [ ] Example interactions section present with 8-15 items
- [ ] Example interactions cover major capability areas
- [ ] Example interactions are representative real prompts
- [ ] Sections follow strict ordering rules
- [ ] Total length is 150-280+ lines

### Simplified Agent Validation
- [ ] Focus areas section present with 4-7 items
- [ ] Focus areas are concise noun phrases
- [ ] Approach section present with 3-6 principles
- [ ] Approach uses numbered list format
- [ ] Approach principles are action-oriented
- [ ] Output section present with 3-6 deliverables
- [ ] Output items are specific, tangible deliverables
- [ ] No prohibited sections present (Purpose, Capabilities, etc.)
- [ ] Total length is 30-50 lines

### Specialized Agent Validation
- [ ] Purpose section present with 2-3 sentences
- [ ] Domain-specific sections appropriate for agent type
- [ ] Domain-specific sections enhance agent capabilities
- [ ] Domain-specific sections are practical and usable
- [ ] Behavioral traits section present with 8-12 items
- [ ] Knowledge base section present with 6-12 items
- [ ] Response approach section present with 6-10 phases
- [ ] Example interactions section present with 5-10 items
- [ ] Sections follow specialized ordering rules

## Style Validation

### Tone and Voice
- [ ] Overall tone is authoritative and instructional
- [ ] No colloquial language or slang used
- [ ] Professional, expert-level language maintained
- [ ] Consistent voice throughout (third-person for sections, imperative for actions)

### Tense Consistency
- [ ] Purpose section uses present tense
- [ ] Behavioral traits use third-person present tense (-s verbs)
- [ ] Response approach uses imperative mood (bare verbs)
- [ ] Example interactions use imperative mood (quoted prompts)
- [ ] No tense mixing within sections

### Capitalization Conventions
- [ ] Section headers use Title Case
- [ ] Subcategories use Title Case (bold)
- [ ] Technology names use Proper Case (OpenTelemetry, PostgreSQL)
- [ ] Acronyms use ALL CAPS (OWASP, JWT, RBAC)
- [ ] Framework names use Proper Case (React, Next.js)
- [ ] Pattern names use Title Case (Circuit Breaker, Saga Pattern)

### Punctuation Standards
- [ ] Oxford comma used in lists (item1, item2, and item3)
- [ ] Bullet lists use consistent formatting
- [ ] Numbered lists use period + space + bold phase
- [ ] Colons used correctly in definitions and lists
- [ ] No unnecessary punctuation

### Formatting Consistency
- [ ] Markdown syntax used correctly
- [ ] Code blocks use appropriate highlighting (if present)
- [ ] Bold formatting used consistently for emphasis
- [ ] List indentation consistent
- [ ] No formatting errors or inconsistencies

## Cross-Reference Validation

### Workflow Dependencies
- [ ] Workflow Position included if agent has dependencies
- [ ] Dependencies clearly identified (Before, Complements, Enables)
- [ ] Agent relationships accurately described

### Scope Boundaries
- [ ] Key Distinctions included if scope overlaps other agents
- [ ] Clear differentiation from similar agents
- [ ] Scope boundaries well-defined
- [ ] No confusion with existing agent roles

### External References
- [ ] Technology references use proper capitalization
- [ ] Links to authoritative sources (if present)
- [ ] Acronyms defined on first use (if uncommon)
- [ ] No outdated or incorrect references

## Automated Validation Pseudocode

```python
def validate_agent_specification(spec, pattern):
    """Validates agent specification against quality standards."""

    errors = []
    warnings = []

    # Frontmatter validation
    if not spec.get('name') or not is_kebab_case(spec['name']):
        errors.append("Invalid or missing name")

    desc = spec.get('description', '')
    if not (150 <= len(desc) <= 300):
        warnings.append(f"Description length: {len(desc)} (should be 150-300)")

    model = spec.get('model')
    if model not in ['opus', 'sonnet', 'inherit']:
        errors.append(f"Invalid model: {model}")

    # Pattern-specific validation
    if pattern == 'comprehensive':
        errors.extend(validate_comprehensive(spec))
    elif pattern == 'simplified':
        errors.extend(validate_simplified(spec))
    elif pattern == 'specialized':
        errors.extend(validate_specialized(spec))

    # Style validation
    warnings.extend(validate_style(spec))

    # Cross-reference validation
    warnings.extend(validate_cross_references(spec))

    return {
        'valid': len(errors) == 0,
        'errors': errors,
        'warnings': warnings
    }
```

## Validation Severity Levels

### Errors (Must Fix)
- Missing required sections
- Incorrect section ordering
- Invalid frontmatter
- Pattern violations
- Critical content issues

### Warnings (Should Fix)
- Length issues
- Style inconsistencies
- Minor formatting problems
- Optimization opportunities
- Cross-reference improvements

## Success Criteria by Pattern

### Comprehensive Agent Success
- [ ] Follows Comprehensive Pattern (150-280+ lines)
- [ ] Includes all 6 required sections in correct order
- [ ] Has 8-15 example interactions
- [ ] Has 8-15 capability categories with 40-80 subcategories
- [ ] Behavioral traits use third-person present tense
- [ ] Response approach has 6-10 phases
- [ ] Sections follow standard ordering
- [ ] Passes all quality validation checks
- [ ] Clearly defines scope and boundaries

### Simplified Agent Success
- [ ] Follows Simplified Pattern (30-50 lines)
- [ ] Includes all required sections (3-4 sections)
- [ ] Focus areas has 4-7 items
- [ ] Approach has 3-6 principles
- [ ] Output has 3-6 deliverables
- [ ] No prohibited sections present
- [ ] Passes all quality validation checks
- [ ] Clearly defines narrow domain scope

### Specialized Agent Success
- [ ] Follows Specialized Pattern (70-250+ lines)
- [ ] Includes domain-specific sections appropriate for type
- [ ] Domain-specific sections enhance agent capabilities
- [ ] Maintains consistency with universal components
- [ ] Passes all quality validation checks
- [ ] Clearly defines agent's unique workflow/requirements

## Final Validation Steps

1. **Self-Review**: Author reviews against checklist
2. **Peer Review**: Another engineer validates specification
3. **Pattern Compliance**: Ensure adherence to selected pattern
4. **Integration Testing**: Test agent in intended workflow
5. **Documentation Review**: Verify completeness and clarity
6. **Final Approval**: Quality assurance sign-off

## Common Validation Issues

### Pattern Selection Errors
- **Issue**: Wrong pattern chosen for agent scope
- **Fix**: Re-evaluate using decision tree
- **Prevention**: Use pattern selection guidelines upfront

### Content Depth Issues
- **Issue**: Comprehensive agents lack sufficient detail
- **Fix**: Add missing subcategories and examples
- **Prevention**: Plan capability breakdown during creation

### Style Inconsistencies
- **Issue**: Mixed tenses or voices within sections
- **Fix**: Apply tense guidelines strictly
- **Prevention**: Reference style guidelines during writing

### Missing Examples
- **Issue**: Insufficient example interactions
- **Fix**: Generate additional representative prompts
- **Prevention**: Map examples to capability areas early

### Scope Overlap
- **Issue**: Agent scope conflicts with existing agents
- **Fix**: Add Key Distinctions section
- **Prevention**: Review existing agents before creation
