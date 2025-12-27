---
name: prompt-guidelines
description: Mandatory protocols for high-fidelity, token-efficient AI prompts. Provides specialized guidance for creating Skills, Agents, and Commands via progressive disclosure. Use when writing system instructions, refactoring agent configs, or designing new commands. Triggers: "write a prompt", "create a skill", "design an agent", "new command".
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
- **Schema**: `<rules>`, `<context>`, `<user_input>`, `<examples>`.

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

### Anti-Examples (Negative)
- **Directive**: Define failure states.
- **Action**: Show common error -> Label "INCORRECT" -> Explain fix.

### Reference Anchoring
- **Directive**: Bind terms to definitions.
- **Instruction**: "Ref [Term] == [Definition_Block]."

## ROUTING (Progressive Disclosure)
- **Constraint**: GLOBAL RULES (Above) == Mandatory for ALL tasks.
- **Task** == Create/Edit Skills -> Read: `./references/skills.md`
- **Task** == Create/Edit Agents -> Read: `./references/agents.md` (See Agent Orchestration Patterns)
- **Task** == Create/Edit Commands -> Read: `./references/commands.md`
- **Routing Patterns**: `IF [Condition] → [Action] ELSE [Fallback]`, `Check → Validate → Execute`, `Task_Type → Component_Reference → Execution_Path`
