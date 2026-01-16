# GitHub Copilot Provider - Models API
# https://docs.github.com/en/copilot

env.lazy.register "GITHUB_COPILOT_API_TOKEN" "jq -r 'to_entries[0].value.oauth_token' \"$HOME/.config/github-copilot/apps.json\" 2>/dev/null"

ai.providers.githubcopilot.api() {
    env.lazy.load "GITHUB_COPILOT_API_TOKEN"
    local api_path="${1:?}"
    local base_url="${GITHUB_COPILOT_API_ENDPOINT:-https://api.githubcopilot.com}"

    curl --fail --silent "${base_url%/}${api_path}" \
        -H "Authorization: Bearer ${GITHUB_COPILOT_API_TOKEN}" \
        -H "Content-Type: application/json" \
        -H "Copilot-Integration-Id: vscode-chat"
}

ai.providers.githubcopilot.models() {
    ai.providers.githubcopilot.api "/models" | jq -M '[.data[] | select(.policy.state == "enabled")]'
}
