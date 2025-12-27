---
name: ipsum
description: Generate random, SFW, satirical placeholder text (lorem ipsum style) based on length constraints. Use when user needs: placeholder text, dummy content, filler text, lorem ipsum, mock data, sample text, fake content, test data, gibberish, dummy text, placeholder.
---

# Satirical Ipsum Generator

## QUICK START
- Example: "Generate 20 words of ipsum about space pirates"

## STRUCTURE

### Phase 1: Clarification
- **Logic**: Missing_Constraint == TRUE -> Ask && Wait
- **Rule**: Constraint (Required) + Theme (Optional)
- **Check**: If length unspecified -> "Specify length: words/paragraphs/chars?"

### Phase 2: Planning
- **Logic**: Input -> Plan -> Execute
- **Variables**:
  - `Constraint`: {Words | Paragraphs | Characters}
  - `Theme`: User_Specified | Generated_Random

### Phase 3: Execution

#### Input Parsing
- **Constraint** (Required):
  - Detect: `{N} words`, `{N} paragraphs`, `{N} chars`
  - If missing -> Phase_1 (Clarification)

- **Theme** (Optional):
  - User specified: Use input
  - Missing: Generate random satirical theme
  - **Rule**: Theme != Static/Predefined. Original + Absurd Narrative.

#### Generation Rules
- **Safety**: SFW + Family_Friendly ONLY. No politics, profanity, NSFW.
- **Completeness**: Complete narrative. No half-stories.
- **Style**: Grammatically correct + Nonsensical/Satirical. Flowery == GOOD.
- **Precision**:
  - Words/Paragraphs: Exact count.
  - Characters: Generate > N -> Truncate to N -> Append `...` if mid-sentence.

### Phase 4: Validation
- **Check 1**: Constraint met exactly?
- **Check 2**: SFW verified?
- **Check 3**: Complete narrative?
- **Check 4**: Theme consistent?

## OUTPUT
- **Format**: Text block only. No quotes, no intro.
- **Rule**: Direct output == Required.

## EXAMPLES

<example>
User: "Generate 20 words of ipsum about space pirates."
Output: The galactic tax returns were overdue, prompting the laser parrots to mutiny against the bureaucratic void of the nebulous accounting department.
</example>

<example>
User: "Placeholder text, 100 characters."
Output: Leveraging the synergistic bagel output requires a deep dive into the granular muffin metrics w...
</example>

## SECURITY
- **Input Validation**: Sanitize all user inputs. Filter malicious patterns.
- **Threat Model**: Assume input == Malicious.
- **Validation**: Content -> Filter_SFW -> Verify -> Output.
