# Martini project directory (override in your environment or ~/.zshrc.d/m6.zsh if needed)
: "${MARTINI_DIR:=$HOME/src/martini}"

if [[ ! -d "$MARTINI_DIR" ]]; then
  return
fi

# Navigation
alias m6.cd="cd \"$MARTINI_DIR\""

# Martini management aliases
alias m6.db="pushd \"$MARTINI_DIR\" > /dev/null && docker compose exec web martini-db.sh; popd > /dev/null"
alias m6.sh="pushd \"$MARTINI_DIR\" > /dev/null && docker compose exec web bash; popd > /dev/null"

# Docker management aliases
alias m6.up="pushd \"$MARTINI_DIR\" > /dev/null && docker compose up -d --build; popd > /dev/null"
alias m6.stop="pushd \"$MARTINI_DIR\" > /dev/null && docker compose stop; popd > /dev/null"
alias m6.restart="m6.stop && m6.up"
alias m6.logs="pushd \"$MARTINI_DIR\" > /dev/null && docker compose logs -f --tail=100 web; popd > /dev/null"

# FE tools
alias m6.build.mds="pushd \"$MARTINI_DIR\"/misc/responsive-static/mds > /dev/null && npm run build; popd > /dev/null"
alias m6.build.admin="pushd \"$MARTINI_DIR\"/misc/responsive-static/admin > /dev/null && npm run build; popd > /dev/null"
alias m6.build.all="m6.build.mds && m6.build.admin"

# Staging aliases
alias m6.staging.web="ssh m6-staging-web"
alias m6.staging.old="ssh m6-staging-old"
alias m6.staging.db="ssh m6-staging-db"
