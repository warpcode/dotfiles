---
applyTo: "**/*.prompt.md,**/*.agent.md,**/*.instructions.md,**/skills/**/SKILL.md"
description: "Best practices for writing clear, concise, and safe prompts and system instructions for AI models."
---

<!-- Source: https://github.com/github/awesome-copilot/blob/main/instructions/ai-prompt-engineering-safety-best-practices.instructions.md -->

# AI Prompt Engineering & Instruction Best Practices

## Directives & Clarity

- **Imperative Voice**: State exactly what the model must do using clear, active verbs ("Extract...", "Validate...", "Generate...").
- **Explicit Constraints**: Define exact output schemas (JSON schema, markdown table format, error response structure).
- **Negative Constraints**: Clearly state forbidden behaviors ("Do NOT summarize without citations", "Never modify unstaged files").

## Prompt Patterns

- **Zero-Shot**: Use for deterministic, well-defined lookups or transformations.
- **Few-Shot**: Provide 2-3 realistic input/output pairs when teaching domain-specific naming, tone, or complex schema mappings.
- **Pointer Pattern**: Reference canonical files (`file:///path/to/example.ts`) instead of embedding massive code snippets in system prompts.

## Anti-Patterns to Avoid

- **Hedging & Fluff**: Eliminate conversational filler ("Please make sure to...", "If possible, could you...").
- **Overfitting**: Avoid examples so narrow that the model fails on slight input variations.
- **Context Bloat**: Keep instruction files under strict platform budgets to preserve active reasoning context.
