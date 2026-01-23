# OpenAI Provider - Base API + wrapper
# https://platform.openai.com/docs/api-reference

env.lazy.register "OPENAI_API_KEY" "kp show 'KeePassXC-Browser Passwords/ChatGPT' -a api_key_docker" "kp.login"

# Base function for all OpenAI-compatible APIs
# Args: base_url api_path api_key [extra_headers...]
ai.providers.openai.api.base() {
    local base_url="${1:?}"
    local api_path="${2:?}"
    local api_key="${3:-}"
    shift 3
    local extra_headers=("$@")

    local curl_args=(
        --fail --silent
        "${base_url%/}${api_path}"
        -H "Content-Type: application/json"
    )

    [[ -n "$api_key" ]] && curl_args+=(-H "Authorization: Bearer ${api_key}")

    for header in "${extra_headers[@]}"; do
        curl_args+=($header)
    done

    curl "${curl_args[@]}"
}

# OpenAI-specific wrapper with lazy key loading
ai.providers.openai.api() {
    env.lazy.load "OPENAI_API_KEY"
    local api_path="${1:?}"
    local base_url="${OPENAI_BASE_URL:-https://api.openai.com/v1}"
    ai.providers.openai.api.base "$base_url" "$api_path" "$OPENAI_API_KEY"
}

ai.providers.openai.models() {
    ai.providers.openai.api "/models" | jq -M '.data'
}
