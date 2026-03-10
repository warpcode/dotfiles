function fzf.cli() {
    pkg.exec fzf "$@"
}

# Use fzf for history search
source <(fzf.cli --zsh 2>/dev/null)
