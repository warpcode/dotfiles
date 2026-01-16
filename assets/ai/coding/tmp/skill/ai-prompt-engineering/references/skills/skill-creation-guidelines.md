# Skill Creation Guidelines

**Important: Read this entire document before starting skill creation.** This guide provides comprehensive frameworks for producing high-quality skills based on analysis of three major skill repositories. It integrates prompt engineering patterns to ensure systematic, reliable skill development.

## Quick Reference

### Core Skill Creation Workflow
1. **Analyze Requirements**: Define skill scope, audience, and complexity level
2. **Choose Structure**: Select directory layout based on content needs
3. **Design SKILL.md**: Follow mandatory sections and appropriate layout type
4. **Create Reference Files**: Add detailed documentation when complexity warrants
5. **Apply Prompt Patterns**: Use chain-of-thought and few-shot learning for systematic development
6. **Validate Output**: Run quality checklists and ensure consistency

### Key Integration Points with Prompt Engineering
- **Few-Shot Learning**: Use curated examples from repository analysis for consistent patterns
- **Chain-of-Thought**: Apply structured reasoning for complex skill architectures
- **Template Systems**: Leverage reusable prompt components for skill sections
- **System Prompts**: Design clear behavioral constraints for skill creation

## Overview

This guide synthesizes patterns from three analyzed repositories (Claude Scientific Skills: 138 skills, Anthropic Skills: 15 skills, wshobson-agents: 108 skills) to provide robust frameworks for creating high-quality skills. It avoids duplicating existing prompt engineering content and instead references established patterns for systematic skill development.

## When to Use This Skill

- Creating new skills for the opencode system
- Updating existing skills with improved structure and content
- Analyzing skill repositories for pattern identification
- Designing skill architectures for complex domains
- Validating skill quality against established standards

## Skill Creation Framework

### Phase 1: Requirements Analysis

**Define Skill Scope:**
- What is the skill's primary purpose?
- Who is the target audience (beginner/expert)?
- What complexity level is appropriate?
- What dependencies exist with other skills?

**Determine Structure Needs:**
- Does the skill require executable code?
- Is extensive documentation needed?
- Are templates or examples necessary?
- Should progressive disclosure be implemented?

### Phase 2: Structure Selection

Use the following decision framework to choose appropriate directory structure:

```
START: Skill Creation
│
├─ Needs executable code?
│  ├─ YES → Add scripts/ directory
│  └─ NO → Continue
│
├─ Has extensive documentation?
│  ├─ YES → Add references/ directory
│  │  ├─ Progressive disclosure needed? → Use resources/ subdirectory
│  │  └─ Standard documentation → Use references/ subdirectory
│  └─ NO → Continue
│
├─ Provides templates/examples?
│  ├─ YES → Add assets/ or examples/ directory
│  └─ NO → Continue
│
└─ Final Structure: SKILL.md + selected directories
```

### Phase 3: SKILL.md Construction

**Mandatory Frontmatter:**
```yaml
---
name: skill-name
description: What skill does + when to use it (200-400 chars)
license: Complete terms in LICENSE.txt
---
```

**Layout Types by Complexity:**

| Layout Type | Characteristics | Length | Use Case |
|-------------|-----------------|--------|----------|
| **Reference-Heavy** | Many code examples, multiple patterns | 400-900 lines | API libraries, design patterns |
| **Progressive Disclosure** | Minimal code, resource triggers | 100-300 lines | Scenario-based guidance |
| **Workflow-Based** | Step-by-step procedures | 400-600 lines | Process automation, tutorials |
| **Balanced** | Concepts + patterns mix | 400-600 lines | General-purpose skills |

**Required Sections:**
- Title (H1)
- Overview (2-3 sentence introduction)
- When to Use This Skill (4-8 concrete use cases)
- Core Capabilities (with "When to use" subsections)
- Best Practices (5-12 actionable items)
- Common Pitfalls (4-8 common mistakes)

### Phase 4: Reference File Creation

**Reference Types:**

| Type | Purpose | Length | When to Create |
|------|---------|--------|---------------|
| **API Reference** | Technical documentation | 300-600 | Complex APIs, multiple methods |
| **Workflow Guide** | Step-by-step procedures | 150-400 | Multi-step processes |
| **Best Practices** | Performance/quality guidelines | 150-300 | Anti-patterns, optimization |
| **Core Concepts** | Foundational knowledge | 200-400 | New paradigms, terminology |

**File Naming Conventions:**
- Use domain-driven names: `api_reference.md`, `workflows.md`
- Avoid rigid templates (FORMS.md, GUIDELINES.md patterns)
- Match content exactly to file name

### Phase 5: Prompt Engineering Integration

**Apply Chain-of-Thought Reasoning:**
Use structured reasoning patterns for complex skill architectures. Break down skill creation into logical steps with intermediate conclusions.

**Implement Few-Shot Learning:**
Reference established skill patterns from analyzed repositories. Use the following few-shot examples:

- **Simple Skill Pattern**: Claude Scientific Skills minimal layout (SKILL.md only)
- **Complex Skill Pattern**: Anthropic Skills with references/ and scripts/
- **Progressive Skill Pattern**: wshobson-agents with resources/ for on-demand loading

**Leverage Template Systems:**
Apply reusable prompt components for consistent section structure. See `references/prompt-templates.md` for variable interpolation techniques.

**Design System Prompts:**
Create clear behavioral constraints using system prompt design patterns. See `references/system-prompts.md` for model behavior specification.

## Quality Assurance Framework

### Validation Checklists

**SKILL.md Checklist:**
- [ ] YAML frontmatter includes name, description, license
- [ ] Description field combines what skill does + when to use (200-400 chars)
- [ ] "When to Use This Skill" section lists 4-8 concrete use cases
- [ ] Core capabilities include "When to use" subsections
- [ ] Code examples are runnable and realistic (imports, setup, comments)
- [ ] Best practices section contains 5-12 actionable items
- [ ] Common pitfalls section identifies 4-8 common mistakes
- [ ] Reference links have clear purpose statements
- [ ] Progressive disclosure implemented when complexity warrants

**Reference File Checklist:**
- [ ] Clear H1 title matching file purpose
- [ ] Table of contents if file exceeds 100 lines
- [ ] Logical section organization (H1 → H2 → H3)
- [ ] Consistent header levels without skipping
- [ ] Present tense, active voice, imperative mood throughout
- [ ] Appropriate technical depth for target audience
- [ ] Complete, working code examples with error handling
- [ ] External links to authoritative sources
- [ ] Cross-references add value without circular dependencies

### Writing Style Standards

**Grammatical Patterns:**
- **Tense**: Present simple for facts and principles
- **Voice**: Active voice for subject-performs-action
- **Mood**: Imperative mood for direct commands
- **Sentence Structure**: Declarative statements with concise phrasing

**Tone and Professionalism:**
- Professional yet accessible technical depth
- Authoritative without arrogance
- Direct and unambiguous instructions
- Consistent formality throughout all files

**Technical Depth Guidelines:**
- **Introductory**: Basic concepts, simple examples
- **Intermediate**: Core workflows, common patterns
- **Advanced**: Optimization, edge cases
- **Expert**: Low-level details, custom implementations

### Code Example Standards

**Completeness Requirements:**
- Include all necessary imports and setup
- Provide realistic data (avoid toy examples)
- Show expected output with inline comments
- Demonstrate error scenarios and edge cases

**Documentation Standards:**
- Inline comments: For logic explanation
- Docstrings: Present for all functions and classes
- Good vs bad comparisons: For anti-patterns
- Formatting: Consistent indentation, syntax highlighting

## Anti-Patterns to Avoid

### SKILL.md Anti-Patterns
- **"When to Use" sections in body**: Trigger conditions belong only in YAML description
- **Future tense instructions**: "You will create" instead of "Create"
- **Passive voice**: "Should be used" instead of "Use"
- **User-facing documentation**: Installation guides, user tutorials
- **Basic concept explanations**: Don't explain variables, loops, or fundamental syntax
- **Vague cross-references**: "See references" without specifying file and purpose
- **Walls of text**: Use bullet points, tables, code blocks for structure

### Reference File Anti-Patterns
- **Incomplete examples**: Missing imports, unclear data requirements
- **Toy examples**: Non-production code that doesn't reflect real usage
- **No error handling**: Examples that work only in ideal conditions
- **Missing context**: Code without explanation of when/why to use
- **Circular references**: References pointing back to SKILL.md sections
- **Duplicating SKILL.md content**: References should extend, not repeat
- **Inconsistent naming**: Mix of plural/singular directories

### Structure Anti-Patterns
- **Over-engineering simple skills**: Don't create references/ for <300 line content
- **Under-engineering complex skills**: Don't put 800+ lines in SKILL.md
- **Rigid template following**: Avoid FORMS.md/GUIDELINES.md when domain names fit better
- **Missing progressive disclosure**: All content in SKILL.md when resources/ would help
- **Inconsistent directory naming**: Mix of plural/singular conventions

## Implementation Workflow

### Step 1: Planning Phase (1-2 hours)
1. Define skill purpose and scope boundaries
2. Identify target audience technical level
3. Determine required directory structure
4. Plan reference file types and purposes
5. Gather authoritative source materials
6. Create skill name and description

### Step 2: Structure Creation (30 minutes)
1. Create skill-name/ directory
2. Initialize SKILL.md with proper frontmatter
3. Create subdirectories as planned
4. Initialize reference files with section headers
5. Set up any required scripts or assets

### Step 3: Content Development (2-4 hours)
1. Write SKILL.md following selected layout type
2. Develop reference files with comprehensive examples
3. Integrate prompt engineering patterns for systematic development
4. Add cross-references and external links
5. Include troubleshooting and best practices
6. Ensure writing style consistency

### Step 4: Validation Phase (1 hour)
1. Run SKILL.md quality checklist
2. Validate reference file checklists
3. Test all cross-references and links
4. Verify code examples are runnable
5. Check writing style consistency
6. Ensure progressive disclosure works correctly

### Step 5: Refinement Phase (30 minutes)
1. Address validation issues found
2. Polish writing and formatting
3. Add missing examples or sections
4. Final consistency review
5. Prepare for integration testing

## Integration with Existing Patterns

This skill creation framework integrates seamlessly with established prompt engineering patterns:

- **Few-Shot Learning**: Use repository analysis examples as few-shot prompts for consistent skill creation
- **Chain-of-Thought**: Apply structured reasoning for complex skill architectures and decision frameworks
- **Prompt Optimization**: Iteratively refine skill content using evaluation frameworks
- **Template Systems**: Leverage reusable components for consistent section structure
- **System Prompts**: Design clear behavioral constraints for skill creation tasks
- **Prompt Safety**: Ensure skill content avoids harmful or biased guidance
- **Multimodal Considerations**: Include visual examples when appropriate for complex concepts
- **Prompt Chaining**: Use multi-step workflows for comprehensive skill development

## Success Metrics

Track the following metrics for skill creation quality:

- **Structural Compliance**: Percentage of mandatory elements present
- **Writing Style Consistency**: Adherence to grammatical and tone standards
- **Code Example Quality**: Completeness and realism of examples
- **Cross-Reference Accuracy**: All links valid and purposeful
- **Progressive Disclosure Effectiveness**: Resources loaded appropriately
- **User Adoption Rate**: How often the skill is successfully used
- **Maintenance Burden**: How often the skill requires updates

## Additional Resources

- **Repository Analysis**: See `/plans/skills-analysis.md` for detailed pattern analysis
- **Repository Reference Materials**: See `/plans/skills-ref/` for comprehensive repository studies
- **Prompt Engineering Integration**: Reference existing prompt patterns in this skill's references/ directory
- **Quality Assurance**: Use validation checklists for systematic improvement
- **Community Standards**: Follow patterns established across analyzed repositories

## Best Practices Summary

1. **Start Simple**: Begin with SKILL.md only, add complexity as needed
2. **Follow Established Patterns**: Use repository analysis as few-shot examples
3. **Apply Prompt Engineering**: Use chain-of-thought and template systems for systematic development
4. **Ensure Quality**: Run validation checklists before finalizing
5. **Maintain Consistency**: Follow writing style and structural standards
6. **Integrate Progressively**: Add directories and files based on genuine need
7. **Document Decisions**: Explain architectural choices in skill content
8. **Test Thoroughly**: Validate examples and cross-references work correctly

This comprehensive framework enables systematic creation of high-quality skills that integrate advanced prompt engineering techniques with proven repository patterns, ensuring reliable and maintainable skill development.