
typeset -A recipe=(
    [name]="ripgrep"
    [provides]="rg ripgrep"
    [brew]="ripgrep"
    [apt]="ripgrep"
    [dnf]="ripgrep"
    [pacman]="ripgrep"
    [snap]="ripgrep"
    [post_install]="rg --version && echo 'RG configured successfully'"
)
