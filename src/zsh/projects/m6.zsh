# Martini project directory (override in your environment or ~/.zshrc.d/m6.zsh if needed)
: "${MARTINI_DIR:=$HOME/src/martini}"

if [[ ! -d "$MARTINI_DIR" ]]; then
  return
fi

alias m6.db="pushd \"$MARTINI_DIR\" > /dev/null && docker compose exec web martini-db.sh; popd > /dev/null"
alias m6.sh="pushd \"$MARTINI_DIR\" > /dev/null && docker compose exec web bash; popd > /dev/null"
alias m6.cd="cd \"$MARTINI_DIR\""
