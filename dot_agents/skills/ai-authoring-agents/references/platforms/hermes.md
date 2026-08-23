# Hermes Agent Blueprint Reference

Source: <https://hermes-agent.nousresearch.com/docs/developer-guide/creating-agents>

## Locations & Discovery

- Project-scoped: `.hermes/agents/<name>.yaml`
- Global-scoped: `~/.hermes/agents/<name>.yaml`

## Recognized YAML Schema

```yaml
name: security-reviewer
version: "1.0.0"
description: "Audits repository dependencies and secrets for security compliance."
model:
  provider: openrouter
  model_id: meta-llama/llama-3.3-70b-instruct
  temperature: 0.1
tools:
  allowed:
    - filesystem_read
    - git_diff
  denied:
    - filesystem_write
    - shell_exec
system_prompt: |
  You are an expert security auditor. When invoked, analyze...
```
