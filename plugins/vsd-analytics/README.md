# vsd-analytics

Cursor plugin that wires analytics MCP servers for Verosoft product investigation.

## What it provides

- **LogRocket MCP** — session replay and product analytics tools via `https://mcp.logrocket.com/mcp`

Skills and rules will be added later. For now this plugin only registers the MCP server.

## MCP server

Installing this plugin from the marketplace loads `mcp.json` automatically. After install, restart Cursor (Cmd+Q and reopen) so the MCP server is picked up.

```json
{
  "mcpServers": {
    "logrocket": {
      "type": "http",
      "url": "https://mcp.logrocket.com/mcp"
    }
  }
}
```

Authenticate with LogRocket when Cursor prompts for MCP auth (OAuth or API key, depending on LogRocket's MCP setup).

## Install

1. Add this marketplace (or refresh it) in Cursor.
2. Install **vsd-analytics**.
3. Fully restart Cursor so the `logrocket` MCP server starts.
