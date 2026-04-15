pkg.recipe.define screen \
    package="screen" \
    managers="apt dnf pacman brew"

pkg.recipe.screen.configure() {
    tui.task "Configuring screen..."
    tui.indent.push
    {
        (( $+commands[screen] )) || { tui.warn "screen command not found, skipping"; return 0; }

        tui.step "Linking .screenrc"
        app.config "screen/.screenrc" ~/.screenrc
        tui.success "screen configured"
    } always {
        tui.indent.pop
    }
}
