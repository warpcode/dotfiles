# STM Format (Structured Telegraphic Markdown)

## Overview

Structured Telegraphic Markdown (STM) is a concise formatting style for prompt engineering that emphasizes keywords and logical structure while removing conversational filler. STM prioritizes clarity and precision over verbose explanations, making prompts more effective and efficient.

## Core Principles

### Content Rule
**Rule**: Content == Keywords + Logic. Remove conversational filler

### Clarity Constraint
**Constraint**: Clarity > Brevity. Ambiguity == FALSE

### Application
**Apply to**: All descriptions, instructions, examples, and prompt components

## Examples

### Bad STM (Incorrect)

```yaml
description: >-
  This agent is designed to help you with exploring the codebase and
  finding patterns. It can do things like searching for files,
  analyzing code structure, and understanding architecture.
```

### Good STM (Correct)

```yaml
description: >-
  General-purpose agent for code exploration and analysis.
  Scope: codebase search, pattern detection, file analysis, architecture understanding.
```

### Additional Examples

**❌ Bad (Conversational Filler)**:
```
Please provide a detailed explanation of how this function works, including what parameters it takes and what it returns.
```

**✅ Good (STM Format)**:
```
Function explanation required:
- Parameters: list input types and purposes
- Return value: describe output type and content
- Logic: summarize key operations
```

**❌ Bad (Ambiguous)**:
```
Make this better somehow.
```

**✅ Good (Clear and Specific)**:
```
Improve code quality:
- Add error handling for edge cases
- Simplify complex logic
- Add descriptive variable names
```

## When to Use STM vs Full Sentences

### Use STM When:
- **Technical Specifications**: API descriptions, configuration requirements, system constraints
- **Instruction Lists**: Sequential steps, conditional logic, workflow definitions
- **Structured Data**: JSON schemas, validation rules, format requirements
- **Cross-References**: File paths, dependency lists, integration points

### Use Full Sentences When:
- **User-Facing Content**: Error messages, help text, documentation for end users
- **Narrative Explanations**: Teaching concepts, providing context, storytelling
- **Conversational Interfaces**: Chatbots, customer support, natural dialogue
- **Creative Writing**: Marketing copy, blog posts, narrative content

### Decision Framework

| Content Type | STM Preferred | Full Sentences Preferred |
|--------------|---------------|--------------------------|
| API Documentation | ✅ | ❌ |
| Error Messages | ❌ | ✅ |
| Configuration | ✅ | ❌ |
| User Guides | ❌ | ✅ |
| Code Comments | ✅ | ❌ |
| Marketing Copy | ❌ | ✅ |

## Integration with Other Techniques

### With Chain-of-Thought
Combine STM for structure with CoT for reasoning:

```
Analysis Process:
Step 1: Extract key facts from input
Step 2: Apply logical reasoning to facts
Step 3: Generate conclusion

Reasoning:
- Fact: Input contains error condition
- Logic: Error requires validation check
- Conclusion: Add validation before processing
```

### With Few-Shot Learning
Use STM for example formatting:

```
Input: user_query
Output: response_format

Example:
Input: "Calculate 2+2"
Output: "4"
```

### With Template Systems
STM provides the foundation for variable interpolation:

```
Task: {action} {target}
Requirements: {constraints}
Output: {format}
```

### With XML Tags
STM works with XML for structured content:

```
<task>
  <action>analyze</action>
  <target>codebase</target>
  <constraints>focus on performance</constraints>
</task>
```

## Benefits

1. **Improved Clarity**: Eliminates ambiguity through structured format
2. **Token Efficiency**: Reduces unnecessary words while maintaining meaning
3. **Consistency**: Standardized format across different prompts
4. **Maintainability**: Easier to modify and update prompt components
5. **Integration**: Works seamlessly with other prompt engineering techniques

## Common Mistakes

- **Over-Abbreviation**: Don't sacrifice clarity for brevity (e.g., "usr inp" instead of "user input")
- **Missing Context**: Ensure keywords provide enough information for understanding
- **Inconsistent Structure**: Use similar patterns across related prompts
- **Ignoring Readability**: STM should still be human-readable for maintenance

## Best Practices

1. **Start with Full Sentences**: Write complete thoughts first, then condense to STM
2. **Use Consistent Keywords**: Establish standard terminology within your prompt set
3. **Test for Ambiguity**: Have colleagues review STM-formatted prompts
4. **Document Conventions**: Maintain a style guide for your team's STM usage
5. **Balance Efficiency**: Don't over-optimize at the expense of comprehension

## Implementation Checklist

- [ ] Review existing prompts for conversational filler
- [ ] Identify high-impact areas for STM conversion
- [ ] Create STM style guide for your team
- [ ] Test STM prompts for clarity and effectiveness
- [ ] Monitor token usage and quality metrics
- [ ] Update documentation to reflect STM conventions