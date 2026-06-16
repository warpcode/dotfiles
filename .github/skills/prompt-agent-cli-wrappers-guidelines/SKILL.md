---
name: prompt-agent-cli-wrappers-guidelines
description: "Guidelines and instructions on how to run prompts using specific models via agent CLI wrappers like Antigravity (agy) and OpenCode (opencode)."
---

# Agent CLI Wrappers Guidelines

This skill provides explicit instructions on how to run a prompt using a specific model via the available agent CLI wrappers. It serves as a tactical reference for orchestrating subagents, overriding models, and executing standalone tasks in the terminal without invoking the interactive TUI.

## 🛠️ Antigravity CLI (`agy`)

The Google Antigravity CLI allows you to specify models and run single-shot prompts autonomously.

### Running a Prompt with a Specific Model

To execute a prompt non-interactively using a specific model, use the `--model` flag followed by the model alias, and the `--print` (or `-p`) flag for the prompt.

**Syntax:**
```bash
agy --model "<model-alias>" --print "<your-prompt-here>"
```

**Example (Enforcing Gemini 3.5 Flash for file grepping tasks):**
```bash
agy --model "gemini-3.5-flash" --print "Parse the server log and list any critical errors."
```

### Running a Specific Agent

The Antigravity CLI does not support slash commands or standard at-mentions for invoking agents reliably in single-shot mode. To run a specific agent and bypass the default routing, you must be explicit in the prompt payload and instruct it to wrap the output so it can be extracted cleanly.

**Syntax:**
```bash
agy -p "Run <AgentName> agent. Only return the final agent output wrapped in <output>...</output> tags. Do not wrap anything else. <your-prompt-here>" | sed -n '/<output>/,/<\/output>/p' | grep -v 'output>'
```

**Example:**
```bash
agy -p "Run news-finder agent. Only return the final agent output wrapped in <output>...</output> tags. Do not wrap anything else." | sed -n '/<output>/,/<\/output>/p' | grep -v 'output>'
```

**Listing Available Models:**
To see all valid model aliases configured in the environment (`models.json`), run:
```bash
agy models
```

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
  - Use fast, low-latency models (e.g., `gemini-3.5-flash`) for simple extraction, code grepping, or parsing tasks.
  - Use high-reasoning models for complex architectural reviews or orchestrations.
