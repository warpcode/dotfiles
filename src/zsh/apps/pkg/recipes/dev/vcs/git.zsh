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

        local gitconfig_path
        gitconfig_path="$("$DOTFILES/bin/df.fs" profile list "assets/configs/git" ".gitconfig" 2>/dev/null | head -n 1)"
        if [[ -n "$gitconfig_path" ]]; then
            command git config --global --replace-all include.path "$gitconfig_path"
        else
            command git config --global --replace-all include.path "$(fs.dotfiles.path "assets/configs/git/.gitconfig_default")"
        fi

        command git config --global core.excludesfile "$(fs.dotfiles.path "assets/configs/git/.gitignore_global")"

        tui.success "git configured"
    } always {
        tui.indent.pop
    }
}
