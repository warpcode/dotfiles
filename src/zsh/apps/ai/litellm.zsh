ai.litellm.models() {
    if ! curl --fail -s "$LITELLM_API_ENDPOINT/models" -H "Authorization: Bearer $LITELLM_API_KEY" -H "Content-Type: application/json" | jq -r ".data[].id" 2>/dev/null; then
        echo "❌ Failed to fetch LiteLLM models from $LITELLM_API_ENDPOINT" >&2
        return 1
    fi
}
