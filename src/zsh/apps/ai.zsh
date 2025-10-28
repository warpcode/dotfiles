# AI Tools Configuration

# LiteLLM API Configuration - only set when not at work
export LITELLM_API_ENDPOINT="http://litellm.ai.localhost/v1"
export LITELLM_API_BASE="$LITELLM_API_ENDPOINT"
export LITELLM_API_KEY="sk-1234"  # Local only, insecure storage is acceptable

# MCP configuration
export CONTEXT7_API_KEY="${CONTEXT7_API_KEY:-}"  # Local only, insecure storage is acceptable

alias ai.litellm.models='curl -s $LITELLM_API_ENDPOINT/models -H "Authorization: Bearer $LITELLM_API_KEY" -H "Content-Type: application/json" | jq -r ".data[].id"'

# GitHub Copilot Configuration
if [[ -f "$HOME/.config/github-copilot/apps.json" ]]; then
    export GITHUB_COPILOT_API_ENDPOINT="https://api.githubcopilot.com"
    export GITHUB_COPILOT_API_TOKEN=$(jq -r 'to_entries[0].value.oauth_token' "$HOME/.config/github-copilot/apps.json" 2>/dev/null)
fi

alias ai.github.models='curl -s https://api.githubcopilot.com/models -H "Authorization: Bearer $GITHUB_COPILOT_API_TOKEN" -H "Content-Type: application/json" -H "Copilot-Integration-Id: vscode-chat" | jq -r ".data[].id"'

# AI Chat configuration
# ref: https://github.com/sigoden/aichat/wiki/Environment-Variables
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

alias ai.chat='ensure_aichat && aichat'

# OpenCode Configuration
if [[ "$IS_WORK" == "1" ]]; then
    export OPENCODE_MODEL="github-copilot/gpt-4.1"
else
    export OPENCODE_MODEL="opencode/grok-code"
fi

alias ai.code='ai.opencode'
alias ai.crush='npx -y @charmland/crush@latest'
alias ai.gemini='npx -y @google/gemini-cli'
alias ai.opencode='npx -y opencode-ai@latest'
