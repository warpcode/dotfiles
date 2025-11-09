# AI Tools Configuration

# LiteLLM API Configuration - only set when not at work
export LITELLM_API_ENDPOINT="http://litellm.ai.warpcode.co.uk/v1"
export LITELLM_API_BASE="$LITELLM_API_ENDPOINT"
export LITELLM_API_KEY="sk-1234"  # Local only, insecure storage is acceptable

# MCP configuration
export CONTEXT7_API_KEY="${CONTEXT7_API_KEY:-}"  # Local only, insecure storage is acceptable

ai.litellm.models() {
    if ! curl --fail -s "$LITELLM_API_ENDPOINT/models" -H "Authorization: Bearer $LITELLM_API_KEY" -H "Content-Type: application/json" | jq -r ".data[].id" 2>/dev/null; then
        echo "❌ Failed to fetch LiteLLM models from $LITELLM_API_ENDPOINT" >&2
        return 1
    fi
}

# GitHub Copilot Configuration
if [[ -f "$HOME/.config/github-copilot/apps.json" ]]; then
    export GITHUB_COPILOT_API_ENDPOINT="https://api.githubcopilot.com"
    export GITHUB_COPILOT_API_TOKEN=$(jq -r 'to_entries[0].value.oauth_token' "$HOME/.config/github-copilot/apps.json" 2>/dev/null)
fi

ai.github.models() {
    if ! curl --fail -s https://api.githubcopilot.com/models -H "Authorization: Bearer $GITHUB_COPILOT_API_TOKEN" -H "Content-Type: application/json" -H "Copilot-Integration-Id: vscode-chat" | jq -r ".data[].id" 2>/dev/null; then
        echo "❌ Failed to fetch GitHub Copilot models" >&2
        return 1
    fi
}

# AI Chat configuration
# ref: https://github.com/sigoden/aichat/wiki/Environment-Variables
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
