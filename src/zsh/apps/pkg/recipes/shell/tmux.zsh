pkg.recipe.define tmux \
    package="tmux" \
    managers="apt dnf pacman brew"


pkg.recipe.tmux.configure() {
    registry.is_enabled pkg tmux pkg.recipe || return 0

    tui.task "Configuring tmux..."
    tui.indent.push
    {
        tui.success "tmux configuration is managed by chezmoi"
    } always {
        tui.indent.pop
    }
}
