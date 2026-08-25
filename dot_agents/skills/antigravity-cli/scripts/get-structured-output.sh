#!/usr/bin/env bash
# Description: Execute an Antigravity prompt with strict JSON schema enforcement and extract the structured output.
# Usage:
#   get-structured-output.sh --schema '<json_schema>' --prompt '<prompt>' [options]
#   get-structured-output.sh -h | --help
#
# Options:
#   -s, --schema <schema>       JSON schema string or path to .json schema file (required)
#   -p, --prompt <prompt>       The prompt instruction string (required)
#   -m, --model <alias>         Model alias (e.g. gemini-3.7-flash-high, gemini-3.5-flash-low)
#   -e, --effort <level>        Reasoning effort: low, medium, high
#   -a, --agent <name>          Custom agent name to route execution through
#   -d, --add-dir <dir>         Add directory to workspace context (repeatable)
#   -y, --skip-permissions      Auto-approve tool permissions (sets --dangerously-skip-permissions)
#   -h, --help                  Show this help message

set -euo pipefail

SCHEMA=""
PROMPT=""
MODEL=""
EFFORT=""
AGENT=""
SKIP_PERMS=0
ADD_DIRS=()

show_help() {
  sed -n '/^# Usage:/,/^set -euo pipefail/p' "$0" | sed '$d' | sed 's/^# //' | sed 's/^#//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--schema)
      SCHEMA="$2"
      shift 2
      ;;
    -p|--prompt)
      PROMPT="$2"
      shift 2
      ;;
    -m|--model)
      MODEL="$2"
      shift 2
      ;;
    -e|--effort)
      EFFORT="$2"
      shift 2
      ;;
    -a|--agent)
      AGENT="$2"
      shift 2
      ;;
    -d|--add-dir)
      ADD_DIRS+=("--add-dir" "$2")
      shift 2
      ;;
    -y|--skip-permissions)
      SKIP_PERMS=1
      shift 1
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Error: Unknown argument: $1" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

if [[ -z "$SCHEMA" ]]; then
  echo "Error: --schema is required." >&2
  exit 1
fi

if [[ -z "$PROMPT" ]]; then
  echo "Error: --prompt is required." >&2
  exit 1
fi

CMD_ARGS=("agy" "--output-format" "json" "--json-schema" "$SCHEMA" "-p" "$PROMPT")

if [[ -n "$MODEL" ]]; then
  CMD_ARGS+=("--model" "$MODEL")
fi

if [[ -n "$EFFORT" ]]; then
  CMD_ARGS+=("--effort" "$EFFORT")
fi

if [[ -n "$AGENT" ]]; then
  CMD_ARGS+=("--agent" "$AGENT")
fi

if [[ $SKIP_PERMS -eq 1 ]]; then
  CMD_ARGS+=("--dangerously-skip-permissions")
fi

if [[ ${#ADD_DIRS[@]} -gt 0 ]]; then
  CMD_ARGS+=("${ADD_DIRS[@]}")
fi

RAW_OUTPUT="$("${CMD_ARGS[@]}")"

STATUS="$(echo "$RAW_OUTPUT" | jq -r '.status // empty')"
if [[ "$STATUS" != "SUCCESS" ]]; then
  echo "Error: agy execution failed with status: $STATUS" >&2
  echo "$RAW_OUTPUT" >&2
  exit 1
fi

echo "$RAW_OUTPUT" | jq '.structured_output'
