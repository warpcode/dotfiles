# ZenMux Provider - OpenAI-compatible
# https://zenmux.ai/docs

# env.lazy.register "ZENMUX_API_KEY" "kp show 'KeePassXC-Browser Passwords/ZenMux' -a api_key" "kp.login"

ai.providers.zenmux.api() {
    # env.lazy.load "ZENMUX_API_KEY"
    local api_path="${1:?}"
    local base_url="${ZENMUX_BASE_URL:-https://zenmux.ai/api/v1}"
    ai.providers.openai.api.base "$base_url" "$api_path" "$ZENMUX_API_KEY"
}

ai.providers.zenmux.models() {
    ai.providers.zenmux.api "/models" | jq -M '.data'
}

ai.providers.zenmux.models.free() {
    ai.providers.zenmux.models | jq -M '[.[] | select(.pricings.completion[0].value == 0 and .pricings.prompt[0].value == 0)]'
}
