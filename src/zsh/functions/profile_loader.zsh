# profile_loader.zsh - Profile configuration loading and merging utilities

# Load profile-specific config files in priority order and merge them using jq
fs.profile.load() {
    local config_subdir="${1:-}" # e.g. "assets/configs/obsidian/rules"
    local config_name="${2:-}"   # e.g. "default.json" or "${note_type}.json"
    [[ -z "$config_subdir" || -z "$config_name" ]] && return 1

    local -a config_files=()
    local -a profile_files=()
    
    # We call df.fs profile list to list config files merging global/default with active profile overrides
    if [[ -n "$DOTFILES" && -f "$DOTFILES/bin/df.fs" ]]; then
        profile_files=( ${(f)"$("$DOTFILES/bin/df.fs" profile list "$config_subdir" "$config_name" 2>/dev/null)"} )
    fi

    local f
    local -i i

    # Always start with the base configuration file as the foundation
    local fallback_path="${DOTFILES:-$HOME/.config/dotfiles}/$config_subdir/$config_name"
    if [[ -f "$fallback_path" ]]; then
        config_files+=( "$fallback_path" )
    fi

    # Load profile-specific config files in priority order (base -> global -> profile)
    for (( i=${#profile_files[@]}; i>0; i-- )); do
        f="${profile_files[$i]}"
        [[ -n "$f" ]] && config_files+=( "${f}" )
    done

    # If no configuration files were found at all, return failure
    if (( ${#config_files[@]} == 0 )); then
        return 1
    fi

    # Merge all discovered configs using jq
    jq -s 'reduce .[] as $item ({}; . * $item)' "${config_files[@]}" 2>/dev/null
}
