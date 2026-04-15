pkg.recipe.define git \
    package="git" \
    managers="apt dnf pacman brew"

pkg.recipe.git.configure() {
    tui.task "Configuring git..."
    tui.indent.push
    {
        (( $+commands[git] )) || { tui.warn "git command not found, skipping"; return 0; }

        tui.step "Setting global includes and excludes"
        command git config --global include.path "$(fs.dotfiles.path "assets/configs/git/.gitconfig_default")"
        command git config --global core.excludesfile "$(fs.dotfiles.path "assets/configs/git/.gitignore_global")"
        tui.success "git configured"
    } always {
        tui.indent.pop
    }
}
