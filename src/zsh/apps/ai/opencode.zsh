# OpenCode CLI

alias ai.code='ai.opencode'

ai.opencode() {
    local model="opencode/glm-4.7-free"

    if [[ "$IS_WORK" == "1" ]]; then
        local git_user
        git_user=$(git config user.name 2>/dev/null || echo "")
        if [[ "${git_user:l}" != "warpcode" ]]; then
            model="github-copilot/gpt-5-mini"
        fi
    fi

    OPENCODE_MODEL="$model" npx -y opencode-ai@latest "$@"
}
