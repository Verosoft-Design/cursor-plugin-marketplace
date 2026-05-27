---
name: search-collection
description: Low-level semantic search over any named Qdrant collection. Use when you need connector_knowledge, connector_specs, agent_memories, user_memories, tool_memories, daily_notes, or any other collection not covered by the higher-level search skills.
disable-model-invocation: true
---

# Search a specific collection

Call the `search_collection` MCP tool.

## Available collections

`knowledge_base`, `document_chunks`, `connector_actions`,
`connector_knowledge`, `connector_specs`, `agent_memories`, `user_memories`,
`tool_memories`, `daily_notes`, `search_analytics`, `marketplace_connectors`

Do **not** search `business_answers` via this tool — the collection uses named
vectors and the server does not pass a vector name. Use `search_knowledge` instead.

## Minimal call

```json
{
  "collection": "connector_knowledge",
  "query": "<what to find>"
}
```

## Full parameter reference

| Parameter         | Type   | Default  | Description                       |
| ----------------- | ------ | -------- | --------------------------------- |
| `collection`      | string | required | One of the collection names above |
| `query`           | string | required | Natural language search query     |
| `limit`           | number | 5        | Max results (max 20)              |
| `filter`          | object | —        | Key-value payload filter          |
| `score_threshold` | number | 0.3      | Minimum similarity score (0–1)    |

## Example — connector knowledge with filter

```json
{
  "collection": "connector_knowledge",
  "query": "authentication flow",
  "filter": { "connector_id": "salesforce" },
  "limit": 5,
  "score_threshold": 0.4
}
```

## Example — user memories

```json
{
  "collection": "user_memories",
  "query": "preferred communication style",
  "filter": { "userId": "user-123", "tenantId": "acme-corp" }
}
```

## When unsure which collection to use

Call `list_collections` first, then choose the most relevant one.
