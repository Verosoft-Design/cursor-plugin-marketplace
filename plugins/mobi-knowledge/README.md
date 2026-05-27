# mobi-knowledge

Cursor plugin that gives agents semantic search over the Verosoft/Mobi Qdrant knowledge base.

## What it provides

- **Rules** — tells the agent when and how to call the MCP search tools
- **Skills** — slash-invokable search workflows for common queries

The MCP server is hosted on Vercel at `https://verovia.ai/api/mcp-kb/mcp`. This plugin wires it in via `mcp.json` so Cursor marketplace installs pick it up automatically.

## Collections available

| Collection            | What's in it                                 |
| --------------------- | -------------------------------------------- |
| `knowledge_base`      | Main product/process/documentation knowledge |
| `business_answers`    | Curated Q&A pairs                            |
| `document_chunks`     | User-uploaded files (PDF, Word, Excel)       |
| `connector_knowledge` | Per-connector knowledge                      |
| `connector_actions`   | Available connector actions                  |
| `connector_specs`     | Connector specifications                     |
| `agent_memories`      | Agent memory store                           |
| `user_memories`       | Per-user memory                              |
| `tool_memories`       | Tool usage memory                            |
| `daily_notes`         | Daily notes                                  |

## MCP server

The hosted endpoint is `https://verovia.ai/api/mcp-kb/mcp` (Streamable HTTP on Vercel). Authentication uses a Bearer token in the `Authorization` header.

Installing this plugin from the marketplace loads `mcp.json` automatically. After install, restart Cursor (Cmd+Q and reopen) so the MCP server is picked up.

To override credentials locally, use an env var in your user or workspace MCP config:

```json
{
  "mcpServers": {
    "Mobi Knowledge Base": {
      "url": "https://verovia.ai/api/mcp-kb/mcp",
      "headers": {
        "Authorization": "Bearer ${env:MOBI_KNOWLEDGE_MCP_TOKEN}"
      }
    }
  }
}
```

For Linear cloud agents, add the same URL under **Integrations → MCP Servers** in the Cursor dashboard.

## Tools exposed

| Tool                      | Description                                                                    |
| ------------------------- | ------------------------------------------------------------------------------ |
| `search_knowledge`        | Search `knowledge_base` with optional `tenant_id`, `category`, `layer` filters |
| `search_business_answers` | Search curated Q&A pairs                                                       |
| `search_documents`        | Search uploaded document chunks                                                |
| `search_collection`       | Search any named collection with arbitrary filters                             |
| `list_collections`        | Discover available collections                                                 |
