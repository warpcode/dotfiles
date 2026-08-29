# Nous Hermes Agent Skill Commands & Blueprints Reference

Source: <https://hermes-agent.nousresearch.com/docs/developer-guide/creating-skills>

In Nous Research's Hermes Agent, all installed skills (`SKILL.md`) automatically register as dynamic slash commands (`/<skill-name>`) across CLI and chat gateways (Telegram, Discord, Slack). Additionally, `metadata.hermes.blueprint` enables scheduled and autonomous workflow directives.

---

## 1. Discovery Paths & Invocation

- **User Skills**: `~/.hermes/skills/<name>/SKILL.md`
- **Project Skills**: `skills/<name>/SKILL.md`
- **Automatic Invocation**: Every skill is invocable via `/<skill-name>`.

---

## 2. Frontmatter Schema & Blueprints

```yaml
---
name: string                   # Skill name and slash command trigger
description: string            # Trigger description
version: string                # Semantic version
author: string                 # Author handle
license: string                # License identifier
platforms: string[]            # Target operating systems (linux, macos)
required_environment_variables: # Declarative secret injection with interactive prompts
  - name: GITHUB_TOKEN
    prompt: "Enter GitHub PAT:"
    help: "Required for PR operations"
metadata:
  hermes:
    tags: string[]
    requires_toolsets: string[]
    config:
      - key: default_env
        description: "Target environment"
        default: "staging"
        prompt: "Choose environment:"
    blueprint:                 # Scheduled / autonomous workflow blueprint
      schedule: string         # Cron ("0 9 * * 1-5") or interval ("every 2h")
      deliver: string          # telegram | discord | slack | webhook
      prompt: string           # Autonomous directive to execute
      no_agent: boolean        # true = deterministic execution without LLM reasoning
---
```

---

## 3. Parameter Interpolation & Syntax

- **Positional & Named Args**: `$1..$n` or inline `key=value` assignment.
- **Interactive Slot-Filling**: Missing dynamic parameters prompt the user interactively.
- **Environment Substitutions**:
  - `${HERMES_SKILL_DIR}`: Absolute directory path of active skill.
  - `${HERMES_SESSION_ID}`: Active session identifier.
- **Dynamic Shell Output**: `` !`command` `` executes shell commands prior to model processing.
- **`[[as_document]]`**: Gateway directive instructing chat clients to deliver files as document attachments.
