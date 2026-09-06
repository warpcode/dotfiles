#!/usr/bin/env bash
set -euo pipefail

# Codex Hook Bridge (sits in ~/.codex/ next to hooks.json)

INPUT=$(cat)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_GUARD_BIN="df.ai-guard"
if ! command -v "$AI_GUARD_BIN" >/dev/null 2>&1; then
  if [[ -x "$HOME/.local/bin/df.ai-guard" ]]; then
    AI_GUARD_BIN="$HOME/.local/bin/df.ai-guard"
  elif [[ -x "$HOME/src/dotfiles/dot_local/bin/executable_df.ai-guard" ]]; then
    AI_GUARD_BIN="$HOME/src/dotfiles/dot_local/bin/executable_df.ai-guard"
  elif [[ -x "$SCRIPT_DIR/../dot_local/bin/executable_df.ai-guard" ]]; then
    AI_GUARD_BIN="$SCRIPT_DIR/../dot_local/bin/executable_df.ai-guard"
  fi
fi

GUARD_ARGS=("$@")
if [[ ${#GUARD_ARGS[@]} -eq 0 ]]; then
  if [[ "$INPUT" =~ \"toolResult\"|\"tool_result\" ]]; then
    GUARD_ARGS=("output")
  elif [[ "$INPUT" =~ \"run_command\"|\"bash\"|\"runTerminalCommand\"|\"execute_command\"|\"terminal\"|\"CommandLine\"|\"command\"|\"cmd\" ]]; then
    GUARD_ARGS=("command")
  elif [[ "$INPUT" =~ \"prompt\" && ! "$INPUT" =~ \"toolCall\" && ! "$INPUT" =~ \"tool_name\" ]]; then
    GUARD_ARGS=("prompt")
  else
    GUARD_ARGS=("file")
  fi
fi

EXIT_CODE=0
ERR_FILE=$(mktemp)
RAW_OUTPUT=$(printf '%s' "$INPUT" | "$AI_GUARD_BIN" "${GUARD_ARGS[@]}" 2>"$ERR_FILE") || EXIT_CODE=$?
STDERR_MSG=$(cat "$ERR_FILE")
rm -f "$ERR_FILE"

if [[ $EXIT_CODE -eq 2 ]]; then
  >&2 echo "${STDERR_MSG:-SECURITY GUARD: Operation denied.}"
  exit 2
fi

if [[ $EXIT_CODE -ne 0 ]]; then
  >&2 echo "SECURITY GUARD error (exit code $EXIT_CODE): $STDERR_MSG"
  exit 2
fi

if command -v jq >/dev/null 2>&1; then
  DECISION=$(echo "$RAW_OUTPUT" | jq -r '.decision // empty' 2>/dev/null || true)
  REASON=$(echo "$RAW_OUTPUT" | jq -r '.reason // ""' 2>/dev/null || true)
  if [[ "$DECISION" == "deny" ]]; then
    >&2 echo "SECURITY GUARD: $REASON"
    exit 2
  fi
elif [[ "$RAW_OUTPUT" =~ \"decision\"[[:space:]]*:[[:space:]]*\"deny\" ]]; then
  >&2 echo "SECURITY GUARD: Operation denied."
  exit 2
fi

if [[ -z "${RAW_OUTPUT//[[:space:]]/}" || "$RAW_OUTPUT" =~ ^[[:space:]]*\{[[:space:]]*\}[[:space:]]*$ ]]; then
  echo '{}'
  exit 0
fi

echo "$RAW_OUTPUT"
