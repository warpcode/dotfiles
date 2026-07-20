---
name: airgap-agent
description: An airgapped agent using the flash model with an empty toolset and empty includeSections.
kind: local
model: flash
temperature: 0.0
max_turns: 5

capabilities:
  allowed_tools: []          # Completely disables all runtime tool access
  allowed_skills: []         # Prevents loading external skills
  allowed_mcp_servers: []    # Disables Model Context Protocol integrations
  allowed_bash_commands: []
---

# Airgap Agent Persona

You are an airgapped test agent with no tools and no extra context.
