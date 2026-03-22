function fzf.cli() {
    pkg.exec fzf "$@"
}

if [[ -o interactive ]] && pkg.status fzf >/dev/null 2>&1; then
    # Use fzf for history search in an interactive shell
    source <(fzf.cli --zsh 2>/dev/null)
fi
