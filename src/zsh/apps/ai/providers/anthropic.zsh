# Anthropic Provider - Custom headers, direct array response
# https://docs.anthropic.com/api/models

env.lazy.register "ANTHROPIC_API_KEY" "kp show 'KeePassXC-Browser Passwords/Anthropic' -a api_key" "kp.login"

ai.providers.anthropic.api() {
    env.lazy.load "ANTHROPIC_API_KEY"
    local api_path="${1:?}"
    local base_url="${ANTHROPIC_BASE_URL:-https://api.anthropic.com}"
    ai.providers.openai.api.base "$base_url" "$api_path" "$ANTHROPIC_API_KEY" \
        "-H" "x-api-key: ${ANTHROPIC_API_KEY}" \
        "-H" "anthropic-version: 2023-06-01"
}

ai.providers.anthropic.models() {
    ai.providers.anthropic.api "/v1/models"
}
