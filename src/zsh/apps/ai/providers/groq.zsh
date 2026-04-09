# Groq Provider - OpenAI-compatible
# https://console.groq.com/docs/api-reference

ai.provider.define "groq" \
    "name=Groq" \
    "base_url=https://api.groq.com/openai/v1" \
    "openai_compatible=true"

ai.providers.groq.enabled() {
    # Personal use
    [[ "$IS_WORK" == "1" ]] && return 1
    return 0
}

ai.providers.groq.credentials() {
    secrets.resolve "GROQ_API_KEY"
}

