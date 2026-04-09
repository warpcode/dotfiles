# Context7 Recipe
# https://mcp.context7.com

ai.mcp.define "context7" \
    "type=remote" \
    "url=https://mcp.context7.com/mcp" \
    "description=Remote context enhancement and documentation search"

ai.mcps.context7.enabled() {
    [[ -n "$CONTEXT7_API_KEY" ]] || return 1
    return 0
}

ai.mcps.context7.config() {
    echo "headers: { \"CONTEXT7_API_KEY\": \"$CONTEXT7_API_KEY\" }"
}
