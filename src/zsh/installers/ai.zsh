# AI Tools Installer

# Ensure aichat is installed
ensure_aichat() {
    if (( ! $+commands[aichat] )); then
        echo "aichat not found. Installing..."
        if (( $+commands[cargo] )); then
            cargo install aichat
        elif (( $+commands[brew] )); then
            brew install aichat
        elif (( $+commands[apt] )); then
            # Try to install via apt if available
            sudo apt update && sudo apt install -y aichat 2>/dev/null || {
                echo "aichat not available via apt. Please install manually: https://github.com/sigoden/aichat"
                return 1
            }
        else
            echo "Please install aichat manually: https://github.com/sigoden/aichat"
            echo "Common installation methods:"
            echo "  cargo install aichat"
            echo "  brew install aichat"
            return 1
        fi
    fi
}