---
name: prompt-antigravity-agents-guidelines
description: Guidelines and procedures for creating, configuring, and testing custom agents in Google Antigravity. Covers declarative Markdown (.md) agents, plugin-defined JSON agents, capabilities configuration (allowed tools, skills, MCPs, bash commands), and runtime isolation modes. Use this skill whenever you are designing a new custom agent, setting up permissions, or writing configurations for Antigravity-run subagents.
---

# Antigravity Agent Configuration Guidelines

Design, configure, and test custom agents in Google Antigravity using declarative, plugin-based, or programmatic execution formats.

---

## 🛠️ Declarative Agent Format (YAML/Markdown)

Declarative agents are configured using YAML frontmatter in Markdown (`.md`) or YAML (`.yaml`) files. They are automatically discovered by the Antigravity runtime.

### 1. File Locations
* **Global Agents**: `~/.gemini/config/agents/<agent-name>.md`
* **Workspace-Scoped Agents**: `<workspace-root>/.agents/<agent-name>.md`

### 2. Configuration Schema
Use the following blueprint for frontmatter capabilities restrictions:

```yaml
---
name: security-auditor
description: Specialized in finding security vulnerabilities in code.
kind: local
model: gemini-3.5-flash
temperature: 0.2
max_turns: 10

# RESTRICT CAPABILITIES HERE
capabilities:
  # 1. Restrict Tools (only expose these tools to the model's context)
  allowed_tools:
    - view_file
    - grep_search

  # 2. Restrict Skills (prevent loading other system/custom skills)
  allowed_skills:
    - technical-review-guidelines

  # 3. Restrict MCP Servers
  allowed_mcp_servers:
    - github

  # 4. Restrict Bash Commands (enforce allowed command prefixes)
  allowed_bash_commands:
    - git status
    - git diff
---

[System prompt instructions go here]
```

---

## 🔌 Plugin JSON Agent Format (`agent.json`)

Plugin-defined agents allow packaging agents alongside custom skills, sidecars, and lifecycle hooks.

### 1. Structure of an Agent Plugin
```
plugins/<plugin-name>/
├── plugin.json
└── agents/
    └── <agent-name>/
        └── agent.json
```

### 2. Plugin Metadata (`plugin.json`)
```json
{
  "name": "weather-agent-plugin",
  "description": "Specialized in weather forecasting.",
  "version": "1.0.0"
}
```

### 3. Agent Configuration (`agent.json`)
Use this schema to configure custom prompts, tools, and reasoning depth:

```json
{
  "name": "weather-agent",
  "description": "Searches the web for current weather forecast.",
  "model": "gemini-3.5-flash",
  "options": {
    "thinking_level": "low"
  },
  "config": {
    "customAgent": {
      "systemPromptSections": [
        {
          "title": "Agent System Instructions",
          "content": "You are a Weather Agent..."
        }
      ],
      "toolNames": [
        "google_web_search",
        "web_fetch"
      ],
      "systemPromptConfig": {
        "includeSections": [
          "user_information",
          "skills",
          "messaging",
          "artifacts",
          "user_rules"
        ]
      }
    }
  }
}
```

* **`toolNames`**: Sandboxes the agent. The runtime strips all non-listed tools from the model's context.
* **`includeSections`**: Determines context injection. To disable all skills, remove `"skills"` from the list.
* **`options.thinking_level`**: Enforces reasoning depth. Supported values: `"minimal"`, `"low"`, `"medium"`, `"high"`.

---

## 🚀 Validation, Installation, & Execution

### 1. Managing Plugins
Validate the plugin configuration:
```bash
agy plugin validate ~/.gemini/config/plugins/weather-agent-plugin
```

Install/reinstall the plugin:
```bash
agy plugin install ~/.gemini/config/plugins/weather-agent-plugin
```

### 2. CLI Execution & Constraints
Run a targeted prompt through the custom agent configuration:
```bash
agy -p "weather-agent: search the web for the current weather in Tokyo."
```

> [!WARNING]
> **Tool Isolation Leak**: When executing an agent via the `"agent-name: ..."` CLI routing pattern, the agent runs within the coordinator's session context. The `toolNames` allowlist is **not** enforced. The coordinator's full toolset leaks to the agent.
> Strict tool isolation is only guaranteed when running the agent inside a dedicated programmatic session or the desktop IDE runner.

---

## 🔒 Session & OS Sandbox Isolation

To guarantee that agents cannot escape their sandbox, execute them in one of these modes:

### 1. Programmatic Python SDK Isolation
Utilize `CapabilitiesConfig` to strip disallowed tools on the API/framework level:

```python
from google.antigravity import Agent, LocalAgentConfig, CapabilitiesConfig
from google.antigravity.types import BuiltinTools
from google.antigravity.models import GeminiModelOptions, ThinkingLevel

capabilities = CapabilitiesConfig(
    enable_subagents=False,
    enabled_tools=[
        BuiltinTools.LIST_DIR,
        BuiltinTools.VIEW_FILE,
        BuiltinTools.FINISH
    ]
)

config = LocalAgentConfig(
    system_instructions="Isolated instructions...",
    api_key=os.environ.get("GEMINI_API_KEY"),
    capabilities=capabilities,
    workspaces=[os.getcwd()]
)
```

### 2. OS-Level Terminal Sandbox
Configure standard sandbox restrictions in `~/.gemini/antigravity-cli/settings.json`:
```json
{
  "enableTerminalSandbox": true,
  "toolPermission": "proceed-in-sandbox"
}
```
Or run the CLI session directly with the `--sandbox` flag:
```bash
agy --sandbox -p "weather-agent: Run weather check."
```
