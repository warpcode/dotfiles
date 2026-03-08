typeset -A recipe=(
    [name]="neovim"
    [provides]="nvim"
    [proxy]=true
    [mise]="neovim@0.11.5"
    [exec]='mise exec $(pkg.field neovim) -- "$@"'
    [depends]='mise'
)
