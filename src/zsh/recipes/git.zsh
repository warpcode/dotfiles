# Function definitions (executed within the subshell scope of zinstall.install)
_git_post_install() {
    echo "📦 Setting global git config..."
    if command -v git >/dev/null; then
        git config --global include.path "~/.gitconfig_default"
        echo "✅ Global git config set successfully"
    else
        echo "❌ Git not found after install?" >&2
    fi
}

typeset -A recipe=(
    [name]="git"
    [provides]="git"
    [apt]="git"
    [brew]="git"
    [dnf]="git"
    [pacman]="git"
    [post_install]="_git_post_install"
)
