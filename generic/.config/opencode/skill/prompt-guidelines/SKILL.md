---
name: prompt-guidelines
description: >-
  Mandatory protocols for high-fidelity, token-efficient AI prompts. Provides specialized guidance for creating, editing, verifying, reviewing, and checking compliance of Skills, Agents, and Commands via progressive disclosure. Use when writing system instructions, refactoring agent configs, designing new commands, or validating existing components. Triggers: "write a prompt", "create a skill", "edit a skill", "verify a skill", "review a skill", "check skill compliance", "design an agent", "edit an agent", "verify an agent", "review an agent", "check agent compliance", "new command", "edit command", "verify command", "review command", "check command compliance".
---

# PROMPT_ENGINEERING_PROTOCOLS

## CORE PRINCIPLE
**Rule**: Mode frameworks are UNIVERSAL design patterns affecting ALL component behavior (not just output format). Once mode is determined, it affects: cognitive process, workflow, validation, interaction, context handling, output format, AND routing to mode-specific references. Components MUST detect mode and switch entire behavioral framework accordingly.

## SYNTAX & FORMATTING
### Structured Telegraphic Markdown (STM)
- **Rule**: Content == Keywords + Logic. Remove conversational filler.
- **Constraint**: Clarity > Brevity. Ambiguity == FALSE.

### Logic Notation
- **Directive**: Use symbols for relationships.
- **Map**: `->` (Causes), `=>` (Implies), `!=` (Not), `&&` (AND), `||` (OR).

### Variable Binding
- **Mode A (Structured)**: Enforce strict schema (JSON/YAML). "Keys == Immutable."
- **Mode B (Conversational)**: Enforce Tone/Style. "Explanation == Concise && Technical."
- **Constraint**: Define Output_Mode explicitly.

## STRUCTURAL MANDATES (The "Brain" Architecture)
- **Rule**: Generated prompts MUST include these execution phases:
### Phase 1: Clarification (Ask)
- **Logic**: Ambiguity > 0 -> Stop && Ask.
- **Instruction**: "If requirements != complete -> List(Questions) -> Wait(User_Input)."

### Phase 2: Planning (Think)
- **Logic**: Task -> Plan -> Approval.
- **Instruction**: "Propose Plan (Steps + Files + Impacts). Wait(User_Confirm) IF impact > Low."

### Phase 3: Execution (Do)
- **Logic**: Step_1 -> Verify -> Step_2.
- **Instruction**: "Execute atomic steps. Validate result after EACH step."

### Phase 4: Validation (Check)
- **Logic**: Result -> Checklist -> Done.
- **Instruction**: "Run Final_Checklist. If Fail -> Self_Correct."

## COGNITIVE PROCESS
### Chain of Thought (CoT)
- **Directive**: Mandate planning phase.
- **Instruction**: "Plan steps && checks before output. Document reasoning process."

### The Critic (Role-Based)
- **Directive**: Force self-correction.
- **Instruction**: "Assume role 'QA_Critic'. If Draft != Rules -> Rewrite."

### Output Priming
- **Directive**: Force entry point.
- **Action**: End prompt with expected start of response (e.g., `Here is the JSON: {`).

## OUTPUT FORMATS & OPERATIONAL MODES

### Mode Detection Protocol
- **Rule**: User Intent -> Mode Classify -> Load Behavioral Framework -> Switch ALL Dimensions
- **Detection Logic**: Keyword matching + Context analysis
- **Behavioral Switch**: Once mode detected, apply ALL 7 dimensions (cognitive, workflow, validation, interaction, success, context, output) - NOT just output format
- **Routing**: Use determined mode for conditional logic and mode-specific reference loading
- **Universal**: Applies to ALL operations

### 5 Operational Modes

1. **Analyse/Read Mode** - Informational responses without modifications
   - Intent: Provide information, extract data, report findings
   - Keywords: "what", "how", "explain", "analyze", "list", "show", "find"
   - Permissions: Read-only (read, glob, grep)
   - Output Focus: Clarity, hierarchy, quick scanning

2. **Write/Edit/Update Mode** - Content creation or modification
   - Intent: Create, write, generate, update, edit, add content
   - Keywords: "create", "write", "generate", "update", "edit", "add", "build"
   - Permissions: Write/edit tools + User confirmation for destructive ops
   - Output Focus: Changes, confirmation, before/after comparisons

3. **Review/Check/Validate Mode** - Compliance with severity
   - Intent: Review, check, audit, validate, analyze for compliance
   - Keywords: "review", "check", "audit", "validate", "compliance", "analyze issues"
   - Permissions: Read-only (strictly enforced)
   - Output Focus: Prioritized issues, severity classification

4. **Plan/Design Mode** - Advisory planning without execution
   - Intent: Plan, design, structure, breakdown, estimate
   - Keywords: "plan", "design", "structure", "breakdown", "estimate", "architecture"
   - Permissions: Read-only (advisory only, no execution)
   - Output Focus: Structured plans with objectives, dependencies, risk assessment

5. **Teach/Explain Mode** - Educational content with rationale
   - Intent: Teach, explain, guide, tutorial, learn
   - Keywords: "teach", "explain", "guide", "tutorial", "learn", "how does X work"
   - Permissions: Read-only
   - Output Focus: Rationale, examples, best practices, anti-patterns

### Multi-Mode Support
- Prompts can activate multiple modes simultaneously
- Design output formats to combine modes when needed
- Maintain clarity when presenting multi-mode outputs
- Order modes logically (e.g., Analyse → Review → Plan → Write)

### How to Detect and Apply Modes
**Step 1: Keyword Analysis**
- Scan user input for mode keywords (see each mode's keyword list)
- Example: "review", "check", "audit" → REVIEW mode

**Step 2: Intent Classification**
- Match keywords to mode purpose (information, creation, review, planning, teaching)
- Example: "What is X?" → Analyse mode (informational)

**Step 3: Behavioral Framework Application**
- Once mode detected, switch entire behavioral approach:
  - Cognitive: How to think about task
  - Workflow: How to execute steps
  - Validation: How to verify results
  - Interaction: How to engage user
  - Context: How to manage information
  - Output: How to present results

**Step 4: Conditional Logic & Routing**
- Use mode for behavior control (IF mode == review THEN read-only)
- Use mode for reference loading (IF creating skill THEN load @skills.md)
- Mode drives entire component behavior, not just output format

## OPERATIONAL MODE FRAMEWORKS

### MODE 1: ANALYSE/READ

**Behavioral Integration**: This mode requires READ-ONLY behavior. NO write/edit tools allowed. Single-pass workflow. No iteration. Query-based interaction.

#### Cognitive Process (Extractive)
- **Mental Model**: What exists? What patterns? What relationships?
- **Approach**: Pattern recognition, information synthesis, structural analysis
- **Thought Process**: Scan → Extract → Organize → Present
- **Example**: "Scanning codebase for API endpoints. Found 15 REST endpoints. Grouped by resource type. Presenting in hierarchical format."

#### Workflow Structure (Linear)
```
Input → Scan → Extract → Organize → Validate → Present
```
- Single pass through information
- No iteration or refinement
- Validation: Accuracy and completeness only

#### Validation Framework (Accuracy)
- **Completeness**: All relevant information included?
- **Accuracy**: Information is correct?
- **Structure**: Organized logically?
- **References**: Citations accurate (file:line)?

#### Interaction Patterns (Query-Based)
- **Style**: One-shot (query → answer)
- **User Provides**: What they want to know
- **LLM Provides**: Information only
- **Confirmation**: Not needed
- **Example**: User: "What endpoints exist in this API?" LLM: [Lists 15 REST endpoints]

#### Success Criteria (Information Completeness)
- All requested information present
- Information is accurate and well-organized
- References included where applicable
- Example: "Done: 15 API endpoints listed, grouped by resource, with file:line references"

#### Context Handling (Consumption)
- Load multiple files, synthesize information
- Load all relevant context before responding
- Progressive Disclosure: Load references on demand
- Example: "Loading API routes, controllers, models. Synthesizing endpoint information."

#### Output Format
```markdown
## [Analysis Topic]

### Section 1
- [Item 1]
- [Item 2]

### Section 2
[code snippet with language annotation]

[Optional: Next Steps / Recommendations]
```

---

### MODE 2: WRITE/EDIT/UPDATE

**Behavioral Integration**: Write/edit tools allowed. Multi-step iterative workflow with self-correction. Confirmatory interaction (ask before destructive operations). Atomic execution with validation.

#### Cognitive Process (Generative)
- **Mental Model**: What needs to exist? How do I create it?
- **Approach**: Problem decomposition, synthesis, refinement
- **Thought Process**: Understand requirement → Design solution → Generate → Validate → Refine
- **Example**: "User wants authentication. I'll create LoginController with JWT. Implement token generation. Validate with tests. Refine error handling."

#### Workflow Structure (Iterative)
```
Requirement → Design → Generate → Validate → Refine → Finalize
```
- Multiple refinement cycles
- Self-correction during generation
- Validation: Functionality, correctness, style

#### Validation Framework (Functional)
- **Correctness**: Does it solve the problem?
- **Style**: Does it follow conventions?
- **Integration**: Does it integrate with existing code?
- **Testing**: Does it pass tests?

#### Interaction Patterns (Confirmatory)
- **Style**: Multi-step with confirmations
- **User Provides**: Requirements
- **LLM Provides**: Proposed changes → User confirms → Execute
- **User Confirmation Required**: For destructive operations
- **Example**: User: "Add authentication." LLM: "I'll create LoginController and add JWT. OK?" User: "Yes." LLM: "Done. Files created."

#### Success Criteria (Functional Implementation)
- Requirement is fulfilled (code works, solves the problem)
- Changes are documented
- No unintended side effects
- Integration is clean
- Example: "Done: Authentication implemented, tested, documented. Files modified: LoginController (created), routes (updated), User model (updated)."

#### Context Handling (Integration)
- Read existing code, integrate changes
- Load patterns, best practices before writing
- Progressive Disclosure: Load references as needed
- Example: "Loading existing authentication code. Loading JWT patterns. Integrating new endpoint with existing structure."

#### Output Format
```markdown
**Summary**: [Action taken] - [Files affected]

**Changes**:
- `[file:line]`: [Change description]
- `[file:line]`: [Change description]

**Example Change**:
```language
Before:
[original code]

After:
[modified code]
```

**Validation**: [Checklist passed]
```
Requirement → Design → Generate → Validate → Refine → Finalize
```
- Multiple refinement cycles
- Self-correction during generation
- Validation: Functionality, correctness, style

#### Validation Framework (Functional)
- **Correctness**: Does it solve the problem?
- **Style**: Does it follow conventions?
- **Integration**: Does it integrate with existing code?
- **Testing**: Does it pass tests?

#### Interaction Patterns (Confirmatory)
- **Style**: Multi-step with confirmations
- **User Provides**: Requirements
- **LLM Provides**: Proposed changes → User confirms → Execute
- **UC Required**: For DO
- **Example**: User: "Add authentication." LLM: "I'll create LoginController and add JWT. OK?" User: "Yes." LLM: "Done. Files created."

#### Success Criteria (Functional Implementation)
- Requirement is fulfilled (code works, solves problem)
- Changes are documented
- No unintended side effects
- Integration is clean
- Example: "Done: Authentication implemented, tested, documented. Files modified: LoginController (created), routes (updated), User model (updated)."

#### Context Handling (Integration)
- Read existing code, integrate changes
- Load patterns, best practices before writing
- PD: Load references as needed
- Example: "Loading existing authentication code. Loading JWT patterns. Integrating new endpoint with existing structure."

#### OF
```markdown
**Summary**: [Action taken] - [Files affected]

**Changes**:
- `[file:line]`: [Change description]
- `[file:line]`: [Change description]

**Example Change**:
```language
Before:
[original code]

After:
[modified code]
```

**Validation**: [Checklist passed]
```

---

### MODE 3: REVIEW/CHECK/VALIDATE

**Behavioral Integration**: READ-ONLY enforced. NO write/edit/bash execution allowed. Hierarchical workflow. Advisory interaction. Exhaustive context loading. Severity-based prioritization.

#### Cognitive Process (Evaluative)
- **Mental Model**: What's wrong? How serious? What should change?
- **Approach**: Comparison, classification, severity assessment
- **Thought Process**: Scan → Detect → Classify → Prioritize → Recommend
- **Example**: "Found SQL injection. Classified as CRITICAL. High impact. Recommend parameterized queries."

#### Workflow Structure (Hierarchical)
```
Scan → Detect → Classify → Prioritize → Report → Recommend
```
- Hierarchical organization (severity levels)
- Classification of findings
- Validation: No misses, correct severity, accurate recommendations

#### Validation Framework (Compliance)
- **Detection**: Are all issues found?
- **Classification**: Is severity correct?
- **Coverage**: Are all categories checked?
- **Recommendations**: Are they actionable?

#### Interaction Patterns (Advisory)
- **Style**: One-shot with optional clarification
- **User Provides**: What to review
- **LLM Provides**: Findings + recommendations
- **Optional**: User asks for clarification on specific issues
- **Example**: User: "Review this code." LLM: "Found 3 SQL injections (CRITICAL). Recommendations: Use parameterized queries." User: "Which lines?" LLM: "UserController:42, 56, 78."

#### Success Criteria (Comprehensive Analysis)
- All categories checked
- All issues found and classified
- Severity assessment is accurate
- Recommendations are actionable
- Example: "Done: Security review complete. 3 CRITICAL issues found, 2 HIGH. All endpoints checked. Severity classified. Recommendations provided."

#### Context Handling (Evaluation)
- Read code, compare against standards
- Load compliance rules, best practices
- Progressive Disclosure: Exhaustive loading for review mode
- Example: "Loading OWASP Top 10. Comparing all endpoints against injection vulnerabilities."

#### Output Format
```markdown
**Summary**: [PASS/FAIL/PARTIAL] - [Overall assessment]

### Critical Issues: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

### High Priority: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

### Medium Priority: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

### Low Priority: [Count]
- [file:line] - [Issue Description] - Impact: [Explanation]

**Recommendations**: [Descriptive corrections only, NO implementations]
```

---

### MODE 4: PLAN/DESIGN

**Behavioral Integration**: Read-only advisory only. NO implementation allowed. Decomposition workflow. Collaborative interaction. Risk assessment. Success criteria definition.

#### Cognitive Process (Strategic)
- **Mental Model**: What's the goal? What's the path? What are the risks?
- **Approach**: Goal decomposition, dependency mapping, risk assessment
- **Thought Process**: Understand objective → Break down → Map dependencies → Assess risks → Sequence
- **Example**: "Goal: Microservices migration. Break into phases. Phase 1: Identify boundaries. Phase 2: Design communication. Assess risks: Service coupling, data consistency. Sequence phases with dependencies."

#### Workflow Structure (Decomposition)
```
Objective → Breakdown → Dependency Map → Risk Assessment → Sequence → Validate
```
- Decomposition into smaller units
- Mapping dependencies
- Assessing feasibility
- Validation: Completeness, feasibility, risk coverage

#### Validation Framework (Feasibility)
- **Completeness**: Are all steps included?
- **Dependencies**: Are they correctly identified?
- **Risks**: Are significant risks addressed?
- **Sequence**: Is ordering logical?
- **Feasibility**: Is it achievable with given resources?

#### Interaction Patterns (Collaborative)
- **Style**: Multi-step with refinement
- **User Provides**: Objective
- **LLM Provides**: Draft plan → User refines → Finalize
- **Iterative**: Back-and-forth refinement
- **Example**: User: "Plan migration." LLM: "I propose 3 phases. Phase 1: Service discovery (2 weeks)." User: "Make it 1 week." LLM: "Risk: Incomplete boundaries." User: "Accept risk." LLM: "Updated plan: 1 week, note risk."

#### Success Criteria (Feasible Roadmap)
- All steps identified
- Dependencies mapped correctly
- Risks assessed and mitigated
- Timeline is realistic
- Success criteria are measurable
- Example: "Done: Migration plan created. 3 phases, dependencies mapped, risks assessed. Timeline: 6 weeks. Success criteria: Service boundaries defined, API contracts documented."

#### Context Handling (Decomposition)
- Read codebase, understand structure
- Load architecture patterns, best practices
- Progressive Disclosure: Load as needed during planning
- Example: "Loading monolith structure. Understanding service boundaries. Loading microservices patterns."

#### Output Format
```markdown
## [Plan/Design Topic]

**Summary**: [Brief overview]

**Objectives**:
- [Objective 1]
- [Objective 2]

**Plan Structure**:
1. [Phase 1] ([Point estimate if applicable])
   - **Objective**: [Goal]
   - **Requirements**: [What's needed]
   - **Dependencies**: [What this depends on]
   - **Risks**: [Potential issues]
   - [Subtasks if applicable]

2. [Phase 2] ([Point estimate if applicable])
   - **Same structure]

**Resources Required**:
- [Resource 1]
- [Resource 2]

**Success Criteria**:
- [Criterion 1]
- [Criterion 2]
```

---

### MODE 5: TEACH/EXPLAIN

**Behavioral Integration**: Read-only educational focus. Narrative workflow. Q&A interaction. Conceptual abstraction. Rationale emphasis (WHY not just WHAT/HOW). Anti-pattern demonstration.

#### Cognitive Process (Pedagogical)
- **Mental Model**: What's the concept? How do I explain it? Will they understand?
- **Approach**: Conceptualization, analogy construction, example generation
- **Thought Process**: Identify concept → Determine audience → Construct explanation → Provide examples → Validate comprehension
- **Example**: "Explaining SOLID Single Responsibility. Use God Object example. Show separation. Explain benefits: testability, maintainability. Provide code example with bad vs good approach."

#### Workflow Structure (Narrative)
```
Concept → Context → Explanation → Examples → Validation → Application
```
- Narrative progression
- Building understanding incrementally
- Validation: Comprehensibility, accuracy, practical applicability

#### Validation Framework (Comprehensibility)
- **Clarity**: Is explanation understandable?
- **Accuracy**: Is technical information correct?
- **Examples**: Do examples work? Are they clear?
- **Application**: Can learner apply concept?

#### Interaction Patterns (Q&A)
- **Style**: One-shot explanation with follow-up Q&A
- **User Provides**: Concept to learn
- **LLM Provides**: Explanation + examples
- **Optional**: User asks follow-up questions
- **Example**: User: "Explain SOLID Single Responsibility." LLM: [Full explanation with examples]. User: "How do I identify God Objects?" LLM: "Look for classes with multiple reasons to change, handle multiple concerns."

#### Success Criteria (Comprehensible Transfer)
- Concept is clearly explained
- Examples demonstrate concept
- Learner can apply concept
- Common misconceptions addressed
- Example: "Done: SOLID Single Responsibility explained. Concept clear with God Object example. Code examples compile. User can identify violations."

#### Context Handling (Abstraction)
- Extract examples from codebase if available
- Load best practices, patterns
- Progressive Disclosure: Load examples as needed
- Example: "Loading SOLID principles. Extracting God Object example from codebase if available."

#### Output Format
```markdown
## [Topic/Concept]

### Purpose
[One-sentence description of what this achieves]

### What It Means
[Explanation of concept in clear terms]

### When to Use
- [Scenario 1]
- [Scenario 2]
- [Scenario 3]

### Implementation
[code example]

### Benefits
- [Benefit 1]
- [Benefit 2]
- [Benefit 3]

### Related Concepts
[References or links]

### Anti-Patterns
❌ **Bad Practice**: [Example of what NOT to do]

✓ **Good Practice**: [Example of correct approach]
```

---

### MULTI-MODE COMBINATIONS

#### Common Patterns
1. **Analyse → Review → Plan**
   - Comprehensive analysis with recommendations
   - Example: Codebase analysis → Security review → Remediation plan

2. **Analyse → Write**
   - Analysis followed by implementation
   - Example: Architecture analysis → Refactoring implementation

3. **Teach → Analyse**
   - Educational explanation with analysis
   - Example: Design pattern explanation → Codebase pattern analysis

4. **Review → Write**
   - Review findings then implement fixes
   - Example: Code review → Bug fixes

#### Guidelines for Multi-Mode Outputs
- Clearly separate each mode with headers
- Use consistent mode labels
- Ensure transitions between modes are logical
- Avoid redundancy across modes
- Each mode section should stand alone

---

### OUTPUT FORMAT DESIGN PROTOCOLS (Template Reference)

#### For Skill/Agent Creators
```markdown
## OUTPUT FORMAT GUIDELINES

### [Mode Name]

**Purpose**: [One-sentence description of what this output achieves]

**Structure**:
```
[Exact output format template with placeholders]
```

**Requirements**:
- [Requirement 1]
- [Requirement 2]

**Validation**:
- [Check 1]
- [Check 2]
```

#### Domain-Specific Guidelines
- **Rule**: Domain-specific skills/agents MUST design output formats tailored to their domain
- **Examples**: api-engineering (REST endpoints), database-engineering (schemas), security-engineering (vulnerability reports)
- **See**: `@references/output-format-design.md` for comprehensive examples

## OPERATIONAL STANDARDS (Universal)
### Component Declaration
- **Rule**: Explicitly declare ALL dependencies + Context.
- **Logic**: Requirement(Tool|Agent|Skill) -> List(Name) + Link(Context/Ref).
- **Goal**: Component + Context => Enable(Progressive_Disclosure).
- **Constraint**: Implicit assumption of tools == FORBIDDEN.

### Environment Awareness
- **Rule**: Action(Create|Edit) -> `scan(~/.config/opencode/)` -> Verify(Dependencies).
- **Constraint**: Assumption == FALSE. Reference ONLY existing components.

### Reference Syntax
- **Syntax**: `Ref == @path/to/file`.
- **Constraint**: Markdown Links `[text](path)` == FORBIDDEN.

### Skill Loading Syntax
- **In Skill Reference Files**: Use `@` syntax for internal references
  - Example: `@references/commit-message.md` within git-workflow skill
- **In Commands**: Use `skill(skill_id)` to load and execute
  - **Load**: `skill(git-workflow)` -> Load instructions and execute
  - **Example**: `skill(git-workflow)` (not `@skills/git-workflow`)
- **Constraint**: Never use `@skills/name` in commands - always use skill() function

### Documentation Priority
- **Logic**: Need_Docs -> `tool(context7)` -> Fallback(Search).

### Security & Validation (MANDATORY)
- **Threat Model**: Assume Input == Malicious. Always validate.
- **Rule**: Destructive operation (rm, sudo, push -f, chmod 777) -> User confirmation.
- **Logic**: `Input -> Sanitize() -> Validate(Safe) -> Execute`.
- **Input Sanitization**: Strip shell escapes, command injection patterns, path traversal.
- **Output Validation**: Verify output format == expected schema.
- **Error Handling**: Define failure modes. Never expose secrets in errors.
- **Security First**: Every prompt MUST include threat modeling and validation steps.

### Context Efficiency
- **Rule**: `Main_File < 500_lines`. Details -> `@references/`.
- **Principle**: Progressive Disclosure.

### Glossary Standard (Universal)
- **Position**: GLOSSARY section MUST be at BOTTOM of file
- **Rule**: Glossary reduces token usage. Define ONLY acronyms/refs/word shortenings appearing ≥3 times AND may cause confusion.
- **Purpose**: Use abbreviations repeatedly in document instead of full terms. NOT for common English words.
- **When to Create**: Acronyms/refs/shortenings ≥3 occurrences in document AND domain-specific OR ambiguous.
- **Per-File**: Each `.md` defines its own glossary for its abbreviations/refs.
- **No Redundancy**: Parent definitions cascade down. Child files use WITHOUT redefinition.
- **Example**: LLM defined here → references/skills.md uses WITHOUT redefinition.
- **Example**: New acronym "GraphQL" in api-engineering/SKILL.md → MUST define there.

## SECURITY FRAMEWORK (Universal)
### Core Principles
- **Zero Trust**: Assume all input is malicious until validated
- **Least Privilege**: Execute with minimal required permissions
- **Fail Safe**: Default to safe state on error
- **Defense in Depth**: Multiple validation layers

### Common Threats
| Threat | Pattern | Mitigation |
|--------|---------|------------|
| Command Injection | `; rm -rf` | Sanitize input, use subprocess with list args |
| Path Traversal | `../../etc/passwd` | Validate absolute paths, whitelist directories |
| Secret Exposure | Log tokens/passwords | Redact secrets, sanitize errors |
| Data Loss | `rm`, `push -f` | Require user confirmation |

### Validation Layers (Apply in Order)
1. **Input Validation**: Type check, schema validate, sanitize
2. **Context Validation**: Verify permissions, check dependencies
3. **Execution Validation**: Confirm intent, check for destructive operations
4. **Output Validation**: Verify format, redact secrets

## VALIDATION PROTOCOL (Definition of Done)
- **Check 1**: Ambiguity? (Are logic gates binary?)
- **Check 2**: Constraints? (Are boundaries explicit?)
- **Check 3**: Structure? (Are Phases 1-4 present?)
- **Check 4**: Edge Cases? (Is failure mode defined?)
- **Check 5**: Token Efficiency? (Is STM applied?)
- **Check 6**: Security? (Input sanitized? Destructive ops confirmed?)
- **Check 7**: Safety? (No secrets exposed? Error handling safe?)
- **Result**: Pass(All) -> Deploy. Fail(Any) -> Refine.

## ANCHORING
### Few-Shot (Positive)
- **Directive**: Provide labeled examples using markdown code blocks.
- **Structure**: ```language
Content
```
- **Purpose**: Demonstrate correct implementation patterns

```markdown
---
description: Example description
---

Step 1: Action
Step 2: Verify
```

### Anti-Examples (Negative)
- **Directive**: Define failure states.
- **Action**: Show common error -> Label "INCORRECT" -> Explain fix.
- **Structure**: Use markdown code blocks for clarity

```markdown
❌ INCORRECT: Poor example structure
Bad pattern example

✓ CORRECT: Clear markdown formatting
Good pattern example
```

### Reference Anchoring
- **Directive**: Bind terms to definitions.
- **Instruction**: "Ref [Term] == [Definition_Block]."

## MULTI-DIMENSIONAL ROUTING FOR PROGRESSIVE DISCLOSURE

### Core Concept
**Rule**: Routing decisions are NOT based on a single dimension. Combine mode + Intent + Context + Keywords for intelligent Progressive Disclosure.

### Four Routing Dimensions

#### 1. Mode-Based Routing
- **Purpose**: Determine Behavioral Framework (cognitive, workflow, validation, interaction)
- **Detection**: Mode keywords (analyze, create, review, plan, teach)
- **Routing**: Load mode-specific Behavioral Framework
- **Example**: Detected "review" → Apply review mode Behavioral Framework → Read references/modes/review.md if exists

#### 2. Intent-Based Routing
- **Purpose**: Load domain-specific or task-specific guidance
- **Detection**: User intent keywords (create skill, design agent, audit security)
- **Routing**: Load intent-specific references
- **Example**: Detected "create skill" → Load references/intents/skill-creation.md or references/skills.md

#### 3. Context-Based Routing
- **Purpose**: Load environment or project-specific patterns
- **Detection**: Project type, existing files, environment variables
- **Routing**: Load context-aware references
- **Example**: Python project detected → Load references/contexts/python-patterns.md

#### 4. Keyword-Based Routing
- **Purpose**: Load specialized knowledge for specific domains
- **Detection**: Domain keywords (SQL injection, SOLID, microservices)
- **Routing**: Load domain expertise references
- **Example**: "SQL injection" detected → Load references/domains/security/sql-injection-mitigation.md

### Combining Dimensions

**Pattern**: `Route(mode) AND Route(Intent) AND Route(Context) AND Route(Keywords)`

**Example 1**: User says "Review SQL injection in this Laravel app"
- mode: Review (keyword "review")
- Intent: Security audit (context "injection")
- Context: Laravel framework (detected from files)
- Keywords: "SQL injection"
- Routing: Review mode Behavioral Framework + references/domains/security/owasp-top10.md + references/contexts/frameworks/laravel-patterns.md

**Example 2**: User says "Create a skill for PDF rotation"
- mode: Write/Edit (keyword "create")
- Intent: Skill creation (keyword "skill")
- Context: File processing (keyword "PDF rotation")
- Routing: Write mode Behavioral Framework + references/skills.md + references/intents/skill-creation.md

### Creating Progressive Disclosure References

#### When to Create Mode-Specific References
- **Use**: When mode Behavioral Framework needs domain-specific adaptation
- **Location**: `references/modes/[mode-name].md`
- **Example**: `references/modes/review.md` for security review extensions

#### When to Create Intent-Specific References
- **Use**: When specific intent requires specialized guidance
- **Location**: `references/intents/[intent-name].md`
- **Example**: `references/intents/skill-creation.md` for detailed skill creation workflow

#### When to Create Context-Specific References
- **Use**: When project/environment requires specialized patterns
- **Location**: `references/contexts/[context-name].md`
- **Example**: `references/contexts/python.md` for Python-specific patterns

### Flexible Reference Organization

**Rule**: Reference folder naming is FLEXIBLE. These are RECOMMENDED structures, not requirements.

#### Recommended Directory Structure
```text
skill-name/
├── SKILL.md
├── references/
│   ├── modes/           # Mode-specific behavioral extensions
│   ├── intents/         # Intent-specific workflows
│   ├── contexts/        # Context/environment-specific patterns
│   ├── domains/         # Domain expertise (security, database, etc.)
│   └── schemas/        # Data schemas, API specs
├── templates/          # Output format templates, prompt templates
├── scripts/            # Python/Bash scripts for deterministic tasks
└── assets/             # Logos, icons, file templates
```

#### Alternative: Flat Structure
```text
skill-name/
├── SKILL.md
├── review-mode.md       # Mode-specific at root level
├── skill-creation.md   # Intent-specific at root level
├── python-patterns.md   # Context-specific at root level
└── owasp-top10.md      # Domain-specific at root level
```

### Implementation Guidance

#### Detect Mode (Step 1)
```
Input: "Review SQL injection in this Laravel app"
Scan keywords: "review" → Mode: REVIEW
Apply: Review mode Behavioral Framework (cognitive, workflow, validation, interaction)
```

#### Detect Intent (Step 2)
```
Input: "Review SQL injection in this Laravel app"
Analyze intent: Security audit → INTENT: Security Review
Load: references/domains/security/owasp-top10.md
```

#### Detect Context (Step 3)
```
Input: "Review SQL injection in this Laravel app"
Scan files: Found Laravel routes, controllers, models
Context: Framework: Laravel → Load: references/contexts/frameworks/laravel-patterns.md
```

#### Detect Keywords (Step 4)
```
Input: "Review SQL injection in this Laravel app"
Extract keywords: "SQL injection" → Domain: Security
Load: references/domains/security/sql-injection-mitigation.md
```

#### Combine and Execute (Step 5)
```
Applied: Review mode Behavioral Framework + OWASP Top 10 + Laravel patterns + SQL injection guidance
Result: Context-aware, mode-compliant, domain-expert response
```

### Routing Logic Examples

#### Simple Mode Routing
```markdown
IF mode == "review" THEN
  Apply review mode Behavioral Framework
  IF intent == "security" THEN READ references/domains/security/owasp-top10.md
END
```

#### Multi-Dimensional Routing
```markdown
IF mode == "create" AND intent == "skill" THEN
  Apply write mode Behavioral Framework
  READ references/skills.md
  READ references/intents/skill-creation.md
  IF keyword == "security" THEN READ references/domains/security/security-skill-patterns.md
END
```

#### Context-Aware Routing
```markdown
IF framework == "laravel" THEN
  READ references/contexts/frameworks/laravel-patterns.md
  IF mode == "review" THEN
    Apply review mode Behavioral Framework with Laravel-specific validation
  END
END
```

---

## ROUTING RULES (Progressive Disclosure)

**Note**: For comprehensive multi-dimensional routing guidance, see "MULTI-DIMENSIONAL ROUTING FOR PROGRESSIVE DISCLOSURE" section above.

### Critical Instruction for LLMs
**Rule**: You **MUST** read the specific reference file below **IMMEDIATELY** when the User's intent matches the Task. Do not proceed without this context.

  - **IF** User Intent involves UNCERTAINTY or requests ADVICE on implementation type (e.g., "What should I build?", "Should this be a skill or agent?", "Help me design a prompt") AND does NOT explicitly specify target type (Skill, Agent, Command) with certainty
    - **ACTION** -> READ FILE: `@references/implementation-advisor.md`
    - **WHY**: specialized advisor to evaluate requirements and recommend optimal implementation method (Skill, Agent, Command, Hybrid, or Custom Tool).
    - **PRIORITY**: CRITICAL - Must be evaluated before other options if intent is ambiguous.

  - **IF** User Intent == "Create Skill" OR "Edit Skill" OR "Write Skill" OR "Verify Skill" OR "Review Skill" OR "Check Skill Compliance"
    - **ACTION** -> READ FILE: `@references/skills.md`
    - **WHY**: Contains the strict schema and template for Skills.

  - **IF** User Intent == "Create Agent" OR "Edit Agent" OR "Design Agent" OR "Verify Agent" OR "Review Agent" OR "Check Agent Compliance"
    - **ACTION** -> READ FILE: `@references/agents.md`
    - **WHY**: Contains the Agent Manifest schema and orchestration patterns.

  - **IF** User Intent == "Create Command" OR "Edit Command" OR "New Command" OR "Verify Command" OR "Review Command" OR "Check Command Compliance"
    - **ACTION** -> READ FILE: `@references/commands.md`
    - **WHY**: Contains the Command definition schema and execution logic.

  - **Constraint**: GLOBAL RULES (Above) == Mandatory for ALL tasks.

### Output Format Routing
- **Rule**: ALWAYS apply mode Behavioral Framework based on detected mode(s)
- **Detection Process**:
  1. Parse user input for mode keywords (see each mode's keyword list)
  2. Analyze context to identify intent (information, creation, review, planning, teaching)
  3. Classify into one or more modes
  4. Load mode-specific Behavioral Framework (ALL 7 dimensions)
- **Behavioral Switch**:
  1. Apply cognitive process (how to think about task)
  2. Apply workflow structure (execution pattern)
  3. Apply validation framework (verification approach)
  4. Apply interaction patterns (how to engage user)
  5. Apply success criteria (completion definition)
  6. Apply context handling (information management)
  7. Apply output format (presentation structure)
- **Mode-Based Routing**:
  - Use determined mode for conditional logic (IF mode == review THEN read-only)
  - Load mode-specific references when needed (e.g., @skills.md when creating skills)
- **Universal**: Applies to ALL operations (skills, agents, commands, prompts)
- **Multi-Mode**: Combine multiple mode Behavioral Frameworks if multiple modes detected
- **Reference**: See "OPERATIONAL MODE FRAMEWORKS" section above for comprehensive guidance on all 7 dimensions per mode

## GLOSSARY

**STM**: Structured Telegraphic Markdown (concise, keyword-driven documentation format)  
**CoT**: Chain of Thought (explicit reasoning/documentation of thought process)  
**LLM**: Large Language Model (generative AI system)  
**JWT**: JSON Web Token (authentication token standard)  
**REST**: Representational State Transfer (API architectural style)  
**SOLID**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion (design principles)  
**ref**: Reference (file path using `@path/to/file` syntax)  

**Glossary Purpose**: Token efficiency. Use abbreviations repeatedly in document instead of full terms. Define ONLY acronyms, reference terms, and word shortenings that may cause confusion or are domain-specific. NOT for common English words (e.g., "pun", "logic", "validate").  

**Glossary Usage** (Universal Guidance for ALL prompts):
- **Position**: GLOSSARY section MUST be at BOTTOM of file
- **Per-File Glossary**: Each `.md` file defines glossary for ITS abbreviations/references
- **No Redundancy**: If term defined in parent SKILL.md → child ref files use WITHOUT redefinition
- **Example**: LLM defined here → references/skills.md uses WITHOUT redefinition
- **Example**: New acronym "GraphQL" in api-engineering/SKILL.md → MUST define there
- **Rule**: Parent definitions cascade down. Child definitions additive ONLY for NEW terms
- **When to Create**: Only when acronyms/references appear ≥3 times in document AND may cause confusion