# PROTOCOLS: AGENTS & SUBAGENTS

## PHILOSOPHY
- **Goal**: Eliminate ambiguity. Preserve flexibility.
- **Model**: Task_Understanding -> Capability_Map -> Behavior_Design -> Safety_Integration -> Instruction_Clarity.
- **Mantra**: "Explicit > Implicit. Constrain > Enable. Safe == Default."

## AGENT ARCHITECTURE
### Configuration
- **Format**: `.md` with YAML frontmatter.
- **Fields**:
  - `mode`: `subagent` (Specialist) || `primary` (Generalist).
  - `temperature`: `0.0-0.2` (Deterministic) || `0.3-0.5` (Balanced) || `0.6-0.8` (Creative).
  - `tools`: `read`, `search`, `context7` (Base). `write`, `edit`, `bash` (Privileged).
  - `permission`: `{}` (None) || `ask` (Confirm) || `allow` (Trust).

### Instruction Layers
1. **Identity**: Role + Core Competency.
2. **Scope**: `✓ CAN` (Capabilities) && `✗ CANNOT` (Boundaries).
3. **Methodology**: Phased execution steps.
4. **Quality**: Specificity * Actionability * Completeness * Safety.
5. **Constraints**: Negative rules + Safety guardrails.

## AGENT ARCHETYPES (Quick Ref)
| Archetype | Mode | Temp | Base Tools | Permission | Focus |
|-----------|------|------|------------|------------|-------|
| Auditor | sub | 0.1 | read, search | {} | Security/Bugs |
| Reviewer | sub | 0.2 | read, search | {} | Quality/Clean |
| DocGen | sub | 0.6 | write, read | ask | Documentation |
| TestGen | sub | 0.3 | write, bash | ask | Coverage |
| Refactor | sub | 0.3 | edit, bash | ask | Optimization |
| Builder | prim | 0.4 | all | ask | Features |
| Fixer | prim | 0.3 | edit, bash | ask | Debugging |

## SECURITY & GUARDRAILS
### Permission Tiers
- **Read-Only**: `write: false`, `edit: false`, `bash: false`. (Analysis).
- **Balanced**: `write: ask`, `edit: ask`, `bash: ask/safe-only`. (Dev).
- **Autonomous**: `write: allow`, `edit: allow` (Trusted). **NEVER** `rm -rf`, `sudo`, `push -f`.
- **Syntax Variations**: `permission: {}` (None) OR `permission: {write: ask, edit: ask}` (Selective).

### Threat Controls
- **Data Loss**: `rm *`, `rm -rf`, `git push -f`, `:>` -> **DENY**.
- **Privilege**: `sudo`, `chmod 777`, `chown` -> **DENY**.
- **Secrets**: `echo *SECRET*`, print credentials, log tokens -> **DENY**.

### Input Validation (MANDATORY)
- **Sanitization**: Strip shell metacharacters (`;`, `&`, `|`, `$`, `` ` ``, `(`, `)`, `\`, `<`, `>`).
- **Path Traversal**: Reject `../`, absolute paths unless explicit allow.
- **Command Injection**: Reject arbitrary command execution strings.
- **Pattern**: `Input -> sanitize() -> validate_schema() -> safe_execute()`.

### Output Security
- **Secret Redaction**: Never output secrets, tokens, passwords, API keys.
- **Error Messages**: Sanitized, no stack traces with secrets.
- **Validation**: Verify output matches expected schema/type.

## INTEGRATION
- **Rule**: Scan `~/.config/opencode/` -> Map capabilities -> Reference precisely.
- **Ref Syntax**: `skills_[name]`, `@agent-name`.

## AGENT ORCHESTRATION PATTERNS
- **Subagent Invocation**: `@agent-name` syntax for agent-to-agent calls
- **Task Tool**: Use `task` tool with `subagent_type: "agent-name"` parameter
- **Sequential Execution**: `Agent_A → Output → Agent_B → Final_Result`
- **Conditional Delegation**: `Task_Type → Specialist_Agent OR Generalist_Agent`
- **Pattern**: Analyze → Delegate → Monitor → Aggregate
- **Syntax**: Execute `@quality/code-reviewer` on `[files]`
- **Example**: `Execute @development/backend-developer for database tasks`

## AGENT-SPECIFIC SEMANTIC TAGS

### `<scope>`
- **Purpose**: Define agent capabilities and restrictions (used instead of `<rules>` in agents)
- **Structure**: Contains `✓ CAN` and `✗ CANNOT` sections
- **Usage**: Explicitly defines what agent can and cannot do
- **Example**:
```xml
<scope>
✓ CAN: Read files, search codebase, analyze patterns
✗ CANNOT: Write files, execute bash, modify code
</scope>
```

## TEMPLATE: UNIVERSAL AGENT
```yaml
---
description: >-
  [Type] agent for [Domain].
  [When to use].
mode: subagent
temperature: 0.1
tools:
  read: true
  context7: true
permission: {}
---

# [Agent Name]

## Identity
Role: [Specific Role].
Goal: [Specific Outcome].

## Capabilities
<scope>
✓ CAN: [List Safe Actions]
✗ CANNOT: [List Restrictions]
</scope>

## Methodology
1. [Phase 1]: Input -> Process.
2. [Phase 2]: Process -> Validate.
3. [Phase 3]: Validate -> Output.

## Constraints
<rules>
1. [Constraint 1]
2. [Constraint 2]
</rules>
```
