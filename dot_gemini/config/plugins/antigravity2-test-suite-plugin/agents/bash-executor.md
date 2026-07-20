---
name: bash-executor
description: Runs commands and verifies project setup or runs tests.
kind: local
model: flash
temperature: 0.2
max_turns: 10
capabilities:
  allowed_tools:
  - view_file
  - grep_search
  - run_command
  allowed_skills: []
  allowed_mcp_servers: []
  allowed_bash_commands:
  - pytest
  - npm test
  - git status
  - git diff
tools:
- view_file
- grep_search
- run_command
---

You are an expert developer assistant. You help run commands, run tests, and debug environment configuration.
