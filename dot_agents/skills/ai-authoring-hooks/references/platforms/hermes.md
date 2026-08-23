# Hermes Agent Lifecycle Hook Reference

> **Official Documentation**:
> - [Hermes Agent Lifecycle Hooks & Plugins](https://hermes-agent.nousresearch.com/docs/developer-guide/lifecycle-hooks)
> - [Hermes Agent GitHub Repository](https://github.com/NousResearch/hermes-agent)

Hermes Agent (by Nous Research) features a modular plugin and lifecycle hook framework designed to extend agent execution loops, observe internal steps, and enforce execution policies.

## Discovery Locations & Configuration

| Scope | Location | Format |
|---|---|---|
| Main Configuration | `~/.hermes/config.yaml` | YAML (`hooks:` and `plugins.enabled:`) |
| Custom Agent Hooks | `hermes/agent-hooks/` or `~/.hermes/hooks/` | Python modules registering hooks |
| Bundled Plugins | `hermes/plugins/` | Python plugin packages implementing `register(ctx)` |

### `config.yaml` Example
```yaml
plugins:
  enabled:
    - security_guard
    - format_verifier
    - telemetry_langfuse

hooks:
  session_start: "scripts/notify_start.sh"
  session_end: "scripts/notify_end.sh"
```

## Supported Lifecycle Events

| Event | Fired At | Common Use |
|---|---|---|
| `session_start` | When the agent session initializes | Context setup, git environment logging |
| `session_end` | When the agent finishes session | Telemetry, cleanup, session archival |
| `pre_llm_call` | Prior to dispatching request to LLM | Injecting path-scoped rules, system prompts |
| `post_llm_call` | Immediately after receiving LLM response | Validating reasoning traces, parsing tags |
| `pre_tool_call` | Before invoking an external tool | Security gating, parameter validation |
| `post_tool_call` | After tool execution completes | Output scrubbing, formatting, auto-fixes |

## Writing Python Hook Plugins

Plugins define a standard entrypoint function `register(ctx)`:

```python
"""hermes/agent-hooks/security_guard.py"""

def register(ctx):
    @ctx.hooks.on("pre_tool_call")
    def validate_tool_call(tool_name: str, tool_args: dict) -> bool:
        if tool_name == "execute_command":
            cmd = tool_args.get("command", "")
            if "rm -rf" in cmd or "DROP TABLE" in cmd:
                ctx.log.warning(f"Blocked dangerous command: {cmd}")
                raise PermissionError(f"Command '{cmd}' is forbidden by security policy.")
        return True

    @ctx.hooks.on("pre_llm_call")
    def inject_rules(messages: list) -> None:
        # Dynamically inject turn-specific instructions or path rules
        messages.append({
            "role": "system",
            "content": "REMINDER: Always run tests before finishing."
        })
```

## CLI Diagnostics

Hermes provides built-in CLI tooling to inspect and debug registered hooks:

```bash
hermes hooks list
hermes hooks doctor
```
