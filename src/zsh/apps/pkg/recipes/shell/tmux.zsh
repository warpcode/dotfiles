pkg.recipe.define tmux \
    package="tmux" \
    managers="apt dnf pacman brew"


pkg.recipe.tmux.configure() {
    (( $+commands[tmux] )) || return 0
    app.config "tmux/tmux.conf" ~/.tmux.conf
}
