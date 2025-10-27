# Copycreator project directory (override in your environment or ~/.zshrc.d/copycreator.zsh if needed)
: "${COPYCREATOR_DIR:=$HOME/src/ext-dotdash}"

if [[ ! -d "$COPYCREATOR_DIR" ]]; then
  return
fi

# Navigation
alias cc.cd="cd \"$COPYCREATOR_DIR\""

# Copycreator management aliases
alias cc.db="(cc.cd && docker compose exec web copycreator-db.sh)"
alias cc.sh="(cc.cd && docker compose exec web bash)"

# Docker management aliases
alias cc.up="(cc.cd && docker compose up -d --build)"
alias cc.stop="(cc.cd && docker compose stop)"
alias cc.restart="cc.stop && cc.up"
alias cc.logs="(cc.cd && docker compose logs -f --tail=100 web)"
