# GitHub Copilot Configuration
if [[ -f "$HOME/.config/github-copilot/apps.json" ]]; then
    export GITHUB_COPILOT_API_ENDPOINT="https://api.githubcopilot.com"
    export GITHUB_COPILOT_API_TOKEN=$(jq -r 'to_entries[0].value.oauth_token' "$HOME/.config/github-copilot/apps.json" 2>/dev/null)
fi
