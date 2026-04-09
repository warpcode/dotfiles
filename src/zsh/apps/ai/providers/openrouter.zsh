# OpenRouter Provider - Aggregator with free models
# https://openrouter.ai/docs/api

ai.provider.define "openrouter" \
    "name=OpenRouter" \
    "base_url=https://openrouter.ai/api/v1" \
    "openai_compatible=true" \
    "api_key_env=OPENROUTER_API_KEY" \
    "priority=20"

ai.providers.openrouter.enabled() {
    [[ -n "${OPENROUTER_API_KEY:-}" ]]
}

ai.providers.openrouter.credentials() {
    secrets.resolve "OPENROUTER_API_KEY"
}

ai.providers.openrouter.models.free() {
    ai.providers.openrouter.models | jq -M '[.[] | select(.pricing.prompt == "0" and .pricing.completion == "0")]'
}
