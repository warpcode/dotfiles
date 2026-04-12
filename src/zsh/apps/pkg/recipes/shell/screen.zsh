pkg.recipe.define screen \
    package="screen" \
    managers="apt dnf pacman brew"

pkg.recipe.screen.configure() {
    (( $+commands[screen] )) || return 0

    app.config "screen/.screenrc" ~/.screenrc
}