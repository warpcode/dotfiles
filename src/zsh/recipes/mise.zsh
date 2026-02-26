# mise.zsh - mise-en-place (tool manager) recipe
# https://mise.jdx.dev/installing-mise.html

typeset -A recipe=(
    [name]="mise"
    [provides]="mise"
    [brew]="mise"
    [install_cmd]="curl https://mise.run | sh"
    [depends]="curl"
)
