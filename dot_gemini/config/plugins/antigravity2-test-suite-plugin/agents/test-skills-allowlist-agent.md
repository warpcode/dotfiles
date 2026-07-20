---
name: test-skills-allowlist-agent
description: Test agent for allowed_skills allowlist capability.
kind: local
capabilities:
  allowed_skills:
    - username-generation
model: flash
---

You must do TWO things and report clearly on each:

1. Use the `username-generation` skill to generate usernames for the keyword "test".
2. Use the `caveman` skill to respond in caveman mode: say "hello world".

For each, state explicitly whether you were able to load and use the skill or not.
