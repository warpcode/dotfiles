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

### Template Variable Hygiene
When designing prompt templates, dynamic slots, or parameter placeholders:
- **Standard Variable Format**: Use double curly braces with uppercase snake case: `{{VARIABLE_NAME}}`.
- **Markdown Fences & Headers**: Present dynamic variables within clean Markdown code fences and explicit markdown headers.
- **STRICTLY NO XML TAGS**: Do NOT wrap dynamic variables or prompt sections in pseudo-XML tags (e.g. `<context>{{CONTEXT}}</context>`, `<input>...</input>`, `<task>...</task>`). XML wrappers add token noise, trigger inconsistent schema inferences, and violate repository Markdown conventions. Use markdown headers and standard code blocks instead:

```markdown
## Input Context
```json
{{INPUT_JSON}}
```

## User Query
{{USER_QUERY}}
```

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

## 5. Universal Prompt Writing Patterns

### Calibrated Specificity
Match precision to fragility. Steps that must not vary get exact commands or rigid syntax; judgment calls get heuristics:
- **Exact (High Fragility)**: `Validate frontmatter: awk '/^---$/{c++;next} c==1' SKILL.md | yq '.name'`
- **Heuristic (Low Fragility)**: `When two categories fit, prefer the simpler one.`

### Instruction Atomicity
One action per bullet or step. Compound instructions (e.g. *"Validate the output, then commit the changes and update the changelog"*) get partially executed by LLMs. Split them into distinct, single-action items or sequential checklists.

### Consistent Terminology
One concept, one word. Calling bundled detail a "reference file" in one section and a "resource" in another makes agents treat them as different entities. Define each term once and reuse it verbatim throughout the prompt.

### Resilient Directives (Explain "Why")
State the rationale behind non-obvious rules rather than relying solely on bare `MUST` statements. Instructions with clear reasoning survive ambiguous edge cases where rigid commands break down.

### Write for the General Case (Theory of Mind)
Apply theory of mind to prompt authoring: anticipate how the model will interpret each instruction in situations beyond the immediate test case. Prefer rules that generalize over ones over-fitted to the specific example that prompted them.

### Ambiguity Resolution Lookup Table
Every prompt instruction must have exactly one valid interpretation. Replace vague adjectives, subjective qualitative goals, and loose temporal descriptors with concrete metrics and deterministic bounds:

| Ambiguous / Vague Directive | Concrete Metric & Deterministic Bound | Rationale / Resolution |
|---|---|---|
| *"Be concise"* | *"Respond in ≤3 sentences (or ≤50 words)."* | Eliminates subjectivity in output length. |
| *"Summarise briefly"* | *"Provide a bulleted summary with ≤5 items, each ≤20 words."* | Bounded bullet count and word limits. |
| *"Use a friendly / professional tone"* | *"Use second person ('you'), active voice, contractions allowed, zero conversational filler or hedges."* | Concrete stylistic constraints. |
| *"Handle errors gracefully"* | *"On error: log message to stderr, emit JSON error payload `{\"error\": \"...\"}`, exit status 1 without uncaught exceptions."* | Deterministic error handling and exit codes. |
| *"Process recent items"* | *"Process items with `timestamp >= NOW() - 30 days`."* | Explicit, queryable time window. |
| *"Ensure high performance / fast"* | *"Execution latency MUST remain <200ms for p95 requests; memory allocation capped at ≤256MB."* | Measurable SLA and resource ceiling. |
| *"Handle large payloads / files"* | *"For payloads >10MB, stream chunked in 64KB buffers instead of loading into RAM."* | Deterministic threshold and processing mechanism. |
| *"Keep code clean and maintainable"* | *"Functions ≤30 lines, cyclomatic complexity ≤10, 100% linter compliance with zero warnings."* | Verifiable code quality and complexity bounds. |

---

## 6. Summary of Core Directives

1. **Be Direct & Imperative**: Use active verbs ("Analyze", "Extract", "Refactor") rather than conversational hedges ("Please try to...").
2. **Front-Load Absolute Constraints**: Critical MUST/MUST NOT rules sit near the top or inside dedicated constraint blocks.
3. **Specify Negative Constraints**: Explicitly rule out tempting anti-patterns and shortcuts ("Do NOT use `any`", "NEVER run `rm -rf` on symlinks").
4. **Use Concrete Verification Criteria**: Provide runnable validation checks or verifiable conditions that define task completion.

