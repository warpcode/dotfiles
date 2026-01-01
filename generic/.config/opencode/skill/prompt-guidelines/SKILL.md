---
name: prompt-guidelines
description: >-
  Mandatory protocols for high-fidelity, token-efficient AI prompts. Provides specialized guidance for creating, editing, verifying, reviewing, and checking compliance of Skills, Agents, and Commands via progressive disclosure.
  Scope: system instructions, agent configs, commands, component validation.
  Triggers: "write a prompt", "create a skill", "edit a skill", "verify a skill", "review a skill", "audit a skill", "check skill compliance", "design an agent", "edit an agent", "verify an agent", "review an agent", "audit an agent", "check agent compliance", "new command", "edit command", "verify command", "review command", "audit command", "check command compliance".
---

# PROMPT_ENGINEERING_PROTOCOLS

## CORE PRINCIPLE
**Rule**: Mode frameworks are UNIVERSAL design patterns affecting ALL component behavior (not just output format). Once mode is determined, it affects: cognitive process, workflow, validation, interaction, context handling, output format, AND routing to mode-specific references. Components MUST detect mode and switch entire behavioral framework accordingly.

## ROUTING_PROTOCOL

### Core Fundamentals (Always Load)
READ FILE: @references/core/syntax.md
READ FILE: @references/core/execution-protocol.md
READ FILE: @references/core/cognitive-process.md
READ FILE: @references/core/anchoring.md
READ FILE: @references/core/security.md
READ FILE: @references/core/validation.md

### Implementation Uncertainty (Highest Priority)
IF intent involves UNCERTAINTY OR requests ADVICE on implementation type AND does NOT explicitly specify target type (Skill, Agent, Command) THEN
  READ FILE: @references/routing/implementation-advisor.md

  ### Uncertainty Triggers
  - "What should I build?"
  - "Should this be a skill or agent?"
  - "Help me design a prompt"
  - "What component type do I need?"
  - "Recommend implementation approach"

  ### Priority
  CRITICAL - Must be evaluated before component type routing

  END
END

### Component Creation Intent
IF intent involves "skill" OR "agent" OR "command" THEN
  READ FILE: @references/routing/component-creation.md
END

### Mode Detection & Routing
IF mode keywords detected THEN
  READ FILE: @references/routing/mode-detection.md

  IF "analyze" OR "explain" OR "show" detected THEN
    READ FILE: @references/modes/analyse.md
  END

  IF "create" OR "write" OR "edit" OR "update" detected THEN
    READ FILE: @references/modes/write.md
  END

  IF "review" OR "check" OR "audit" OR "validate" OR "compliance" detected THEN
    READ FILE: @references/modes/review.md
    READ FILE: @references/output/severity-classification.md
  END

  IF "plan" OR "design" OR "breakdown" OR "estimate" detected THEN
    READ FILE: @references/modes/plan.md
    READ FILE: @references/output/jira-structure.md
  END

  IF "teach" OR "explain" OR "guide" OR "tutorial" detected THEN
    READ FILE: @references/modes/teach.md
  END

  IF multiple modes detected THEN
    READ FILE: @references/modes/multi-mode.md
  END
END

### Progressive Disclosure
IF complexity > High THEN
  READ FILE: @references/routing/progressive-disclosure.md
END

### Component-Specific Routing
IF "create skill" OR "edit skill" OR "audit skill" detected THEN
  READ FILE: @references/components/skills.md
END

IF "create agent" OR "edit agent" OR "audit agent" detected THEN
  READ FILE: @references/components/agents.md
END

IF "create command" OR "edit command" OR "audit command" detected THEN
  READ FILE: @references/components/commands.md
END

### Output Format Design
IF "output" OR "template" OR "formatting" detected THEN
  READ FILE: @references/output/common.md
END

## GLOSSARY

**STM**: Structured Telegraphic Markdown (concise, keyword-driven documentation format)
**CoT**: Chain of Thought (explicit reasoning/documentation of thought process)
**LLM**: Large Language Model (generative AI system)
**ref**: Reference (file path using `@path/to/file` syntax)
**PD**: Progressive Disclosure (load references on-demand based on context)
**JWT**: JSON Web Token (authentication token standard)
**REST**: Representational State Transfer (API architectural style)
**SOLID**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion (design principles)
