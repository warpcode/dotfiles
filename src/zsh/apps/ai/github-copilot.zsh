if [[ -f "$HOME/.config/github-copilot/apps.json" ]]; then
    export GITHUB_COPILOT_API_ENDPOINT="${GITHUB_COPILOT_API_ENDPOINT:-https://api.githubcopilot.com}"

    local token
    token=$(jq -r 'to_entries[0].value.oauth_token' "$HOME/.config/github-copilot/apps.json" 2>/dev/null)

    export GITHUB_COPILOT_API_TOKEN="${GITHUB_COPILOT_API_TOKEN:-$token}"
fi
