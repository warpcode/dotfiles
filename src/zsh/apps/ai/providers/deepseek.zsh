# Deepseek Provider - OpenAI-compatible
# https://api.deepseek.com/docs/api

env.lazy.register "DEEPSEEK_API_KEY" "kp show 'KeePassXC-Browser Passwords/Deepseek' -a api_key_docker" "kp.login"

ai.providers.deepseek.api() {
    env.lazy.load "DEEPSEEK_API_KEY"
    local api_path="${1:?}"
    local base_url="${DEEPSEEK_BASE_URL:-https://api.deepseek.com/v1}"
    ai.providers.openai.api.base "$base_url" "$api_path" "$DEEPSEEK_API_KEY"
}

ai.providers.deepseek.models() {
    ai.providers.deepseek.api "/models" | jq -M '.data'
}
