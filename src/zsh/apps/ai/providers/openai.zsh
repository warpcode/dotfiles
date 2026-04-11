# OpenAI Provider - Base API + wrapper
# https://platform.openai.com/docs/api-reference

secrets.register "OPENAI_API_KEY" \
    "openai-api" \
    "kp show 'KeePassXC-Browser Passwords/ChatGPT' -a api_key_docker"

ai.provider.define "openai" \
    "name=OpenAI" \
    "base_url=https://api.openai.com/v1" \
    "openai_compatible=true" \
    "api_key_env=OPENAI_API_KEY" \
    "priority=40"

ai.providers.openai.enabled() {
    [[ -n "${OPENAI_API_KEY:-}" ]]
}

ai.providers.openai.credentials() {
    secrets.resolve "OPENAI_API_KEY"
}

