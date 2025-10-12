# AI Tools Configuration

# LiteLLM API Configuration - only set when not at work
export LITELLM_API_ENDPOINT="http://litellm.ai.localhost/v1"
export LITELLM_API_TOKEN="sk-1234"  # Local only, insecure storage is acceptable

# GitHub Copilot Configuration
if [[ -f "$HOME/.config/github-copilot/apps.json" ]]; then
    export GITHUB_COPILOT_API_ENDPOINT="https://api.githubcopilot.com"
    export GITHUB_COPILOT_API_TOKEN=$(jq -r 'to_entries[0].value.oauth_token' "$HOME/.config/github-copilot/apps.json" 2>/dev/null)
fi
