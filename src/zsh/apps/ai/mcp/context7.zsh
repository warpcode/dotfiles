# Context7 Recipe
# https://mcp.context7.com

ai.mcp.define "context7" \
    "type=remote" \
    "url=https://mcp.context7.com/mcp" \
    "api_key_header=CONTEXT7_API_KEY" \
    "description=Remote context enhancement and documentation search"

# ai.mcps.context7.enabled() {
#     [[ -n "$CONTEXT7_API_KEY" ]]
# }
