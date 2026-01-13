# LiteLLM Provider - Aggregator for 100+ providers
# https://docs.litellm.ai/docs/proxy_server

# env.lazy.register "LITELLM_API_KEY" "kp show 'KeePassXC-Browser Passwords/LiteLLM' -a api_key" "kp.login"

ai.providers.litellm.api() {
    # env.lazy.load "LITELLM_API_KEY"
    local api_path="${1:?}"
    local base_url="${LITELLM_BASE_URL:-http://localhost:4000}"
    ai.providers.openai.api.base "$base_url" "$api_path" "$LITELLM_API_KEY"
}

ai.providers.litellm.models() {
    local raw_json
    raw_json=$(ai.providers.litellm.api "/models")

    if [[ $? -ne 0 || -z "$raw_json" ]]; then
        echo "❌ Failed to fetch LiteLLM models" >&2
        return 1
    fi

    # Output filtered models as JSON array
    echo "$raw_json" | jq -M '[.data[] | select(
        if (.id | test("^[^/]+/[*]"; "x")) then false
        elif (.id | test("-[0-9]{4}-?[0-9]{2}-?[0-9]{2}"; "x")) then false
        elif (.id | test("-[0-9]{2}-202[0-9]"; "x")) then false
        elif (.id | test("-[0-9]{2}-[0-9]{2}"; "x")) then false
        elif (.id | test("-[0-9]{3,4}$"; "x")) then false
        elif (.id | test("/[0-9]{3,4}-?x-?[0-9]{3,4}/"; "x")) then false
        elif (.id | test("-preview-"; "x")) then false
        else true end
    )]'
}

ai.providers.litellm.models.free() {
    ai.providers.litellm.api "/models" | jq -M '[.data[] | select(.id | endswith(":free"))]'
}
