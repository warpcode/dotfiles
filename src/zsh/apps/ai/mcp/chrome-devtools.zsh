# Chrome DevTools MCP Recipe
# https://github.com/modelcontextprotocol/servers/tree/main/src/chrome-devtools

ai.mcp.define "chrome-devtools" \
    "command=npx -y chrome-devtools-mcp@latest --autoConnect" \
    "type=local" \
    "description=Chrome DevTools protocol integration for browser interaction"
