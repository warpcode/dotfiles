# OpenCode Provider - OpenAI-compatible
# https://opencode.ai/docs

# env.lazy.register "OPENCODE_API_KEY" "kp show 'KeePassXC-Browser Passwords/OpenCode' -a api_key" "kp.login"

ai.providers.opencode.api() {
    # env.lazy.load "OPENCODE_API_KEY"  # Uncomment when API key is needed
    local api_path="${1:?}"
    local base_url="${OPENCODE_BASE_URL:-https://opencode.ai/zen/v1}"
    ai.providers.openai.api.base "$base_url" "$api_path" ""
}

ai.providers.opencode.models() {
    ai.providers.opencode.api "/models" | jq -M '.data'
}

ai.providers.opencode.models.free() {
    ai.providers.opencode.models | jq -M '[.[] | select(.id | (endswith("-free") // . == "big-pickle" // startswith("grok-code") // . == "gpt-5-nano"))]'
}
