pkg.recipe.define git \
    package="git" \
    managers="apt dnf pacman brew"

pkg.recipe.git.configure() {
    (( $+commands[git] )) || return 0

    command git config --global include.path "$(fs.dotfiles.path "assets/configs/git/.gitconfig_default")"
    command git config --global core.excludesfile "$(fs.dotfiles.path "assets/configs/git/.gitignore_global")"
}
