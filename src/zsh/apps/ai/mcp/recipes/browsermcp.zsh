# BrowserMCP Recipe
# https://github.com/browsermcp/mcp

ai.mcp.define_recipe "browsermcp" \
    "command=npx @browsermcp/mcp@latest" \
    "type=local" \
    "description=Browser control and automation via Playwright"

ai.mcp.recipes.browsermcp.enabled() {
    return 0
}
