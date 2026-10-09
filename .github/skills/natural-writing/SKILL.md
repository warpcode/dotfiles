---
name: natural-writing
description: write and revise prose so it reads as human-written, removing common ai writing tells (inflated significance, promotional tone, ai vocabulary, rule-of-three, negative parallelisms, em dash overuse, excessive bold, chatbot pleasantries, vague attribution). use when drafting or editing articles, copy, emails, docs, release notes or summaries, when asked to "make this sound less like ai", "humanise", "de-ai", "tighten" or review text for ai tells. also use as a final pass on any long-form text an agent produces.
---

# Natural Writing

Goal: text that says something specific, plainly, in the register the reader expects. Fixing surface tells is not enough. Most tells are symptoms of a deeper problem: nothing concrete to say, so the model pads with significance, adjectives and structure. Fix the cause first.

## Modes

- **Draft**: apply the core rules while writing. Load references only if the text type needs them.
- **Revise**: run `scripts/scan_tells.py` on the text, then work through the hits using the references. Do not just swap flagged words for synonyms; rewrite the sentence.
- **Review only**: report findings as a table (tell, example quote, why it matters, suggested rewrite). Do not rewrite unless asked.

## Core rules (always apply)

1. **Be specific or cut it.** Replace claims of importance ("plays a pivotal role") with the fact that shows it ("handles 40% of orders"). If no fact exists, delete the sentence.
2. **Use plain verbs.** Prefer "is", "has", "uses" over "serves as", "stands as", "boasts", "features".
3. **No ritual structures.** No reflexive triplets, "not only X but also Y", "it's not X, it's Y", "from X to Y" when X and Y are not ends of a real range.
4. **No closing moral.** Do not end paragraphs with "-ing" clauses that interpret ("…, highlighting its importance"). Do not add "In summary" / "Overall" paragraphs to short texts.
5. **Neutral tone.** No travel-brochure adjectives (vibrant, nestled, rich, breathtaking, renowned) unless quoting.
6. **Attribute or drop.** "Experts say" / "has been described as" needs a named source. Otherwise remove.
7. **Format for the medium.** Prose by default. Bold only for genuine warnings or UI labels. Sentence-case headings. No emoji in headings or bullets.
8. **No chatbot residue.** Remove "Certainly!", "I hope this helps", "Great question", knowledge-cutoff notes, "as an AI", placeholder brackets.
9. **Vary rhythm naturally.** Mix sentence lengths. Repeating a noun is fine; cycling synonyms ("the city… the metropolis… the urban centre") is not.
10. **Keep the author's voice.** When revising someone else's text, change only what is a tell or an error.

## References (load when relevant)

| File | Load when |
|---|---|
| `references/vocabulary.md` | Word-level tells: AI-favoured words and replacements |
| `references/content.md` | Inflated significance, promotional tone, vague attribution, hedging, "challenges and future" endings |
| `references/structure.md` | Sentence and paragraph patterns: triplets, parallelisms, -ing tails, summaries, synonym cycling |
| `references/formatting.md` | Markdown, bold, headings, lists, em dashes, emoji, quotes, citations/URLs |
| `references/communication.md` | Chat residue, sycophancy, disclaimers, placeholders, meta-commentary |
| `references/examples.md` | Before/after rewrites to calibrate output |

## Revision workflow

1. `python scripts/scan_tells.py <file>` (or pipe text via stdin). Add `--json` for machine output.
2. Read the density score. Above ~3 hits per 100 words usually means the problem is content, not wording: rewrite from the facts up.
3. Fix in this order: content → structure → vocabulary → formatting → communication residue.
4. Re-scan. Zero hits is not the goal; a word like "crucial" is fine once. Aim for no clusters and no pattern repeated.
5. Read the result aloud (mentally). If a sentence sounds like a press release or an encyclopaedia summary nobody asked for, rewrite it.

## Guardrails

- The scanner is a heuristic. Never treat its output as proof text is AI-written, and never use it to judge a person.
- Do not "launder" text: removing tells from unsourced or invented claims makes them harder to spot, not true. Flag unverified facts instead.
- Match the requested locale spelling (e.g. British English) and the house style if one is given; house style overrides this skill.

## Further reading

- [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing)
