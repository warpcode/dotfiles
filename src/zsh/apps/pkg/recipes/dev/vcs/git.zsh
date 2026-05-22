pkg.recipe.define git \
    package="git" \
    managers="apt dnf pacman brew"

pkg.recipe.git.configure() {
    registry.is_enabled pkg git pkg.recipe || return 0

    tui.task "Configuring git..."
    tui.indent.push
    {
        (( $+commands[git] )) || { tui.warn "git command not found, skipping"; return 0; }

        tui.step "Setting global includes and excludes"

        local -a gitconfig_paths
        gitconfig_paths=( ${(f)"$("$DOTFILES/bin/df.fs" profile list "assets/configs/git" ".gitconfig" 2>/dev/null)"} )
        if (( ${#gitconfig_paths} > 0 )); then
            command git config --global --unset-all include.path 2>/dev/null || true
            local -i i
            for (( i=${#gitconfig_paths}; i>0; i-- )); do
                command git config --global --add include.path "${gitconfig_paths[$i]}"
            done
        fi

        local gitignore_path
        gitignore_path="$("$DOTFILES/bin/df.fs" profile list "assets/configs/git" ".gitignore_global" 2>/dev/null | head -n 1)"
        if [[ -n "$gitignore_path" ]]; then
            command git config --global core.excludesfile "$gitignore_path"
        fi

        tui.success "git configured"
    } always {
        tui.indent.pop
    }
}
