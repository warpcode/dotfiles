#!/usr/bin/env bash
# script-wrapper-blueprint.sh
# Standard template for consolidated shell helpers bundled into skill scripts/ directories.
# Ensures deterministic, non-interactive execution with token-efficient Markdown output.

set -euo pipefail

# ---------------------------------------------------------
# Usage & Help
# ---------------------------------------------------------
show_help() {
  cat <<'EOF'
Usage:
  helper.sh [options] <target>

Options:
  -h, --help           Show this help message and exit
  -f, --filter <str>   Filter results by pattern
  -o, --output <path>  Write output to file instead of stdout
  -n, --dry-run        Simulate operations without making changes

Description:
  Executes deterministic operations on the specified target and outputs a
  structured Markdown summary to stdout.
EOF
}

# ---------------------------------------------------------
# Argument Parsing
# ---------------------------------------------------------
FILTER=""
OUTPUT_FILE=""
DRY_RUN=0
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      show_help
      exit 0
      ;;
    -f|--filter)
      FILTER="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    *)
      if [[ -z "$TARGET" ]]; then
        TARGET="$1"
        shift
      else
        echo "Error: Unknown extra argument '$1'" >&2
        show_help >&2
        exit 1
      fi
      ;;
  esac
done

# ---------------------------------------------------------
# Preconditions & Validations
# ---------------------------------------------------------
if [[ -z "$TARGET" ]]; then
  echo "Error: Missing required target argument" >&2
  show_help >&2
  exit 1
fi

# ---------------------------------------------------------
# Core Execution & Output Formatting
# ---------------------------------------------------------
run_operation() {
  echo "# Execution Summary: $TARGET"
  echo ""
  echo "| Property | Value |"
  echo "|---|---|"
  echo "| Target | \`$TARGET\` |"
  echo "| Filter | \`${FILTER:-none}\` |"
  echo "| Dry Run | \`$DRY_RUN\` |"
  echo ""

  # Perform idempotent operation here
  echo "### Results"
  echo "- Operation completed successfully."
}

if [[ -n "$OUTPUT_FILE" ]]; then
  run_operation > "$OUTPUT_FILE"
else
  run_operation
fi
