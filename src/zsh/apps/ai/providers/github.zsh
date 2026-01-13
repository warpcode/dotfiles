# GitHub Models Provider - OpenAI-compatible
# https://docs.github.com/en/rest/models/catalog

env.lazy.register "GITHUB_API_KEY" "kp show 'KeePassXC-Browser Passwords/Github' -a api_key_docker_ai" "kp.login"

ai.providers.github.api() {
    env.lazy.load "GITHUB_API_KEY"
    local api_path="${1:?}"
    local base_url="${GITHUB_BASE_URL:-https://models.github.ai}"
    ai.providers.openai.api.base "$base_url" "$api_path" "$GITHUB_API_KEY" \
        "-H" "Accept: application/vnd.github+json" \
        "-H" "X-GitHub-Api-Version: 2022-11-28"
}

ai.providers.github.models() {
    ai.providers.github.api "/catalog/models"
}
