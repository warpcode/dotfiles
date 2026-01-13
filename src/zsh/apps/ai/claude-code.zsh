##
# Run Claude Code with default settings
# @param ... Arguments passed to claude-code
##
ai.claude() {
    npx -y @anthropic-ai/claude-code "$@"
}

##
# Run Claude Code using LiteLLM endpoint
# @param ... Arguments passed to claude-code
##
ai.claude.litellm() {
    ANTHROPIC_BASE_URL="${LITELLM_BASE_URL}" \
    ANTHROPIC_AUTH_TOKEN="${LITELLM_API_KEY}" \
    ANTHROPIC_MODEL="qwen3-coder" \
    ANTHROPIC_SMALL_FAST_MODEL="qwen3-coder" \
    npx -y @anthropic-ai/claude-code "$@"
}
