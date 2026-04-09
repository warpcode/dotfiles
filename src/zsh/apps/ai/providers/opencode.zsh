# OpenCode Provider - OpenAI-compatible
# https://opencode.ai/docs

ai.provider.define "opencode" \
    "name=OpenCode" \
    "base_url=https://opencode.ai/zen/v1" \
    "openai_compatible=true" \
    "priority=10"

ai.providers.opencode.models.free() {
    ai.providers.opencode.models | jq -M '[.[] | select(.id | (endswith("-free") // . == "big-pickle" // startswith("grok-code") // . == "gpt-5-nano"))]'
}
