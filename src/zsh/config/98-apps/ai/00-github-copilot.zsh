# GitHub Copilot Configuration
if [[ -f "$HOME/.config/github-copilot/apps.json" ]]; then
    # Set the API endpoint for GitHub Copilot
    export GITHUB_COPILOT_API_ENDPOINT="${GITHUB_COPILOT_API_ENDPOINT:-https://api.githubcopilot.com}"

    # Extract the OAuth token from the GitHub Copilot apps.json file
    local token
    token=$(jq -r 'to_entries[0].value.oauth_token' "$HOME/.config/github-copilot/apps.json" 2>/dev/null)

    # Export the API token, allowing external override
    export GITHUB_COPILOT_API_TOKEN="${GITHUB_COPILOT_API_TOKEN:-$token}"
fi
