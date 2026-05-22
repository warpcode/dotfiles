[[ -z "$DOTFILES" ]] && export DOTFILES="${0:A:h:h:h}"

_zsh.init() {
    setopt null_glob globstarshort

    export DOTFILES_PROFILE="$("$DOTFILES/bin/df.fs" profile name 2>/dev/null)"

    local root f
    local roots=(
        "$HOME/.zshrc.before.d/"
        "$DOTFILES/src/zsh/"
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
    local -a profile_inits
    profile_inits=( ${(f)"$("$DOTFILES/bin/df.fs" profile list "assets/configs/zsh" "init.zsh" 2>/dev/null)"} )
    local profile_init=""
    if (( ${#profile_inits} > 0 )); then
        profile_init="${profile_inits[1]}"
    fi
    if [[ -n "$profile_init" ]]; then
        source "$profile_init"
    fi

    # Run per-recipe init hooks on shell load
    pkg.recipe.init_all
}

# Reload the Zsh configuration
zsh.reload() {
    source $HOME/.zshrc
    [[ -o interactive ]] && echo "🔄 config reloaded"
}
export ZSH_RELOAD_FN=$(functions zsh.reload)

_zsh.init
