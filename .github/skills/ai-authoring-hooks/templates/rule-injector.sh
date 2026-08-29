#!/usr/bin/env bash
# rule-injector.sh: Dynamically inspect modified files and inject path-scoped rules
set -euo pipefail

CHANGED_FILES=$(git status --porcelain 2>/dev/null | awk '{print $2}' || true)
if [ -z "$CHANGED_FILES" ]; then
  CHANGED_FILES=$(git log -n 1 --name-only --pretty=format: 2>/dev/null || true)
fi

INJECTED_RULES=""
RULE_DIRS=(".github/instructions" ".agents/rules" ".claude/rules")

for DIR in "${RULE_DIRS[@]}"; do
  [ -d "$DIR" ] || continue
  for RULE_FILE in "$DIR"/*; do
    [ -f "$RULE_FILE" ] || continue

    # Extract applyTo, globs, or paths from YAML frontmatter
    GLOBS=$(awk '/^---$/{c++;next} c==1{if($1 ~ /^(applyTo|globs|paths):/) {sub(/^[^:]*:[[:space:]]*/, ""); print}}' "$RULE_FILE" 2>/dev/null | tr -d '"' | tr ',' ' ' || true)

    if [ -n "$GLOBS" ]; then
      MATCHED=0
      for GLOB in $GLOBS; do
        for FILE in $CHANGED_FILES; do
          # shellcheck disable=SC2053
          if [[ "$FILE" == $GLOB ]]; then
            MATCHED=1
            break 2
          fi
        done
      done
      if [ "$MATCHED" -eq 1 ]; then
        CONTENT=$(awk '/^---$/{c++;next} c>=2' "$RULE_FILE")
        INJECTED_RULES="${INJECTED_RULES}\n\n[RULE: $(basename "$RULE_FILE")]\n${CONTENT}"
      fi
    fi
  done
done

if [ -n "$INJECTED_RULES" ]; then
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg ctx "$INJECTED_RULES" '{
      hookSpecificOutput: {
        additionalContext: ("Active Path Rules:\n" + $ctx)
      }
    }'
  else
    printf '{"hookSpecificOutput":{"additionalContext":"Active Path Rules:%s"}}\n' "$INJECTED_RULES"
  fi
else
  echo '{}'
fi
