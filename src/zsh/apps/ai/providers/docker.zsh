# Docker AI Provider - Local inference, no auth
# https://github.com/go-skynet/go-llama.cpp

ai.providers.docker.api() {
    local api_path="${1:?}"
    local base_url="${DOCKER_BASE_URL:-http://localhost:12434/engines/llama.cpp/v1}"
    ai.providers.openai.api.base "$base_url" "$api_path" ""
}

ai.providers.docker.models() {
    ai.providers.docker.api "/models" | jq -M '.data'
}

ai.providers.docker.models.free() {
    # Docker AI is local - all models are "free" (no API costs)
    ai.providers.docker.models
}
