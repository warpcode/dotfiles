# OpenAI Provider - Base API + wrapper
# https://platform.openai.com/docs/api-reference

secrets.register "OPENAI_API_KEY" \
    "openai-api" "default" \
    "kp show 'KeePassXC-Browser Passwords/ChatGPT' -a api_key_docker"

ai.provider.define "openai" \
    "name=OpenAI" \
    "base_url=https://api.openai.com/v1" \
    "openai_compatible=true"

ai.providers.openai.enabled() {
    [[ "$IS_WORK" == "1" ]] && return 1
    return 0
}

ai.providers.openai.credentials() {
    secrets.resolve "OPENAI_API_KEY"
}

