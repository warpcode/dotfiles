---
name: prompt-agent-cli-wrappers-guidelines
description: "Guidelines and instructions on how to run prompts using specific models via agent CLI wrappers like OpenCode (opencode)."
---

# Agent CLI Wrappers Guidelines

This skill provides explicit instructions on how to run a prompt using a specific model via the available agent CLI wrappers. It serves as a tactical reference for orchestrating subagents, overriding models, and executing standalone tasks in the terminal without invoking the interactive TUI.

## 🛠️ OpenCode CLI (`opencode`)

OpenCode provides similar capabilities to run one-off tasks using specific providers and models.

### Running a Prompt with a Specific Model

To execute a prompt using OpenCode, use the `run` subcommand along with the `-m` (or `--model`) flag. OpenCode models are specified in the format `provider/model`.

**Syntax:**
```bash
opencode run -m "<provider>/<model>" "<your-prompt-here>"
```

**Example:**
```bash
opencode run -m "anthropic/claude-3-sonnet-20240229" "Audit the active directory for security flaws."
```

### Running a Specific Agent

OpenCode has built-in parameter support for dispatching prompts directly to a specific custom agent, bypassing the need for natural language routing.

**Syntax:**
```bash
opencode run --agent "<agent-name>" "<your-prompt-here>"
```

**Listing Available Models:**
To see all valid models and providers configured for OpenCode, run:
```bash
opencode models
```

## 🧠 Constraints and Routing

- **Inheritance vs. Constraints:** When executing these wrappers to spawn subagents for specific operations (e.g., file reading, grepping), ensure you explicitly pass the required model. This effectively acts as setting `inherit = false` for the subagent's context by overriding any inherited master model state.
- **Model Selection Strategy:** 
  - Use fast, low-latency models (e.g., `google/gemini-2.5-flash`) for simple extraction, code grepping, or parsing tasks.
  - Use high-reasoning models for complex architectural reviews or orchestrations.
