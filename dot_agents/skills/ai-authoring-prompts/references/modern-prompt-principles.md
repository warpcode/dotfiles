# Modern Prompt Principles & Context Curation

Evidence-based best practices for authoring prompts for modern Large Language Models and native reasoning models (e.g. Claude 3.7 Sonnet / Adaptive Thinking, OpenAI o1/o3-mini, Gemini 2.0 Flash / Pro Thinking).

---

## 1. Shift from Micromanagement to Goal Scoping

Traditional prompting often treated LLMs like brittle interpreters requiring step-by-step procedural scaffolding (e.g., "First read X, then think about Y, then explain your reasoning in detail, then do Z").

On modern reasoning models and capable agentic models, this procedural micromanagement is counterproductive:
- **Native Thinking Replaces Artificial Scaffolding**: Models with internal reasoning tokens perform their own high-compute search and validation passes. Forcing explicit "think step by step" in user prompts wastes output tokens and can constrain the model's internal exploration.
- **Define "Done" Rather than "How"**: Focus the prompt on the objective, domain rules, operational boundaries, and verifiable success criteria. Let the model determine the optimal path to satisfy those criteria.

| Dimension | Legacy / Procedural Prompting | Modern / Goal-Oriented Prompting |
|---|---|---|
| **Core Directive** | "First think step by step through each factor, then..." | "Given the Context, produce the requested Output satisfying the Rules." |
| **Reasoning Guidance** | Prescriptive step-by-step script | Clear success criteria, edge-case bounds, and evaluation rubric |
| **Formatting Control** | Loose prose explanations | Structured markdown headers, typed JSON schema, or markdown tables |
| **Token Utilization** | Wasted on repetitive scaffolding words | Concentrated on essential domain context and constraints |

---

## 2. Context Curation & Structured Markdown Sections

Context curation ("Context Engineering") is the intentional selection and organization of information presented to the model.

### Use Explicit Markdown Headers
Organize distinct sections using clear Markdown headers and code fences to prevent instruction drift, confusion, and ambiguity:

```markdown
## Context
Project uses Go 1.23 with standard library testing.

## Rules
- NEVER edit files in ~/.zsh directly; edit source templates in dot_zsh/.
- Ensure all zsh scripts pass `zsh -n`.

## Task
Refactor the package loader to support lazy hydration.

## Output Contract
Return a unified diff of modified files followed by test verification commands.
```

### Benefits of Structured Sections
1. **Separation of Instructions vs Data**: The model cleanly distinguishes operational rules from payload text or runtime input.
2. **Context Anchoring**: Headers allow the model's attention mechanism to reference specific blocks without cross-contaminating constraints.
3. **Structured Extraction**: Downstream tools and parsers can reliably extract target sections.

---

## 3. The "New Hire" Mental Model

Treat the model as a highly capable, senior colleague who has **zero prior context** on your specific workspace or unstated assumptions:
- If a human engineer would ask *"Which directory should this go in?"* or *"What is the fallback behavior?"*, the prompt is underspecified.
- State defaults, fallback behaviors, and negative constraints explicitly upfront.

---

## 4. Zero-Shot vs Few-Shot Strategy

1. **Start Zero-Shot with Precise Constraints**: Modern reasoning models excel at zero-shot generalization when constraints and schemas are unambiguous.
2. **Use Few-Shot Examples for Syntactic Fragility**: Only add input/output examples when:
   - Defining a non-standard custom format or DSL.
   - Enforcing subtle stylistic nuances that prose struggles to capture.
   - Correcting an observed edge-case failure during testing.
3. **Keep Examples Minimal & Canonical**: One or two clean, minimal examples are more effective than ten verbose, repetitive ones.

---

## 5. Summary of Core Directives

1. **Be Direct & Imperative**: Use active verbs ("Analyze", "Extract", "Refactor") rather than conversational hedges ("Please try to...").
2. **Front-Load Absolute Constraints**: Critical MUST/MUST NOT rules sit near the top or inside dedicated constraint blocks.
3. **Specify Negative Constraints**: Explicitly rule out tempting anti-patterns and shortcuts ("Do NOT use `any`", "NEVER run `rm -rf` on symlinks").
4. **Use Concrete Verification Criteria**: Provide runnable validation checks or verifiable conditions that define task completion.
