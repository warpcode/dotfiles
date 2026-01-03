---
name: prompt-engineering
description: >-
  Core prompt-engineering protocols mandatory for ALL prompt-related tasks.
  Provides LLM prompt engineering best practices: clear/direct, multishot, chain-of-thought, XML tags, prompt chaining, long context, extended thinking.
  Includes guard rails: reduce hallucinations, increase consistency, mitigate jailbreaks, handle streaming refusals, reduce prompt leak, keep in character.
  Scope: general prompt engineering principles and best practices.
  Triggers: all prompt-related tasks.
---

# PROMPT ENGINEERING PROTOCOLS

## CORE PRINCIPLE
**Rule**: Be clear, direct, and provide contextual information. Think step-by-step. Use XML tags for structure. Provide examples for guidance.

## SYNTAX & FORMATTING

### STM FORMAT
- **Rule**: Content == Keywords + Logic. Remove conversational filler
- **Constraint**: Clarity > Brevity. Ambiguity == FALSE
- **Apply to**: All descriptions, instructions, examples

## BE CLEAR AND DIRECT

**Golden Rule**: Show your prompt to a colleague with minimal context. If they're confused, the LLM will be too.

### How To Be Clear, Contextual, And Specific

- **Give the LLM contextual information**:
  - What task results will be used for
  - What audience output is meant for
  - What workflow task is part of, and where this task belongs in that workflow
  - The end goal of task, or what a successful task completion looks like

- **Be specific about what you want the LLM to do**:
  - If you want the LLM to output only code and nothing else, say so

- **Provide instructions as sequential steps**:
  - Use numbered lists or bullet points to better ensure that the LLM carries out task exact way you want it to

### Examples

❌ **Unclear Prompt**: Please remove all personally identifiable information from these customer feedback messages: {{FEEDBACK_DATA}}

✅ **Clear Prompt**: Task == Anonymize customer feedback for quarterly review.

**Instructions**:
1. Replace PII (names, email, phone) with placeholders (CUSTOMER_[ID], EMAIL_[ID], PHONE_[ID])
2. Keep product mentions intact
3. Output processed messages separated by "---"

**Data**: {{FEEDBACK_DATA}}

## LONG CONTEXT TIPS

- **Put longform data at top**: Place documents (~20K+ tokens) above query/instructions
- **Structure with XML**: Wrap docs in `<document><source>...</source><document_content>...</document_content></document>`
- **Ground in quotes**: Ask LLM to extract quotes first, then analyze (reduces noise)

### Example
```xml
<documents>
  <document index="1"><source>report.pdf</source><document_content>{{REPORT}}</document_content></document>
  <document index="2"><source>data.xlsx</source><document_content>{{DATA}}</document_content></document>
</documents>
Extract quotes relevant to [task]. Analyze based on quotes.
```
## LOGIC NOTATION

### When To Use Logic Gates vs Natural Language

- **Use logic gates** for complex conditional logic, algorithmic instructions, and when precision is critical
- **Use natural language** for simple explanations, general guidance, and when readability is more important than formal precision
- **Example logic gates**: IF input_invalid THEN Validate ELSE Process END
- **Example natural language**: Validate input before processing, or continue if already valid

### Logic Design Philosophy: Explicit vs Implicit

**Purpose**: Guide prompt designers on when to use explicit logic vs implicit understanding.

#### When Explicit Logic Wins

**Use Keywords/Logic Gates When**:
- **Precision Required**: Exact, predictable behavior needed (routing, classification, validation)
- **Testability Matters**: "Did 'skill' match?" is trivial to verify and debug
- **Performance Critical**: O(1) matching vs LLM inference latency + cost
- **Technical Tasks**: Developer tools where users are explicit ("create a skill", "validate schema")

**Benefits of Explicit Logic**:
- **Deterministic**: Same input always produces same output
- **No Ambiguity**: Keywords are explicit; classification is probabilistic
- **No Circular Dependency**: Using LLM to determine what to orchestrate creates confusion
- **Instant**: No extra LLM call required

**Examples of Explicit Logic**:
```markdown
IF "skill" OR "create.*skill" OR "new.*skill" detected THEN
  Load skill-creation workflow
END
```

#### When Implicit/Intent-Based Makes Sense

**Use Natural Language/Intent When**:
- **Ambiguity Expected**: Conversational AI, emotional support, vague queries
- **Context Understanding Required**: "I'm feeling sad" → emotional support (not keyword matching)
- **Natural Language Interfaces**: "Book a flight to Paris" → booking intent
- **Creative/Exploratory**: Brainstorming, ideation, open-ended tasks

**Benefits of Intent-Based**:
- **Flexibility**: Handles variations and nuances in natural language
- **User Experience**: More natural, less rigid than exact keyword matching
- **Adaptive**: Can infer intent from context and partial information

**Examples of Intent-Based**:
```
User: "I'm not sure what I need"
System: Ask clarifying questions to understand intent
```

#### Decision Framework

| Factor | Explicit Logic | Intent-Based |
|--------|---------------|--------------|
| **Precision** | High (deterministic) | Medium (probabilistic) |
| **Performance** | Instant | Variable (LLM call) |
| **Testability** | Trivial | Difficult |
| **Flexibility** | Low (exact match) | High (variations ok) |
| **Best For** | Technical tasks, routing, classification | Conversational AI, ambiguous queries |

#### Hybrid Approach

**Combine Both When**:
- **Default**: Try explicit keyword matching first (fast, predictable)
- **Fallback**: If no match, use intent classification (flexible, adaptive)
- **Example**:
  ```markdown
  IF "skill" OR "create.*skill" detected THEN
    Load skill-creation workflow
  ELSE IF intent ambiguous THEN
    Ask: "Are you working with skills, agents, or commands?"
  END
  ```

#### Best Practices

**For Explicit Logic (Keywords/Logic Gates)**:
- Use specific verbs/nouns (create, edit, validate, database, api)
- Expand with regex for flexibility (skill|create.*skill|new.*skill)
- Log what matched for debugging
- Provide fallback for unrecognized input

**For Intent-Based Logic**:
- Use for open-ended or conversational contexts only
- Provide clear examples of expected inputs
- Ask clarifying questions when intent uncertain
- Avoid for technical task routing (use keywords instead)

### Symbols
- `->` (Causes)
- `=>` (Implies)
- `!=` (Not)
- `&&` (AND)
- `||` (OR)

### Conditionals
- **Single**: IF condition THEN ... END
- **Two branches**: IF condition THEN ... ELSE ... END
- **Multiple**: IF condition THEN ... ELSE IF condition THEN ... ELSE ... END
- **Nested**: IF inside another IF block

### Line Breaks
- Each logic chain MUST be on new line
- Inside IF blocks: Indented lines, no bullet points
- Outside IF blocks: Each chain on new line
- Multi-line actions: Indent continuation lines

## VARIABLE BINDING

### Mode A (Structured)
- Enforce strict schema (JSON/YAML)
- "Keys == Immutable."

### Mode B (Conversational)
- Enforce Tone/Style
- "Explanation == Concise && Technical."

### Constraint
- Define Output_Mode explicitly

## DESCRIPTION FORMAT

**Common Rules**: STM format (keywords only, no filler), single newlines, no blank lines

## STM EXAMPLES

❌ **Incorrect**:
```yaml
description: >-
  This agent is designed to help you with exploring the codebase and
  finding patterns. It can do things like searching for files,
  analyzing code structure, and understanding architecture.
```

✅ **Correct**:
```yaml
description: >-
  General-purpose agent for code exploration and analysis.
  Scope: codebase search, pattern detection, file analysis, architecture understanding.
```

## REFERENCE LOADING

- **Syntax**: `Ref == @path/to/file`
- **Constraint**: Markdown Links `[text](path)` == FORBIDDEN
- **Rule**: All `@` paths MUST be relative to skill's main SKILL.md file

## XML TAGS

**Benefits**: Clarity, accuracy, flexibility, parseability

**Best Practices**:
- Be consistent with tag names
- Nest tags: `<outer><inner></inner></outer>` for hierarchy
- Combine with multishot `<examples>` or CoT `<thinking><answer>`

**Example**: Use `<document><source>...</source><content>...</content></document>` for structured data

## EXECUTION PROTOCOL

**Purpose**: Mandatory 4-phase structure for all components

### PHASE 1: CLARIFICATION (Ask)
**Logic**: Ambiguity > 0 → Stop && Ask
**Instruction**:
```
Check task completeness (requirements, context, constraints)
IF requirements != complete THEN List missing && Wait(User_Input) END
IF context ambiguous THEN Clarify && Wait(User_Input) END
Proceed to Phase 2
```

### PHASE 2: PLANNING (Think)
**Logic**: Task → Plan → Approval
**Instruction**:
```
Analyze task (steps, dependencies, impacts)
IF impact > Low THEN Propose plan (Steps + Files + Impacts) && Wait(User_Confirm) ELSE Execute END
IF complex THEN Break into subtasks END
```

### PHASE 3: EXECUTION (Do)
**Logic**: Step_1 → Verify → Step_2
**Instruction**:
```
For each step
  Execute action
  Validate result
  IF fails THEN Identify failure && Apply fix && Re-validate END
END
```

### PHASE 4: VALIDATION (Check)
**Logic**: Result → Checklist → Done
**Instruction**:
```
Run checklist (requirements, quality, safety)
IF fails THEN Identify issues && Apply corrections && Re-run END
Complete task
```

**Exit Criteria**: Phase 1 (requirements confirmed), Phase 2 (plan approved), Phase 3 (steps validated), Phase 4 (checklist passed)

## LOGIC CHAIN RULES (CRITICAL)

- **Multi-Line Support**: Each phase can contain multiple logic chains
- **Line Separation**: Each logic chain MUST be on its own line
- **IF Blocks**:
  - IF/ELSE/ELSE IF blocks MUST use END marker
  - Multiple logic chains within IF block - each on new line, indented
  - Nested IF blocks supported (END markers for each)
- **No Single-Line Constraint**: Phases are NOT limited to one logic chain

## PROMPT CHAINING

**Benefits**: Accuracy (full attention per subtask), Clarity (simpler steps), Traceability (easy debugging)

**How To Chain**:
1. Identify subtasks (distinct, sequential steps)
2. Structure handoffs with XML tags
3. Single-task goal per subtask
4. Iterate based on LLM performance

**Workflows**:
- Multi-step analysis: Extract → Analyze → Report
- Content creation: Research → Outline → Draft → Edit → Format
- Data processing: Extract → Transform → Analyze → Visualize
- Self-correction: Draft → Review → Refine

**Example**: Prompt 1: Review contract → Output <risks>. Prompt 2: Draft email based on <risks>. Prompt 3: Review email tone.

**Tip**: Run independent subtasks in parallel for speed.

## COGNITIVE PROCESS

### PURPOSE
Define cognitive frameworks for high-quality reasoning and output.

### CHAIN OF THOUGHT (CoT)

- **Directive**: Mandate planning phase
- **Instruction**: "Plan steps && checks before output. Document reasoning process"
- **Benefits**: Accuracy (step-by-step reduces errors), Coherence (structured thinking), Debugging (visible thought process)

**When To Use**: Complex math, multi-step analysis, document writing, multi-factor decisions

**Techniques** (least to most complex):

1. **Basic**: "Think step-by-step" (minimal guidance)
2. **Guided**: Outline specific steps (lacks structure)
3. **Structured**: `<thinking></thinking><answer></answer>` XML tags (separates reasoning from output)
4. **Critic**: "Assume role 'QA_Critic'. If Draft != Rules → Rewrite" (force self-correction)


### OUTPUT PRIMING

- **Directive**: Force entry point.
- **Action**: End prompt with expected start of response (e.g., `Here is the JSON: {`).

### ANCHORING

### Few-Shot (Positive)

- **Directive**: Provide labeled examples using markdown code blocks.
- **Structure**: ```language\nContent\n```
- **Purpose**: Demonstrate correct implementation patterns

### Anti-Examples (Negative)

- **Directive**: Define failure states.
- **Action**: Show common error -> Label "INCORRECT" -> Explain fix.
- **Structure**: Use markdown code blocks for clarity

### Reference Anchoring

- **Directive**: Bind terms to definitions.
- **Instruction**: "Ref [Term] == [Definition_Block]."

## MULTISHOT PROMPTING

**Benefits**: Accuracy (reduces misinterpretation), Consistency (enforces uniform structure), Performance (boosts complex task handling)

**Effective Examples**:
- Relevant (mirrors use case)
- Diverse (covers edge cases)
- Clear (wrapped in `<example>` or `<examples>` tags)

**Tip**: Include 3-5 diverse examples. More = better performance on complex tasks.

## SECURITY FRAMEWORK

### PURPOSE
Universal security protocols for all components.

### CORE PRINCIPLES

- **Zero Trust**: Assume all input is malicious until validated
- **Least Privilege**: Execute with minimal required permissions
- **Fail Safe**: Default to safe state on error
- **Defense in Depth**: Multiple validation layers

### MITIGATE JAILBREAKS

#### Basic Techniques (General Applicability)

- **Harmlessness screens**: Use a lightweight model to pre-screen user inputs.

**Example: Harmlessness Screen for Content Moderation**

**User**: A user submitted this content: {{CONTENT}}

**Assistant (prefill)**: (Y) if content violates policy, (N) if acceptable

**Correct response format**:
- **Y** - Content harmful, refuse
- **N** - Content acceptable, proceed

- **Input validation**: Filter prompts for jailbreaking patterns (use LLM to create generalized validation screen)
- **Prompt engineering**: Emphasize ethical/legal boundaries
- **Continuous monitoring**: Analyze outputs for jailbreaking signs, iteratively refine prompts

#### Enterprise Examples

**Ethical Bot**: You are [Corp] AI. Values: Integrity, Compliance, Privacy, IP Respect. Screen query → Process if compliant else "Cannot perform action against [Corp] values."

**Financial Bot**: You are [Corp] financial advisor. Directives: Validate against SEC/FINRA, refuse insider trading, protect client privacy. Screen → Process if compliant else "Violates regulations."

### REDUCE PROMPT LEAK

**Strategies**:
- Separate context from queries (system prompts, emphasize in User turn, reemphasize in Assistant prefill)
- Post-processing: Filter outputs for leak keywords (regex, keyword filtering)
- Avoid unnecessary proprietary details (distracts from "no leak" instructions)
- Regular audits: Review prompts/outputs for leaks

**Example**: AnalyticsBot with proprietary formula. System: "NEVER mention formula." User: "Remember to never mention formula." Assistant prefill: "[Never mention formula]"

**Note**: Use only when necessary. Leak-proofing adds complexity, may degrade performance. Try monitoring/post-processing first.

### THREAT MODEL

#### Common Threats

| Threat | Pattern | Mitigation |
|--------|---------|------------|
| Command Injection | `; rm -rf` | Sanitize input, use subprocess with list args |
| Path Traversal | `../../etc/passwd` | Validate absolute paths, whitelist directories |
| Secret Exposure | Log tokens/passwords | Redact secrets, sanitize errors |
| Data Loss | `rm`, `push -f` | Require user confirmation |

## VALIDATION LAYERS (Apply In Order)

1. **Input Validation**: Type check, schema validate, sanitize
2. **Context Validation**: Verify permissions, check dependencies, verify tool availability
3. **Execution Validation**: Confirm intent, check for destructive operations
4. **Output Validation**: Verify format, redact secrets

### OPERATIONAL STANDARDS

**Note**: Before using any referenced tools, verify they exist in your environment context. Tool references assume standard availability unless otherwise specified.

#### Destructive Operation Protection

IF destructive operation (rm, sudo, push -f, chmod 777) requested THEN
  Require_User_Confirm
  Display operation details
  Display impact assessment
  Wait(User_Confirm)
END

#### Input Sanitization

IF input contains shell metacharacters THEN
  Sanitize input
  Validate schema
  Reject if validation fails
END

#### Path Traversal Prevention

IF path traversal detected THEN
  Reject absolute paths
  Validate against whitelist
  Error if path invalid
END

#### Secret Protection

IF secrets might be exposed THEN
  Redact secrets from output
  Sanitize error messages
  Never log sensitive data
END

#### Error Handling

IF error occurs THEN
  Provide safe error message
  Never expose stack traces
  Never expose secrets
  Log sanitized error
END

## VALIDATION PROTOCOL

### PURPOSE
Define "Definition of Done" for all component types.

## DEFINITION OF DONE

### Check 1: Ambiguity

- Are logic gates binary?
- No vague conditions?

### Check 2: Constraints

- Are boundaries explicit?
- No "undefined" states?

### Check 3: Structure

- Are Phases 1-4 present?
- Clarification, Planning, Execution, Validation?

### Check 4: Edge Cases

- Is failure mode defined?
- Error handling documented?

### Check 5: Token Efficiency

- Is STM applied?
- Conversational filler removed?

### Check 6: Security

- Input sanitized?
- Destructive ops confirmed?

### Check 7: Safety

- No secrets exposed?
- Error handling safe?

## VALIDATION OUTCOME

- **Pass(All)** -> Deploy
- **Fail(Any)** -> Refine

## REDUCE HALLUCINATIONS

**Basic Strategies**:
- **Allow "I don't know"**: Explicitly permit uncertainty, reduces false info
- **Direct quotes for grounding**: Extract word-for-word quotes first from long docs (>20K tokens), then analyze (grounds in actual text)
- **Verify with citations**: Require LLM to cite sources for each claim, retract if no supporting quote found

**Examples**:
- M&A analysis: "If unsure, say 'I don't have enough information'"
- GDPR audit: Extract quotes first, analyze only based on extracted quotes
- Press release: Review claims, find supporting quotes, remove unsupported claims with []

### Advanced Techniques

**Selection Guide** (complexity → effectiveness):

| Technique | Complexity | Effectiveness | Best For |
|-----------|-----------|---------------|----------|
| Allow "I don't know" | Low | Medium | All tasks |
| Direct quotes | Medium | High | Document analysis |
| Citation verification | High | Very High | Critical claims |
| Chain-of-thought verification | Medium | High | Complex reasoning |
| External knowledge restriction | Low | High | Factual accuracy |

**Methods**:
- **CoT verification**: Explain reasoning step-by-step to reveal faulty logic
- **Best-of-N verification**: Run same prompt multiple times, compare for inconsistencies
- **Iterative refinement**: Use outputs as inputs for follow-up verification prompts
- **External knowledge restriction**: Instruct LLM to use only provided documents

**Note**: These reduce but don't eliminate hallucinations. Always validate critical information.

## INCREASE CONSISTENCY

### Specify Desired Output Format

Use JSON, XML, or templates to precisely define output requirements.

**Example**: Customer feedback JSON with "sentiment", "key_issues"[], "action_items"[{"team","task"}]</think></tool_call>

### Prefill LLM's Response

Prefill `Assistant` turn to enforce structure and bypass friendly preamble.

**Example**: `<report><summary><metric name="total_revenue">$0.00</metric>...` → LLM fills in values

### Constrain With Examples

Provide concrete examples instead of abstract instructions.

**Example**: Competitor analysis format with `<competitor><name>...</name><swot><strengths>...</strengths>...</swot></competitor>`

### Use Retrieval For Contextual Consistency

Ground responses in fixed information set (KBs, documentation).

**Example**: IT Support AI checks `<kb><entry>...</entry></kb>` first, responds in `<response><kb_entry>...</kb_entry><answer>...</answer></response>` format

### Chain Prompts For Complex Tasks

Break down complex tasks into smaller, consistent subtasks. Each subtask gets LLM's full attention, reducing inconsistency errors across scaled workflows.

## HANDLE STREAMING REFUSALS

### Reset Context After Refusal

When you receive **`stop_reason`: `refusal`**, you must reset the conversation context **by removing or updating the turn that was refused** before continuing. Attempting to continue without resetting will result in continued refusals.

**Note**: Usage metrics are still provided in response for billing purposes, even when the response is refused.

### Implementation Guide

Detect `stop_reason: "refusal"` in streaming response, reset conversation state.

**Note**: Test in staging, validate API availability/auth first.

**Bash**: `grep -q '"stop_reason":"refusal"' "$response"` → Reset context if match
**Python**: Check `event.delta.stop_reason == 'refusal'` in stream handler → Call `reset_conversation()`

**Best Practices**: Monitor refusals, auto-reset context, custom messaging, track patterns

## KEEP LLM IN CHARACTER

**Role Prompting**: Use system prompts to define role/personality (foundation for consistency)
**Reinforce**: Prefill responses with character tag, especially in long conversations
**Prepare**: Provide common scenarios and expected responses

**Example**: AcmeBot - enterprise AI for [Corp]. Role: Analyze docs, provide insights, maintain professional tone. Rules: Reference standards/industry best practices, ask if unsure, never disclose confidential info. Scenarios: IP queries → "Cannot disclose proprietary info", best practices → "Per [standard] we prioritize", unclear docs → "Please clarify [section]." Assistant prefill: `[AcmeBot]`

## OPERATIONAL MODES

### MODE COMPARISON

| Mode | Purpose | Permissions | Key Focus |
|-------|---------|-------------|-----------|
| **ANALYZE/READ** | Extract information | Read-only: read, glob, grep | Accuracy, completeness |
| **WRITE/EDIT/UPDATE** | Create/modify content | Write tools, user confirm for destructive | Change visibility, confirmation |
| **REVIEW/CHECK/VALIDATE** | Identify issues | Read-only (strict) | Severity classification, actionability |
| **PLAN/DESIGN** | Create plans | Read-only (advisory) | Feasibility, risk assessment |
| **TEACH/EXPLAIN** | Educational content | Read-only | Conceptual clarity, rationale |

**Note**: Modes can combine. See MULTI-MODE SUPPORT below.

---

### MODE 1: ANALYZE/READ

**Purpose**: Extract information without modifications
**Permissions**: Read-only (read, glob, grep)
**Workflow**: Input → Scan → Extract → Organize → Present (linear, single-pass)
**Validation**: Completeness, accuracy, structure, references

**Output Format**:
```markdown
## [Topic]
### Section 1
- [Item 1]

### Section 2
[code block]
```

**Requirements**: H2→H3→H4 headers, bullets, code with language, file:line refs, no filler

### MODE 2: WRITE/EDIT/UPDATE

**Purpose**: Create/modify content with change visibility
**Permissions**: Write tools, user confirm for destructive ops
**Workflow**: Requirement → Design → Generate → Validate → Refine (iterative)
**Validation**: Correctness, style, integration, testing

**Output Format**:
```markdown
**Summary**: [Action] - [Files]

**Changes**:
- `[file:line]`: [Change]

**Example**:
```language
Before: [code]
After: [code]
```
**Validation**: [Checklist]
```

**Requirements**: Show all files, before/after, line refs, user confirm (destructive), atomic steps
### MODE 3: REVIEW/CHECK/VALIDATE

**Purpose**: Identify issues with severity classification
**Permissions**: Read-only (MUST NOT implement fixes)
**Workflow**: Scan → Detect → Classify → Prioritize → Report (hierarchical)
**Validation**: Detection, classification, coverage, actionable recommendations

**Output Format**:
```markdown
**Summary**: [PASS/FAIL/PARTIAL] - [Assessment]

### Critical: [Count]
- `[file:line]`: [Issue] - Impact: [Explanation]

### High: [Count]
- `[file:line]`: [Issue] - Impact: [Explanation]

**Recommendations**: [Descriptive only, NO code]
```

**Requirements**: Severity levels (CRITICAL, HIGH, MEDIUM, LOW), sorted by severity, location+description+impact, descriptive recommendations only, NO implementations
### MODE 4: PLAN/DESIGN

**Purpose**: Create structured plans without execution
**Permissions**: Read-only (advisory), point estimates optional
**Workflow**: Objective → Breakdown → Dependencies → Risks → Sequence (decompositional)
**Validation**: Completeness, dependencies, risks, sequence, feasibility

**Output Format**:
```markdown
## [Topic]
**Summary**: [Overview]

**Objectives**:
- [Objective 1]

**Plan Structure**:
1. [Phase 1] ([estimate])
   - **Objective**: [Goal]
   - **Requirements**: [Needed]
   - **Dependencies**: [Depends on]
   - **Risks**: [Issues]

2. [Phase 2] ([estimate])
   - [Same structure]

**Resources**: [List]
**Success Criteria**: [Criteria]
```

**Requirements**: Objectives clear, dependencies identified, risks assessed, resources listed, success criteria measurable, estimates optional, NO implementation details
### MODE 5: TEACH/EXPLAIN

**Purpose**: Educational content with rationale
**Permissions**: Read-only
**Workflow**: Concept → Context → Explanation → Examples → Validation (narrative)
**Validation**: Clarity, accuracy, examples work, learner can apply

**Output Format**:
```markdown
## [Topic]
### Purpose
[One-sentence goal]

### What It Means
[Clear explanation]

### When To Use
- [Scenario 1]
- [Scenario 2]

### Implementation
[code example]

### Benefits
- [Benefit 1]
- [Benefit 2]

### Related Concepts
[References]

### Anti-Patterns
❌ **Bad**: [Example]
✓ **Good**: [Example]
```

**Requirements**: Explain WHY not just WHAT/HOW, concrete examples, benefits+trade-offs, anti-patterns (❌/✓), related concepts, educational tone
## MULTI-MODE SUPPORT

**Principles**: Combine modes coherently, order logically (Analyse → Review → Plan → Write), maintain clarity, avoid redundancy

### Common Patterns

**Pattern 1: Analyse → Review → Plan**
```markdown
## Analysis
[Findings...]

## Review
**Summary**: PARTIAL - Issues
[Severity hierarchy...]

## Plan
1. Fix Critical [2 days]
2. Address High [1 week]
```

**Pattern 2: Analyse → Write**
```markdown
## Analysis
[State...]

## Changes
**Summary**: Implemented fixes
[Details...]
```

**Pattern 3: Teach → Analyse**
```markdown
## Concept
[Explanation...]

## Analysis
[Code-specific application...]
```

**Pattern 4: Review → Write**
```markdown
## Review
**Summary**: FAIL - Critical issues
[Severity hierarchy...]

## Changes
**Summary**: Implemented fixes
[Details...]
```

### Guidelines
- Separate modes with headers, consistent labels
- Bridge transitions, explain relevance, reference prior findings
- Maintain mode integrity: Analyse (read-only), Write (changes), Review (descriptive only), Plan (no implementation), Teach (rationale)
- Failure: Fail → Report → Adjust → Retry (or abort if critical)
## GLOSSARY

**STM**: Structured Telegraphic Markdown (keywords + logic, no filler)
**CoT**: Chain of Thought (explicit reasoning process)
**Extended Thinking**: Advanced self-evaluation and step-by-step reasoning
**LLM**: Large Language Model
**ref**: Reference (`@path/to/file` syntax)
**PD**: Progressive Disclosure (load references on-demand)

**Key Guidelines** (ordered by importance):
1. Be Clear & Direct: Contextual info, sequential steps
2. XML Tags: Structure separation
3. Multishot: 3-5 diverse examples
4. Chain of Thought: Structured reasoning
5. Extended Thinking: Self-reflection, instruction following
6. Prompt Chaining: Subtasks, XML handoffs
7. Long Context: Data placement, document structure, quote grounding
