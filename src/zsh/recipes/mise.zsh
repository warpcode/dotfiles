# mise.zsh - mise-en-place (tool manager) recipe
# https://mise.jdx.dev/installing-mise.html

_mise_post_install() {
    echo "   Running mise install..."
    if ! mise install --cd ~; then
        echo "⚠️ mise install failed. Please run it manually to install tools."
    fi
}

typeset -A recipe=(
    [name]="mise"
    [provides]="mise"
    [brew]="mise"
    [install_cmd]="curl https://mise.run | sh"
    [depends]="curl"
    [post_install]="_mise_post_install"
)
