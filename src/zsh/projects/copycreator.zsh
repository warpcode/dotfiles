# Copycreator project directory (override in your environment or ~/.zshrc.d/copycreator.zsh if needed)
: "${COPYCREATOR_DIR:=$HOME/src/ext-dotdash}"

if [[ ! -d "$COPYCREATOR_DIR" ]]; then
  return
fi

# Copycreator management aliases
alias cc.db="pushd \"$COPYCREATOR_DIR\" > /dev/null && docker compose exec web copycreator-db.sh; popd > /dev/null"
alias cc.sh="pushd \"$COPYCREATOR_DIR\" > /dev/null && docker compose exec web bash; popd > /dev/null"

# Docker management aliases
alias cc.up="pushd \"$COPYCREATOR_DIR\" > /dev/null && docker compose up -d --build; popd > /dev/null"
alias cc.stop="pushd \"$COPYCREATOR_DIR\" > /dev/null && docker compose stop; popd > /dev/null"
alias cc.restart="cc.stop && cc.up"
alias cc.logs="pushd \"$COPYCREATOR_DIR\" > /dev/null && docker compose logs -f --tail=100 web; popd > /dev/null"
