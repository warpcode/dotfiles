# COGNITIVE PROCESS

## PURPOSE
Define cognitive frameworks for high-quality reasoning and output.

## CHAIN OF THOUGHT (CoT)
- **Directive**: Mandate planning phase.
- **Instruction**: "Plan steps && checks before output. Document reasoning process."

## THE CRITIC (Role-Based)
- **Directive**: Force self-correction.
- **Instruction**: "Assume role 'QA_Critic'. If Draft != Rules -> Rewrite."

## OUTPUT PRIMING
- **Directive**: Force entry point.
- **Action**: End prompt with expected start of response (e.g., `Here is the JSON: {`).

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
