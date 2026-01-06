# Command Creation Guidelines

## Overview

This guide provides comprehensive frameworks for creating high-quality LLM commands using advanced prompt engineering techniques. It synthesizes patterns from analyzed command repositories and applies prompt engineering principles to ensure commands are discoverable, executable, and production-ready.

## When to Use This Guide

- Creating new commands from scratch
- Updating existing commands with improved structure
- Applying universal patterns for consistency
- Implementing prompt optimization for command generation

## Core Principles

### Universal Structural Requirements

Every command must include these mandatory components:

1. **Title (H1)** - Clear, descriptive command name matching file
2. **Role/Context Definition** - Single paragraph defining purpose and scope using present tense third-person
3. **Requirements Section** - `$ARGUMENTS` template for user input
4. **Core Content** - Detailed instructions with examples
5. **Closing Statement** - Purpose reinforcement

### Frontmatter Metadata (YAML)

```yaml
---
description: Use when [triggering conditions] - [what command does]
argument-hint: [input format hint]
model: haiku|sonnet|opus
allowed-tools: [comma-separated tool list]
---
```

**Pattern**: `Use when [trigger] - [action/purpose]` (50-100 characters)

## Layout Pattern Selection

### Decision Tree for Layout Selection

```
1. Is this a simple, single-operation command?
   ├── YES → Simple Query Layout (Pattern 1)
   └── NO → Continue

2. Does this require multi-agent orchestration?
   ├── YES → Multi-Phase Workflow Layout (Pattern 2)
   └── NO → Continue

3. Is this teaching patterns or creating artifacts?
   ├── YES → Guide/Documentation Layout (Pattern 3)
   └── NO → Continue

4. Does this need extensive code examples?
   ├── YES → Reference/Instructional Layout (Pattern 4)
   └── NO → Continue

5. Is this a focused, parameterized tool?
   ├── YES → Specification/Parameterized Layout (Pattern 5)
   └── NO → Continue

6. Does this need YAML metadata for discovery?
   ├── YES → Frontmatter Metadata Layout (Pattern 6)
   └── NO → Continue

7. Is this coordinating multiple agents?
   ├── YES → Orchestration/Coordination Layout (Pattern 7)
   └── NO → Validation/Quality Gate Layout (Pattern 8)
```

## Pattern Implementations

### Pattern 1: Simple Query Layout (90-150 lines)

**Use for:** Straightforward operations, quick references

**Structure:**
```markdown
---
description: Use when [trigger] - [purpose]
---

# Command Title

Brief description of command purpose.

## Usage

`/command-name [arguments]`

## Variables

- VARIABLE: Description (default: value)

## Steps

1. Action 1
2. Action 2

## Examples

[Concrete usage scenarios]

## Notes

[Important considerations]
```

### Pattern 2: Multi-Phase Workflow Layout (150-300 lines)

**Use for:** Complex operations with sequential phases

**Structure:**
```markdown
---
description: Use when [trigger] - [purpose]
argument-hint: [input format hint]
model: [suggested model]
allowed-tools: [tool list]
---

# Command Title

Comprehensive description of workflow orchestration.

## User Input

**Input**: $ARGUMENTS

## Overview

[High-level workflow explanation]

## Phase 1: [Phase Name]

### Sub-section

[Detailed steps with inline code]

## Phase 2: [Phase Name]

[Steps for second phase]

## Execution Flow Diagram

```
[ASCII flowchart]
```

## Examples

[Detailed scenarios]

## Error Handling

[Error-specific procedures]

## Checklist

- [ ] Verification items
```

### Pattern 3: Guide/Documentation Layout (300+ lines)

**Use for:** Meta-commands teaching patterns or creating artifacts

**Structure:**
```markdown
---
description: Guide for creating X
name: command-name
---

# Command Title

[Comprehensive guide for creating/implementing X]

## Overview

[Core principle in 1-2 sentences]

## When to Create X

**Create when:**
- Condition 1
- Condition 2

**Don't create for:**
- Condition 1

## X Types

### Type 1
[Description]

## Directory Structure

[File tree]

## Anatomy of X

[Component breakdown]

## Anti-Patterns

### ❌ Bad Pattern

[Description]
**Why bad:** [Reason]

### ✅ Good Pattern

[Description]
**Why good:** [Reason]

## X Creation Checklist

**Phase 1:**
- [ ] Item 1

## The Bottom Line

[Core takeaway]
```

## Writing Style Conventions

### Grammatical Patterns

**Frontmatter Description:**
- Tense: Present, third-person ("Use when [trigger] - [purpose]")
- Format: "Use when [condition] - [outcome]"

**Command Body Instructions:**
- Tense: Imperative mood (command form)
- Voice: Active, direct commands
- Examples: "Read the file", "Launch the agent"

**Sentence Structure:**
- Average length: 10-20 words
- Ratio: 60% simple, 25% compound, 15% complex

### Tone and Voice

**Primary Tone:** Direct, Authoritative, Instructional
- No hedging language ("could", "might", "perhaps")
- No politeness markers ("please", "would you mind")
- Clear, unambiguous instructions

**Examples:**
```
❌ BAD: You might want to consider reading the file.
✅ GOOD: Read the file ONCE.
```

### Technical Depth Levels

**Progressive Disclosure:**
1. Introductory: Brief overview (1-3 sentences)
2. Intermediate: Step-by-step procedures, specific commands
3. Advanced: Complex logic, edge cases, algorithms

### Code Example Density

**Strategic Placement:**
- Simple commands: 2-3 code blocks (90-150 lines total)
- Medium commands: 5-8 code blocks (150-300 lines total)
- Complex commands: 10-20+ code blocks (300+ lines total)

**Prose-Code-Prose Pattern:**
```
1. Launch Developer Agent:

Use Task tool with:
- Agent Type: developer
- Model: opus

Launch agent with prompt...
```

### Cross-Referencing Patterns

**Command References (Preferred):**
```markdown
**REQUIRED:** Use superpowers:test-driven-development
**BACKGROUND:** Understand superpowers:systematic-debugging
```

**Reference Density:**
- Low (60%): 0-2 references
- Medium (30%): 3-5 references
- High (10% - meta): 6-10+ references

## Validation Criteria

### Structural Validation (MANDATORY)
- [ ] H1 title present and descriptive
- [ ] Role/context definition paragraph present
- [ ] Requirements section with `$ARGUMENTS`
- [ ] Core content sections appropriate for complexity
- [ ] Output format section (if applicable)
- [ ] Closing statement reinforcing purpose
- [ ] Consistent heading hierarchy (H1 → H2 → H3)
- [ ] Frontmatter includes description

### Content Validation
- [ ] Code blocks have language specified
- [ ] Active voice predominates (≥85% of sentences)
- [ ] Present tense for descriptions
- [ ] Imperative mood for instructions (≥80%)
- [ ] Sentence length 10-25 words average
- [ ] No hedging language
- [ ] Professional, confident tone
- [ ] Appropriate code density for command type
- [ ] Cross-references use command names, not file paths
- [ ] Success criteria measurable and specific

### Quality Validation
- [ ] Examples demonstrate real usage scenarios
- [ ] Error handling documented (for workflows)
- [ ] Security considerations addressed (for destructive operations)
- [ ] Progressive disclosure maintained
- [ ] Command discoverable via description/metadata

## Anti-Patterns and Common Mistakes

### ❌ Structural Anti-Patterns

**File Path References:**
```markdown
❌ BAD: See skills/testing/test-driven-development/SKILL.md
✅ GOOD: Use superpowers:test-driven-development
```

**Hedging Language:**
```markdown
❌ BAD: You might want to consider reading the file.
✅ GOOD: Read the file.
```

**Inconsistent Structure:**
```markdown
❌ BAD: Requirements section missing or malformed
✅ GOOD: ## Requirements\n$ARGUMENTS
```

### ❌ Content Anti-Patterns

**Over-Explanation:**
```markdown
❌ BAD: This command will help you to create commits that are well-formatted and follow conventional commit standards...
✅ GOOD: Create well-formatted commits with conventional commit messages.
```

**Missing Context:**
```markdown
❌ BAD: ## Steps\n1. Do this\n2. Do that
✅ GOOD: ## Context\nUsers need automated commit formatting.\n## Steps\n1. Analyze changes\n2. Format message
```

**Inappropriate Code Density:**
```markdown
❌ BAD: Simple command with 400 lines of code examples
✅ GOOD: Reference command with comprehensive examples
```

## Implementation by Pattern

### For Simple Commands (Pattern 1)
1. Keep sections minimal (6-8 sections max)
2. Use linear flow (no branching logic)
3. Include 2-3 examples showing input/output
4. Use H2 headers only (no deep nesting)
5. Focus on quick reference over comprehensive documentation

### For Workflow Commands (Pattern 2)
1. Define 2-5 clear phases with distinct purposes
2. Include ASCII flowcharts for non-trivial branching
3. Use table-based decision logic for multi-factor choices
4. Add verification checklists with completion tracking
5. Document error handling for each phase

### For Guide Commands (Pattern 3)
1. Structure with 20+ sections using H1-H4 hierarchy
2. Include anti-patterns with before/after examples
3. Add rationalization tables for common excuses
4. Create comprehensive checklists (30+ items)
5. Apply testing methodology to documentation creation

## Success Metrics

### Structural Quality
- Header Hierarchy: Consistent H1→H2→H3 progression
- Section Completeness: All required sections present
- Template Compliance: $ARGUMENTS used correctly
- Naming Consistency: Kebab-case filenames, descriptive titles

### Content Quality
- Writing Clarity: Imperative language, active voice
- Technical Accuracy: Code examples functional and correct
- Progressive Disclosure: Overview before details
- Cross-Reference Quality: Command-based, not file-based

### Execution Quality
- Discoverability: Clear descriptions and metadata
- Error Handling: Comprehensive failure procedures
- Validation: Success criteria measurable
- Security: Safe handling of destructive operations

## Integration with Prompt Engineering

Apply prompt engineering techniques when creating commands:

### Few-Shot Learning
Use dynamic example selection for command templates. Load `references/few-shot-learning.md` for example selection strategies.

### Chain-of-Thought Prompting
Apply structured reasoning for complex workflow commands. Reference `references/chain-of-thought.md` for CoT techniques.

### Prompt Optimization
Use iterative refinement workflows for command generation. Load `references/prompt-optimization.md` for systematic improvement.

### Template Systems
Create reusable command components with variable interpolation. Reference `references/prompt-templates.md` for modular patterns.

### System Prompt Design
Design effective command headers and role definitions. Load `references/system-prompts.md` for behavior specification.

## Command Generation Process

1. **Identify Purpose** - Determine command scope and complexity
2. **Select Pattern** - Use decision tree to choose appropriate layout
3. **Apply Writing Style** - Follow grammatical and tone conventions
4. **Add References** - Include command-based cross-references where appropriate
5. **Validate Structure** - Check against validation criteria
6. **Test Execution** - Verify command clarity and completeness
7. **Iterate Based on Feedback** - Refine using prompt optimization techniques

## Resources

- **Universal Patterns**: Apply structural guidelines from prompt templates
- **Quality Assurance**: Use evaluation frameworks for command testing
- **Prompt Safety**: Reference prompt-safety.md for secure command design
- **Multimodal Prompting**: Consider cross-modal elements in complex commands

The Bottom Line: Commands are executable documentation. Structure them for reliable LLM execution while maintaining human readability. Follow these patterns to create commands that are discoverable, maintainable, and effective for AI agent execution.