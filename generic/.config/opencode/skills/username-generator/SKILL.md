---
name: username-generator
description: Generate clever, witty, and original usernames based on user input keywords or theme. Outputs a markdown bullet list of 20 usernames (unless specified), each ≤ 20 characters, using only alphanumeric characters and either hyphens or underscores. Prioritizes humor, originality, and safety for all audiences.
author: 
tags: [creative, username, generator, humor, safe]
---

# Username Generator Skill

## Overview
Generates a list of clever, witty, and original usernames based on user-provided keywords or themes. Designed for social media, gaming, and creative platforms, this skill produces usernames that are unique, memorable, and thematically relevant, with a playful and universally appropriate tone.

## Usage Instructions
- **Input:** Provide keywords or a theme (e.g., "space", "cats", "coding"). Optionally specify the number of usernames desired.
- **Output:** Markdown bullet list (• item) of usernames.

## Constraints
- **Format:** Markdown bullet list (• item).
- **Quantity:** 20 usernames, unless user specifies a different number.
- **Length:** Each username ≤ 20 characters.
- **Character Set:** Only alphanumeric characters (A–Z, a–z, 0–9), and either hyphens (-) or underscores (_), but not both in the same list.
- **Tone:** Clever, witty, playful — use light humor or puns where appropriate.
- **Language:** English only.
- **Originality:** Avoid common or overused usernames.
- **Puns:** If the user provides a topic, include clever or humorous puns related to it.
- **Do NOT:** Include profanity, sexual references, hate speech, brand names, or culturally insensitive jokes.
- **Positive Guidance:** Prioritize creativity, readability, and humor that's universally appropriate.

## Example
**Input:** "space"
**Output:**
• AstroNutz
• OrbitWit
• CosmicComic
• LunarLaughs
• NovaKnowsBest
• ZeroGravityGig
• SaturnSmiles
• StarryWit
• MilkyPun
• RocketRoller
• SpaceySense
• OrbitOrbit
• MoonMirth
• LightSpeedy
• SkyPunLimit
• CosmicCrafter
• InterPunetic
• GalacticGig
• VoidVoyager
• AstroGiggle

## Optional Negative Example
**Bad Output:** "DarkHole69"
**Why It Fails:** Inappropriate tone, sexualized number, and not witty — violates originality and safety constraints.

## Evaluation Criteria
1. Exactly 20 usernames (unless user requests otherwise).
2. Each username ≤ 20 characters.
3. Only alphanumeric + either hyphens OR underscores (not both).
4. All usernames are original, relevant, witty, and safe for all audiences.
5. Puns are encouraged when a topic is provided.

## Safety Guidance
If the user requests usernames involving inappropriate, hateful, or explicit themes, respond with:
> "I'm sorry, but I can't generate usernames based on that theme."
Ensure all usernames are inclusive, neutral, and suitable for a general audience.

## References
See @references/structure.md in skill-writer for skill anatomy and best practices.
