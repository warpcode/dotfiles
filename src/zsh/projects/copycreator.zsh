# Copycreator project directory (override in your environment or ~/.zshrc.d/copycreator.zsh if needed)
: "${COPYCREATOR_DIR:=$HOME/src/ext-dotdash}"

if [[ ! -d "$COPYCREATOR_DIR" ]]; then
  return
fi

alias cc.cd="cd \"$COPYCREATOR_DIR\""
