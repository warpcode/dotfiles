# Martini project directory (override in your environment or ~/.zshrc.d/m6.zsh if needed)
: "${MARTINI_DIR:=$HOME/src/martini}"

if [[ ! -d "$MARTINI_DIR" ]]; then
  return
fi

# Navigation
alias m6.cd="cd \"$MARTINI_DIR\""

# Martini management aliases
alias m6.sh="pushd \"$MARTINI_DIR\" > /dev/null && docker compose exec web bash; popd > /dev/null"

# Database management
alias m6.db="pushd \"$MARTINI_DIR\" > /dev/null && docker compose exec web martini-db.sh; popd > /dev/null"
alias m6.db.dump="pushd \"$MARTINI_DIR\" > /dev/null && docker compose exec mysql mysqldump -u\$(_m6_get_config_json martini-db '.username') -p\$(_m6_get_config_json martini-db '.password') \$(_m6_get_config_json martini-db '.name') > backup_\$(date +%Y%m%d_%H%M%S).sql; popd > /dev/null"
alias m6.db.query="pushd \"$MARTINI_DIR\" > /dev/null && docker compose exec web martini-db.sh -e"
alias m6.db.tables="pushd \"$MARTINI_DIR\" > /dev/null && docker compose exec web martini-db.sh -e 'SHOW TABLES;'; popd > /dev/null"

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

# Fetch config value as JSON from martini-config-docker.php
# Usage: _m6_get_config_json <key> [jq_filter]
_m6_get_config_json() {
    local key="$1"
    local jq_filter="$2"
    if [[ -z "$key" ]]; then
        echo "Error: key parameter required" >&2
        return 1
    fi

    pushd "$MARTINI_DIR" > /dev/null || { echo "Error: martini directory not found" >&2; return 2; }
    # Only output JSON, suppress all other output
    local json_output=$(php -r 'chdir("etc"); $key = $argv[1];require "martini-config-docker.php";$value = Config::get($key);echo json_encode($value);' "$key" 2>/dev/null)
    local ret=$?
    popd > /dev/null

    if [[ $ret -eq 0 ]]; then
        if [[ -n "$jq_filter" ]]; then
            echo "$json_output" | jq -r "$jq_filter" | tr -d '[:space:]'
        else
            echo "$json_output" | tr -d '[:space:]'
        fi
    fi
    return $ret
}
