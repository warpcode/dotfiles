typeset -A recipe=(
    [name]="git"
    [apt]="git"
    [brew]="git"
    [dnf]="git"
    [pacman]="git"
    [post_install]='
        echo "📦 Setting global git config..."
        pkg.exec git config --global include.path "~/.gitconfig_default"
    '
)
