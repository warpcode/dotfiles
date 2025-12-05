
ai.github.models() {
    if ! curl --fail -s https://api.githubcopilot.com/models -H "Authorization: Bearer $GITHUB_COPILOT_API_TOKEN" -H "Content-Type: application/json" -H "Copilot-Integration-Id: vscode-chat" | jq -r ".data[].id" 2>/dev/null; then
        echo "❌ Failed to fetch GitHub Copilot models" >&2
        return 1
    fi
}
