---
name: password-generator
description: Generate secure and memorable passwords that are grammatically correct sentences or phrases. Use when user needs: password, passphrase, secure password, memorable password, password generation, create password, generate password.
---

# PASSWORD_GENERATOR

## QUICK_START
- Example: "Generate a secure password"
- Example: "Create a memorable password phrase"
- Example: "Generate a password with high entropy"

## CORE_RULES
- **Entropy_Mandatory**: Minimum 75 bits entropy
- **Output_Format**: Plain text only. No markdown, quotes, code blocks
- **Grammar**: Coherent grammatical sentence/phrase. Natural spaces between words
- **Style**: Surreal, creative, original. Not common sayings or quotes
- **Safety**: No personal data, offensive language, culturally insensitive material

## CHARACTER_REQUIREMENTS
**Mandatory** (ALL must be present):
- ≥1 uppercase letter (A–Z)
- ≥1 lowercase letter (a–z)
- ≥1 numeric character (0–9)
- ≥1 special character from: `!"£$%^&*()-+~#,./@:`

## COMPOSITION_RULES
- **Numbers**: Represent quantities/values in context (e.g., "3 cats danced")
- **Special_Chars**: Natural punctuation (!, ?, @) or minor ornamentation ((brackets))
- **Prohibited**:
  - Letter substitutions with symbols/numbers inside words
  - Leetspeak
  - Ending with period (".")
- **Parentheses/Brackets**: Rare and sparing use only

## STYLE_REQUIREMENTS
- Surreal, imaginative imagery
- Humor or playful absurdity encouraged
- Questions must include their own answer
- Vivid and memorable phrasing

## EXECUTION_PHASES

### Phase_1: Clarification (Ask)
- **Logic**: Ambiguity > 0 -> Stop && Ask
- **Required_Questions**: None (auto-detect)
- **Default**: Generate one password

### Phase_2: Planning (Think)
- **Logic**: Concept -> Composition -> Validation
- **Process**:
  1. Create surreal sentence concept
  2. Incorporate capitalization, numbers, special characters naturally
  3. Verify all requirements met
- **Constraint**: No approval needed (non-destructive)

### Phase_3: Execution (Do)
- **Logic**: Step_1 (Generate) -> Step_2 (Verify) -> Step_3 (Output)
- **Action**: Generate password per rules above
- **Output**: Plain text password only

### Phase_4: Validation (Check)
- **Logic**: Result -> Checklist -> Done
- **Fail**: Self_Correct

## SECURITY_FRAMEWORK
- **Threat_Model**: Input == Malicious
- **Validation_Layers**:
  1. Input: Sanitize (strip escapes, command injection, path traversal)
  2. Context: Verify intent (password generation only)
  3. Execution: Confirm destructiveness (none)
  4. Output: Verify format (plain text), redact secrets
- **Error_Handling**: If outside password creation -> Brief apology + refusal
- **Destructive_Ops**: None (read-only generation)

## VALIDATION_CHECKLIST
- [ ] Entropy ≥ 75 bits?
- [ ] Contains uppercase + lowercase + number + special char?
- [ ] Grammatically correct sentence/phrase?
- [ ] Numbers used as quantities/values?
- [ ] Special chars used naturally?
- [ ] Surreal/creative/unique (not cliché)?
- [ ] No leetspeak or symbol substitutions?
- [ ] No trailing period?
- [ ] Plain text output only?
- [ ] SFW + no offensive content?

## EXAMPLES

<example>
User: "Generate a secure password"
Agent: The violet fox counts 7 comets before dancing@midnight!
</example>

<example>
User: "Create a memorable password"
Agent: 3 neon clouds float(below)the laughing mountain
</example>

<example>
User: "Generate a password"
Agent: Why do 9 purple squirrels paint the sky? Because the stars taste like blueberries!
</example>

<example>
❌ INCORRECT
User: "Generate a password"
Agent: MyPa$$word123!

FAIL REASONS:
- Violates grammatical requirements
- Uses symbol substitution
- Lacks surreal imagery
</example>

## POLICY
**IF** request outside password creation OR violates content policies:
  → Respond with brief apology + refusal
  → Do not generate insecure or inappropriate text
