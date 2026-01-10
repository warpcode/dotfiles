# rust.zsh - Rust and Cargo recipe using rustup

_rust_post_install() {
    # Source the environment so rustup is available immediately if needed
    if [[ -f "$HOME/.cargo/env" ]]; then
        source "$HOME/.cargo/env"
    fi
    
    if command -v rustup >/dev/null; then
        echo "   Setting rustup default to stable..."
        rustup default stable
    else
        echo "⚠️ rustup command not found immediately after install. You might need to source ~/.cargo/env"
    fi
}

typeset -A recipe=(
    [name]="rust"
    [provides]="cargo rustc rustup"
    [depends]="curl"
    # Use -y for non-interactive installation
    [install_cmd]="curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- --no-modify-path -y"
    [post_install]="_rust_post_install"
)
