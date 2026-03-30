# config.zsh - Configuration management and templating

_config_resolve() {
    local type="$1" path="$2"
    [[ -e "$path" ]] && { echo "${path:a:P}"; return 0; }
    local alt="$DOTFILES/assets/$type/$path"
    [[ -e "$alt" ]] && { echo "${alt:a:P}"; return 0; }
    return 1
}

# Symlink a config file or directory from assets/configs/
config.symlink() {
    local src="$1" dst="$2"
    [[ -z "$src" || -z "$dst" ]] && { echo "Usage: config.symlink <source> <destination>" >&2; return 1; }

    local resolved; resolved=$(_config_resolve configs "$src") || {
        echo "❌ Source not found: $src" >&2
        return 1
    }

    [[ -d "$dst" && ! -L "$dst" ]] && { echo "❌ Destination is a directory: $dst" >&2; return 1; }
    [[ -L "$dst" && "${dst:a:P}" == "$resolved" ]] && return 0
    [[ -e "$dst" || -L "$dst" ]] && rm -f "$dst"

    mkdir -p "${dst:h}"
    ln -s "$resolved" "$dst"
}

# Template a file using gomplate and JSON configs
config.hydrate() {
    local -A opts; zparseopts -E -D -K -A opts -config-file: -config-json: -output: h -help
    local tpl_in="$1"
    [[ -z "$tpl_in" || -n "$opts[-h]$opts[--help]" ]] && {
        echo "Usage: config.hydrate <template> [--config-file <path>] [--config-json <json>] [--output <path>]"
        return 0
    }
    shift

    local tpl; tpl=$(_config_resolve templates "$tpl_in") || { echo "❌ Template not found: $tpl_in" >&2; return 1; }

    local merged='{}'
    # Handle --config-file
    if [[ -n "$opts[--config-file]" ]]; then
        local cfg; cfg=$(_config_resolve configs "$opts[--config-file]") || return 1
        merged=$(jq -s '.[0] * .[1]' <<<"$merged" <"$cfg")
    fi
    # Handle --config-json
    if [[ -n "$opts[--config-json]" ]]; then
        merged=$(jq -s '.[0] * $n' --argjson n "$opts[--config-json]" <<<"$merged")
    fi

    merged=$(jq --arg now "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" '.secrets |= (. // {}) | .created |= (. // $now)' <<<"$merged")

    local tmp=$(mktemp)
    {
        print -r "$merged" > "$tmp"
        local -a args=(--missing-key=zero -f "$tpl" -c "config=file://${tmp}?type=application/json")

        if [[ "$tpl_in" == */* ]]; then
            local base="$DOTFILES/assets/templates/${tpl_in%%/*}"
            [[ -d "$base/partials" ]] && args+=(--template "tpls=$base/partials/")
        fi

        if [[ -n "$opts[--output]" ]]; then
            mkdir -p "${opts[--output]:h}"
            gomplate "${args[@]}" > "$opts[--output]"
        else
            gomplate "${args[@]}"
        fi
    } always {
        rm -f "$tmp"
    }
}

# Replace content between markers
config.markers.replace() {
    local file="$1" lead="$2" tail="$3" repl="$4"
    [[ -z "$file" || -z "$lead" || -z "$tail" || -z "$repl" ]] && return 1

    if [[ ! -f "$file" ]]; then
        print -r "$lead" > "$file"
        print -r "$repl" >> "$file"
        print -r "$tail" >> "$file"
    elif ! grep -qE -- "$lead" "$file" || ! grep -qE -- "$tail" "$file"; then
        print -r "$lead" >> "$file"
        print -r "$repl" >> "$file"
        print -r "$tail" >> "$file"
    else
        local -a lines=( ${(f)"$(<"$file")"} )
        local -a new_lines=()
        local block=0
        local line
        for line in "${lines[@]}"; do
            if [[ "$line" =~ "$lead" ]]; then
                new_lines+=("$line" "$repl")
                block=1
            elif [[ "$block" -eq 1 && "$line" =~ "$tail" ]]; then
                block=0
                new_lines+=("$line")
            elif [[ "$block" -eq 0 ]]; then
                new_lines+=("$line")
            fi
        done
        print -rl -- "${new_lines[@]}" > "$file"
    fi
}
