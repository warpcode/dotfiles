---
name: ai-prompt-engineering
description: Master advanced prompt engineering techniques to maximize LLM performance, reliability, and controllability in production. Use when optimizing prompts, improving LLM outputs, or designing production prompt templates.
---

# Prompt Engineering Patterns

Master advanced prompt engineering techniques to maximize LLM performance, reliability, and controllability in production.

## When to Use This Skill

- Designing complex prompts for production LLM applications
- Optimizing prompt performance and consistency
- Implementing structured reasoning patterns (chain-of-thought, tree-of-thought)
- Building few-shot learning systems with dynamic example selection
- Creating reusable prompt templates with variable interpolation
- Debugging and refining prompts that produce inconsistent outputs
- Implementing system prompts for specialized AI assistants
- Creating new skills using comprehensive development frameworks
- Updating existing skills with improved structure and content
- Generating high-quality LLM commands using structured guidelines
- Applying universal patterns for command consistency and reliability

## Core Capabilities

- **Few-Shot Learning**: Dynamic example selection and construction
- **Chain-of-Thought Prompting**: Structured reasoning elicitation
- **Prompt Optimization**: Iterative refinement and performance measurement
- **Template Systems**: Reusable prompt components with variable interpolation
- **System Prompt Design**: Model behavior and constraint specification
- **Skill Creation Frameworks**: Comprehensive guidelines for producing high-quality skills based on repository analysis
- **Command Generation**: Structured frameworks for creating production-ready LLM commands with proper layout patterns and writing conventions
- **Universal Pattern Integration**: Applying structural guidelines (progressive disclosure, quality assurance, cross-referencing) to prompt design for better reliability and maintainability

## Quick Start

```python
# Basic prompt engineering pattern
prompt = "Convert this natural language query to SQL: Find all users who registered in the last 30 days"
```

For advanced implementations with templates and examples, see the reference guides below.

## Available Resources

Use these guides based on your specific needs:

- **"I need to implement few-shot learning"** → Load `references/few-shot-learning.md` for example selection strategies and dynamic retrieval
- **"How do I add step-by-step reasoning to prompts?"** → Load `references/chain-of-thought.md` for CoT prompting techniques
- **"My prompts produce inconsistent results"** → Load `references/prompt-optimization.md` for systematic refinement workflows
- **"I want to create reusable prompt templates"** → Load `references/prompt-templates.md` for variable interpolation and modular components
- **"How do I design effective system prompts?"** → Load `references/system-prompts.md` for behavior specification and constraints
- **"How do I ensure prompt safety and security?"** → Load `references/prompt-safety.md` for input validation and jailbreak prevention
- **"I need to work with images or audio in prompts"** → Load `references/multimodal-prompting.md` for cross-modal reasoning techniques
- **"How do I create multi-step workflows?"** → Load `references/prompt-chaining.md` for agent orchestration and complex chains
- **"I want to evaluate and compare prompt performance"** → Load `references/evaluation-frameworks.md` for automated testing and A/B experimentation
- **"How do I integrate universal patterns into my prompts?"** → Load `references/prompt-templates.md` for structural guidelines and integration techniques
- **"I need to create new skills"** → Load `references/skills/skill-creation-guidelines.md` for comprehensive skill development frameworks
- **"How do I create new commands"** → Load `references/commands/command-creation-guidelines.md` for structured command generation with universal patterns

## Best Practices

1. Start simple, add complexity only when needed
2. Test extensively on diverse, representative inputs
3. Treat prompts as code with proper versioning
4. Monitor performance metrics in production
5. Document why prompts are structured as they are

## Common Pitfalls

- Starting with complex prompts before trying simple ones
- Using examples that don't match the target task
- Exceeding token limits with excessive examples
- Leaving room for multiple interpretations

## Assets and Tools

- **references/few-shot-learning.md**: Deep dive on example selection and construction
- **references/chain-of-thought.md**: Advanced reasoning elicitation techniques
- **references/prompt-optimization.md**: Systematic refinement workflows
- **references/prompt-templates.md**: Reusable template patterns
- **references/system-prompts.md**: System-level prompt design
- **references/prompt-safety.md**: Input validation, jailbreak prevention, and content policies
- **references/multimodal-prompting.md**: Image/text combinations and cross-modal reasoning
- **references/prompt-chaining.md**: Multi-step workflows and agent orchestration
- **references/evaluation-frameworks.md**: Automated testing, benchmarking, and A/B testing
- **references/skills/skill-creation-guidelines.md**: Comprehensive frameworks for creating high-quality skills
- **references/commands/command-creation-guidelines.md**: Structured guidelines for generating production-ready LLM commands
- **assets/prompt-template-library.md**: Ready-to-use prompt templates for common tasks, including universal pattern integration
- **assets/few-shot-examples.json**: Curated example datasets for various domains

## Success Metrics

Track accuracy, consistency, latency, token usage, success rate, and user satisfaction.

## Implementation Guide

1. Start with simple prompts, test, then add complexity
2. Use the reference guides above for specific techniques
3. Experiment with the provided templates and examples
4. Implement automated evaluation and optimization

## Quality Assurance Checklist

Before deploying prompts in production:

- [ ] Test on diverse, representative inputs (not just edge cases)
- [ ] Validate outputs meet quality standards and consistency requirements
- [ ] Measure performance metrics (accuracy, latency, token usage)
- [ ] Document prompt rationale and expected behavior
- [ ] Include fallback mechanisms for unreliable prompts
- [ ] Test for adversarial inputs and jailbreak attempts
- [ ] Monitor performance in production with automated alerts
