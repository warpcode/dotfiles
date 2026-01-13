# Groq Provider - Fast inference, OpenAI-compatible
# https://console.groq.com/docs/api

env.lazy.register "GROQ_API_KEY" "kp show 'KeePassXC-Browser Passwords/Groq' -a api_key_docker" "kp.login"

ai.providers.groq.api() {
    env.lazy.load "GROQ_API_KEY"
    local api_path="${1:?}"
    local base_url="${GROQ_BASE_URL:-https://api.groq.com/openai/v1}"
    ai.providers.openai.api.base "$base_url" "$api_path" "$GROQ_API_KEY"
}

ai.providers.groq.models() {
    ai.providers.groq.api "/models" | jq -M '.data'
}
