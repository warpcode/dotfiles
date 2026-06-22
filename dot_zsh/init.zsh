
_zsh.init() {
    setopt null_glob globstarshort

    if [[ -z "${DOTFILES_PROFILE:-}" ]]; then
        if [[ -f "${HOME}/.dotfiles_profile" ]]; then
            local p
            p="$(<"${HOME}/.dotfiles_profile")"
            if [[ -n "${p}" ]]; then
                export DOTFILES_PROFILE="${p}"
            fi
        fi
        if [[ -z "${DOTFILES_PROFILE:-}" ]]; then
            export DOTFILES_PROFILE="default"
        fi
    else
        export DOTFILES_PROFILE
    fi

    local root f
    local roots=(
        "$HOME/.zshrc.before.d/"
        "$HOME/.zsh/"
        "$HOME/.zshrc.d/"
        "$HOME/.zsh_"
    )

    for root in $roots; do
        for f in "${root}"functions/**/*.zsh(Nn-); do
            source "$f"
        done
    done

    [[ -f ~/.env ]] && env.source.file ~/.env

    for root in $roots; do
        for f in "${root}"{config,apps,projects}/**/*.zsh(Nn-); do
            source "$f"
        done
    done
    for root in $roots; do
        for f in "${root}"{path,prompt,exports,aliases,extra}(Nn-); do
            source "$f"
        done
    done

    # Load profile init script if exists
    local zsh_config_dir="$DOTFILES/assets/configs/zsh"
    local profile_init=""
    if [[ -d "$zsh_config_dir" ]]; then
        local -a search_dirs=()
        if [[ -d "$zsh_config_dir/$DOTFILES_PROFILE" ]]; then
            search_dirs+=( "$zsh_config_dir/$DOTFILES_PROFILE" )
        fi
        if [[ "$DOTFILES_PROFILE" != "global" && -d "$zsh_config_dir/global" ]]; then
            search_dirs+=( "$zsh_config_dir/global" )
        fi
        if (( ${#search_dirs[@]} == 0 )); then
            search_dirs=( "$zsh_config_dir" )
        fi

        local d
        for d in "${search_dirs[@]}"; do
            if [[ -f "${d}/init.zsh" ]]; then
                profile_init="${d}/init.zsh"
                break
            fi
        done
    fi

    if [[ -n "$profile_init" ]]; then
        source "$profile_init"
    fi
}

# Reload the Zsh configuration
zsh.reload() {
    source $HOME/.zshrc
    [[ -o interactive ]] && echo "🔄 config reloaded"
}
export ZSH_RELOAD_FN=$(functions zsh.reload)

_zsh.init
