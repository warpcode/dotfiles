# OpenRouter Provider - Aggregator with free models
# https://openrouter.ai/docs/api (no API key for models)

env.lazy.register "OPENROUTER_API_KEY" "kp show 'KeePassXC-Browser Passwords/ChatGPT' -a api_key_docker_ai" "kp.login"

ai.providers.openrouter.api() {
    local api_path="${1:?}"
    local base_url="${OPENROUTER_BASE_URL:-https://openrouter.ai/api/v1}"
    ai.providers.openai.api.base "$base_url" "$api_path" "$OPENROUTER_API_KEY"
}

ai.providers.openrouter.models() {
    ai.providers.openrouter.api "/models" | jq -M '.data'
}

ai.providers.openrouter.models.free() {
    ai.providers.openrouter.models | jq -M '[.[] | select(.pricing.prompt == "0" and .pricing.completion == "0")]'
}
