function fzf.cli() {
    pkg.exec fzf "$@"
}

if [[ -o interactive ]]; then
    # Use fzf for history search in an interactive shell
    source <(fzf.cli --zsh 2>/dev/null)
fi
