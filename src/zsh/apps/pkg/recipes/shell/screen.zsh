pkg.recipe.define screen \
    package="screen" \
    managers="apt dnf pacman brew"

pkg.recipe.screen.configure() {
    registry.is_enabled pkg screen pkg.recipe || return 0

    tui.task "Configuring screen..."
    tui.indent.push
    {
        tui.success "screen configuration is managed by chezmoi"
    } always {
        tui.indent.pop
    }
}
