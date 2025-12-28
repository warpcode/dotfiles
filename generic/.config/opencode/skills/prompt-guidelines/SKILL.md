---
name: prompt-guidelines
description: >-
  Mandatory protocols for high-fidelity, token-efficient AI prompts. Provides specialized guidance for creating, editing, verifying, reviewing, and checking compliance of Skills, Agents, and Commands via progressive disclosure. Use when writing system instructions, refactoring agent configs, designing new commands, or validating existing components. Triggers: "write a prompt", "create a skill", "edit a skill", "verify a skill", "review a skill", "check skill compliance", "design an agent", "edit an agent", "verify an agent", "review an agent", "check agent compliance", "new command", "edit command", "verify command", "review command", "check command compliance".
---

# PROMPT_ENGINEERING_PROTOCOLS

## SYNTAX & FORMATTING
### Structured Telegraphic Markdown (STM)
- **Rule**: Content == Keywords + Logic. Remove conversational filler.
- **Constraint**: Clarity > Brevity. Ambiguity == FALSE.

### Logic Notation
- **Directive**: Use symbols for relationships.
- **Map**: `->` (Causes), `=>` (Implies), `!=` (Not), `&&` (AND), `||` (OR).

### Semantic Enclosure (XML)
- **Directive**: Wrap ALL distinct contexts in semantic tags.
- **Global Schema**: `<rules>`, `<context>`, `<examples>`, `<execution>`, `<example>`.
- **Global Tags**:
  - `<rules>`: Execution phases, logic gates, and procedural instructions
  - `<context>`: Dependencies, threat models, references, and environment setup
  - `<examples>`: Collection of example demonstrations
  - `<execution>`: Main execution steps and operational procedures
  - `<example>`: Individual example block for illustration
- **Component-Specific Tags**: Documented in each component's reference file (@references/skills.md, @references/agents.md, @references/commands.md)

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
- **Instruction**: "Open `<thinking>` tag. Plan steps && checks. Close tag, THEN output."

### The Critic (Role-Based)
- **Directive**: Force self-correction.
- **Instruction**: "Assume role 'QA_Critic'. If Draft != Rules -> Rewrite."

### Output Priming
- **Directive**: Force entry point.
- **Action**: End prompt with expected start of response (e.g., `Here is the JSON: {`).

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
- **Rule**: Destructive_Op(rm, sudo, push -f, chmod 777) -> `User_Confirm`.
- **Logic**: `Input -> Sanitize() -> Validate(Safe) -> Execute`.
- **Input Sanitization**: Strip shell escapes, command injection patterns, path traversal.
- **Output Validation**: Verify output format == expected schema.
- **Error Handling**: Define failure modes. Never expose secrets in errors.
- **Security First**: Every prompt MUST include threat modeling and validation steps.

### Context Efficiency
- **Rule**: `Main_File < 500_lines`. Details -> `@references/`.
- **Principle**: Progressive Disclosure.

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
| Data Loss | `rm`, `push -f` | Require explicit user confirmation |

### Validation Layers (Apply in Order)
1. **Input Validation**: Type check, schema validate, sanitize
2. **Context Validation**: Verify permissions, check dependencies
3. **Execution Validation**: Confirm intent, check for destructiveness
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
- **Directive**: Provide labeled examples wrapped in `<example>`.
- **Structure**: `<example> -> Content -> </example>`
- **Purpose**: Demonstrate correct implementation patterns
- **Constraint**: Use semantic tags, NOT markdown code blocks

<example>
---
description: Example description
---

Step 1: Action
Step 2: Verify
</example>

### Anti-Examples (Negative)
- **Directive**: Define failure states.
- **Action**: Show common error -> Label "INCORRECT" -> Explain fix.
- **Structure**: Use same `<example>` tag format for clarity

<example>
❌ INCORRECT: Using markdown code blocks
```markdown
Example content
```

✓ CORRECT: Using semantic example tags
<example>
Example content
</example>
</example>

### Reference Anchoring
- **Directive**: Bind terms to definitions.
- **Instruction**: "Ref [Term] == [Definition_Block]."

## ROUTING (Progressive Disclosure)
### Critical Instruction for LLMs
**Rule**: You **MUST** read the specific reference file below **IMMEDIATELY** when the User's intent matches the Task. Do not proceed without this context.

  - **IF** User Intent involves UNCERTAINTY or requests ADVICE on implementation type (e.g., "What should I build?", "Should this be a skill or agent?", "Help me design a prompt") AND does NOT explicitly specify a target type (Skill, Agent, Command) with certainty
    - **ACTION** -> READ FILE: `@references/implementation-advisor.md`
    - **WHY**: specialized advisor to evaluate requirements and recommend the optimal implementation method (Skill, Agent, Command, Hybrid, or Custom Tool).
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
