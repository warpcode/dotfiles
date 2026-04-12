pkg.recipe.define mise \
    package="mise" \
    managers="apt dnf brew pacman" \
    apt_key="https://mise.jdx.dev/gpg-key.pub|mise-archive-keyring.asc" \
    apt_repo="mise-archive-keyring.asc|deb [arch=amd64 signed-by=%KEYRING%] https://mise.jdx.dev/deb stable main" \
    dnf_copr="jdxcode/mise"

pkg.recipe.mise.init() {
    (( $+commands[mise] )) || return 0

    local mise_init
    mise_init="$(mise activate zsh 2>/dev/null)" || mise_init=""
    [[ -n "$mise_init" ]] || return 0

    eval "$mise_init"
}
