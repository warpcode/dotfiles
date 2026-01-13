# Mistral AI Provider - OpenAI-compatible
# https://docs.mistral.ai/api/api-reference

env.lazy.register "MISTRAL_API_KEY" "kp show 'KeePassXC-Browser Passwords/MistralAI' -a api_key" "kp.login"

ai.providers.mistral.api() {
    # env.lazy.load "MISTRAL_API_KEY"
    local api_path="${1:?}"
    local base_url="${MISTRAL_BASE_URL:-https://api.mistral.ai/v1}"
    ai.providers.openai.api.base "$base_url" "$api_path" "$MISTRAL_API_KEY"
}

ai.providers.mistral.models() {
    ai.providers.mistral.api "/models" | jq -M '.data'
}
