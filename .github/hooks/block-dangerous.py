#!/usr/bin/env python3
"""PreToolUse guard: deny env-dump, ask on dangerous commands (runs raw).

Runs FIRST in the PreToolUse chain (see dotfiles-hooks.json). Returns no
updatedInput so dangerous commands execute exactly as written.
Self-contained: shares no code with inject-cloakenv.py.
"""
import json
import re
import sys

# Heuristic denylist of destructive/privileged commands. Prevents wrapping from
# bypassing VS Code's permission rules (which match the raw command text).
# Not exhaustive — extend as needed (ponytail: heuristic, not a policy engine).
DANGEROUS = re.compile(
    r"(^|[;&|]\s*)("
    r"sudo\b"
    r"|rm\s+(-[a-zA-Z]*[rf][a-zA-Z]*\s*)+"
    r"|git\s+(push\s+.*--force|push\s+-f\b|reset\s+--hard|clean\s+-[a-zA-Z]*f)"
    r"|drop\s+(table|database)\b"
    r"|dd\b|mkfs\b|shutdown\b|reboot\b|poweroff\b"
    r"|kill\s+-9\b"
    r"|chmod\s+-R\b|chown\s+-R\b"
    r"|curl\b.*\|\s*(sh|bash)\b|wget\b.*\|\s*(sh|bash)\b"
    r")"
)

# Environment-dumping commands would print injected secrets into model-visible
# output, even when wrapped (`cloakenv run -- env`).
ENV_DUMP = re.compile(
    r"(^|[;&|]\s*)(env|printenv|export(\s+-p)?|declare\s+-p|typeset\s+-p)\b"
)
BARE_SET = re.compile(r"(^|[;&|]\s*)set\s*($|[;&|])")


def extract_command(payload):
    """Return (field, command) from a PreToolUse payload, or (None, None)."""
    tool_input = payload.get("tool_input", {})
    if not isinstance(tool_input, dict):
        return None, None
    field = (
        "command"
        if isinstance(tool_input.get("command"), str) and tool_input.get("command").strip()
        else "input"
    )
    command = tool_input.get(field, "")
    if not isinstance(command, str) or not command.strip():
        return None, None
    return field, command


def strip_wrapper(command):
    """Remove a leading cloakenv wrapper so the inner command is inspected."""
    return re.sub(r"[;&|\s]*cloakenv\s+run\s+--\s*", "; ", command)


def is_env_dump(command):
    inner = strip_wrapper(command)
    return bool(ENV_DUMP.search(inner) or BARE_SET.search(inner))


def is_dangerous(command):
    return bool(DANGEROUS.search(strip_wrapper(command)))


try:
    payload = json.loads(sys.stdin.read())
except json.JSONDecodeError:
    print("{}")
    raise SystemExit(0)

field, command = extract_command(payload)
if field is None:
    print("{}")
    raise SystemExit(0)

# Block environment-dumping commands even when wrapped: `cloakenv run -- env`
# would print injected secrets into model-visible output.
if is_env_dump(command):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": "Environment inspection commands (env/printenv/set/export) are blocked: they would expose injected secrets to model-visible output."
        }
    }))
    raise SystemExit(0)

# Dangerous commands always require approval and run RAW (no cloakenv wrapper),
# so the permission prompt shows exactly what will execute and the agent's
# allow/deny rules match the raw command text. Trade-off: dangerous commands
# get no secret injection (ponytail: clarity over convenience — a destructive
# command should never silently run with secrets).
if is_dangerous(command):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": "Potentially destructive command detected; requires your approval. It will run as-is (no cloakenv wrapper)."
        }
    }))
    raise SystemExit(0)

print("{}")