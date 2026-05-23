# Groq Provider - OpenAI-compatible
# https://console.groq.com/docs/api-reference

ai.provider.define "groq" \
    "name=Groq" \
    "base_url=https://api.groq.com/openai/v1" \
    "openai_compatible=true" \
    "api_key_env=GROQ_API_KEY" \
    "priority=30"

ai.providers.groq.enabled() {
    [[ -n "${GROQ_API_KEY:-}" ]]
}

ai.providers.groq.credentials() {
    "$DOTFILES/bin/df.keepass" get "AI/Groq" "api_key"
}

