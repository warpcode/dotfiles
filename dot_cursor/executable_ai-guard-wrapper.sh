#!/usr/bin/env bash
set -euo pipefail

# Cursor Hook Bridge (sits in ~/.cursor/ next to hooks.json)

INPUT=$(cat)
# df.ai-guard exits with status 2 on deny, so capture output and exit code
RAW_OUTPUT=$(printf '%s' "$INPUT" | df.ai-guard "$@" 2>/dev/null || true)

# Abstain: pass through {} so Cursor uses its native permission evaluation
if [[ -z "${RAW_OUTPUT//[[:space:]]/}" || "$RAW_OUTPUT" =~ ^[[:space:]]*\{[[:space:]]*\}[[:space:]]*$ ]]; then
  echo '{}'
  exit 0
fi

if command -v jq >/dev/null 2>&1; then
  DECISION=$(echo "$RAW_OUTPUT" | jq -r '.decision // "allow"')
  REASON=$(echo "$RAW_OUTPUT" | jq -r '.reason // ""')
  if [[ "$DECISION" == "deny" ]]; then
    >&2 echo "SECURITY GUARD: $REASON"
    exit 2
  fi
fi

echo "$RAW_OUTPUT"
