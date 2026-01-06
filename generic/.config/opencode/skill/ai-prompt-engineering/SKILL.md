---
name: ai-prompt-engineering
description: Master advanced prompt engineering techniques to maximize LLM performance, reliability, and controllability in production. Use when optimizing prompts, improving LLM outputs, or designing production prompt templates.
---

# Prompt Engineering Patterns

Master advanced prompt engineering techniques to maximize LLM performance, reliability, and controllability.

## When to Use This Skill

- Designing complex prompts for production LLM applications
- Optimizing prompt performance and consistency
- Implementing structured reasoning patterns (chain-of-thought, tree-of-thought)
- Building few-shot learning systems with dynamic example selection
- Creating reusable prompt templates with variable interpolation
- Debugging and refining prompts that produce inconsistent outputs
- Implementing system prompts for specialized AI assistants

## Core Capabilities

- **Few-Shot Learning**: Dynamic example selection and construction
- **Chain-of-Thought Prompting**: Structured reasoning elicitation
- **Prompt Optimization**: Iterative refinement and performance measurement
- **Template Systems**: Reusable prompt components with variable interpolation
- **System Prompt Design**: Model behavior and constraint specification

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

- **assets/prompt-template-library.md**: Ready-to-use prompt templates for common tasks
- **assets/few-shot-examples.json**: Curated example datasets for various domains
- **scripts/optimize-prompt.py**: Automated prompt optimization and evaluation tool

## Success Metrics

Track accuracy, consistency, latency, token usage, success rate, and user satisfaction.

## Implementation Guide

1. Start with simple prompts, test, then add complexity
2. Use the reference guides above for specific techniques
3. Experiment with the provided templates and examples
4. Implement automated evaluation and optimization
