---
name: ipsum
description: Generates random, SFW, satirical placeholder text (lorem ipsum style) based on length and theme constraints.
---

# Satirical Ipsum Generator

This skill generates "Lorem Ipsum" style placeholder text, but instead of Latin, it produces work-friendly, satirical English text based on a theme.

## Input Handling

When the user activates this skill (e.g., "generate ipsum", "give me placeholder text"), analyze their request for two variables:

1.  **Constraint** (Required):
    *   Look for: Character limit, Word limit, or Paragraph limit.
    *   *If missing:* Ask the user specifically: "Do you have a length preference? (e.g., 50 words, 2 paragraphs, or 200 characters)" and wait for response.

2.  **Theme** (Optional):
    *   Look for a specific topic (e.g., "about marketing", "medieval knights").
    *   *If missing:* Randomly invent a satirical story theme on the fly (do not use a static or pregenerated list). The theme should be original, surprising, and lend itself to a playful or absurd narrative. Satirical stories are preferred.

## Generation Rules

1.  **Content Safety:** The text must be strictly Safe For Work (SFW) and Family Friendly. No politics, no profanity, no NSFW topics.
2.  **Completeness:** Any story or text generated must be a complete, self-contained narrative or passage. Do not provide half a story or incomplete text, regardless of length constraint. If a character or word limit is specified, ensure the text forms a satisfying, coherent whole within that limit.
3.  **Style:** Grammatically correct but nonsensical or highly satirical. Flowery language is encouraged.
4.  **Strict Limits:**
    *   **Words/Paragraphs:** Meet the count exactly.
    *   **Characters:** Generate slightly more text than needed, then strictly truncate to the exact character count, ending with an ellipsis `...` if it cuts a sentence mid-flow.

## Output Format

Return *only* the generated text block. Do not wrap it in quotes unless requested. Do not add introductory filler like "Here is your text:".

### Examples

**User:** "Generate 20 words of ipsum about space pirates."
**Output:**
The galactic tax returns were overdue, prompting the laser parrots to mutiny against the bureaucratic void of the nebulous accounting department.

**User:** "Placeholder text, 100 characters."
**Output:**
Leveraging the synergistic bagel output requires a deep dive into the granular muffin metrics w...
