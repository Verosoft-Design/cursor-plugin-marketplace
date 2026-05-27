# mobi-knowledge

Cursor plugin that gives agents semantic search over the Verosoft/Mobi Qdrant knowledge base.

## What it provides

- **Rules** — tells the agent when and how to call the MCP search tools
- **Skills** — slash-invokable search workflows for common queries

The MCP server itself lives in the mobi monorepo at `apps/mobi-knowledge-mcp` and is deployed to Vercel.

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

## MCP server setup

The server is deployed via Vercel from `mobi/apps/qdrant-mcp`. Set these env vars in the Vercel dashboard:

| Variable         | Value                      |
| ---------------- | -------------------------- |
| `QDRANT_URL`     | `https://qdrant.veliox.ai` |
| `QDRANT_API_KEY` | Qdrant API key             |
| `GEMINI_API_KEY` | Google AI / Gemini API key |

Once deployed, the MCP endpoint is at `https://<your-deployment>.vercel.app/mcp`.

### Connecting to Cursor (local desktop)

```json
{
  "mcpServers": {
    "mobi-knowledge": {
      "url": "https://<your-deployment>.vercel.app/mcp"
    }
  }
}
```

### Connecting to Linear cloud agents

Add the same URL in the Cursor dashboard under **Integrations → MCP Servers** as a remote server. Linear agents pick it up automatically.

## Tools exposed

| Tool                      | Description                                                                    |
| ------------------------- | ------------------------------------------------------------------------------ |
| `search_knowledge`        | Search `knowledge_base` with optional `tenant_id`, `category`, `layer` filters |
| `search_business_answers` | Search curated Q&A pairs                                                       |
| `search_documents`        | Search uploaded document chunks                                                |
| `search_collection`       | Search any named collection with arbitrary filters                             |
| `list_collections`        | Discover available collections                                                 |
