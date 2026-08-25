# Antigravity CLI (`agy`) MCP & Plugin Administration

Detailed guide for managing Model Context Protocol (MCP) servers and Antigravity plugins via `agy`.

---

## 1. MCP Server Management (`agy mcp`)

Antigravity stores user-level MCP configuration in `~/.gemini/antigravity-cli/mcp_config.json` (or active settings profile). Use `agy mcp` subcommands to mutate configuration without editing raw JSON.

### Listing MCP Servers
```bash
agy mcp list
```

### Adding a Stdio MCP Server
Flags must precede the `<name>` argument:
```bash
agy mcp add <name> <commandOrUrl> [args...]
```

**Examples:**
```bash
# Node / npx filesystem server
agy mcp add fs npx -y @modelcontextprotocol/server-filesystem /path/to/work

# Python / uvx server
agy mcp add context-mcp uvx run context-server

# Passing environment variables (-e or --env)
agy mcp add --env GITHUB_TOKEN=ghp_secret gh npx -y @modelcontextprotocol/server-github

# Using -- before command when args begin with '-'
agy mcp add --env GITHUB_TOKEN=ghp_secret gh -- docker run -i ghcr.io/github/mcp
```

### Adding an HTTP / SSE MCP Server
HTTP endpoints are detected automatically from `http://` or `https://` URLs:
```bash
# HTTP server with authorization header
agy mcp add --header "Authorization: Bearer <token>" context7 https://mcp.context7.com/mcp
```

### Enabling, Disabling, and Removing Servers
```bash
# Enable server
agy mcp enable <name>

# Disable server
agy mcp disable <name>

# ⚠ WRITE: Permanently remove server configuration
agy mcp remove <name>
```

---

## 2. Plugin Management (`agy plugin`)

Manage plugins installed in `~/.gemini/config/plugins/` or marketplace bundles.

### Listing Plugins
```bash
agy plugin list
```

### Validating a Plugin Definition
Validate `plugin.json` schema and entrypoints:
```bash
agy plugin validate /path/to/plugin-directory
```

### Installing a Plugin
```bash
# Install from local directory
agy plugin install /path/to/plugin-directory

# Install from marketplace
agy plugin install plugin-name@marketplace-id
```

### Enabling and Disabling Plugins
```bash
agy plugin enable <name>
agy plugin disable <name>
```

### ⚠ WRITE: Uninstalling a Plugin
```bash
agy plugin uninstall <name>
```

### Generating Marketplace Links & Importing
```bash
# Generate link to a marketplace
agy plugin link <marketplace_name> <target>

# Import plugins from Claude or Gemini environments
agy plugin import gemini
agy plugin import claude
```
