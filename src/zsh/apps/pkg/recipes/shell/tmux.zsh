pkg.recipe.define tmux \
    package="tmux" \
    managers="apt dnf pacman brew"


pkg.recipe.tmux.configure() {
    tui.task "Configuring tmux..."
    tui.indent.push
    {
        (( $+commands[tmux] )) || { tui.warn "tmux command not found, skipping"; return 0; }

        tui.step "Linking tmux.conf"
        app.config "tmux/tmux.conf" ~/.tmux.conf
        tui.success "tmux configured"
    } always {
        tui.indent.pop
    }
}
