# Ollama Provider - Local inference, no auth
# https://github.com/ollama/ollama/blob/main/docs/api.md

ai.providers.ollama.api() {
    local api_path="${1:?}"
    local base_url="${OLLAMA_BASE_URL:-http://localhost:11434}"
    command curl --fail -s "${base_url%/}${api_path}" -H "Content-Type: application/json"
}

ai.providers.ollama.models() {
    ai.providers.ollama.api "/api/tags" | jq -M '.models'
}

ai.providers.ollama.models.free() {
    # Ollama is local - all models are "free" (no API costs)
    ai.providers.ollama.models
}
