---
name: search-knowledge
description: Semantic search over the main knowledge_base collection. Use when the agent or user needs to find documentation, product information, processes, or any stored organisational knowledge.
disable-model-invocation: true
---

# Search the knowledge base

Call the `search_knowledge` MCP tool.

## Minimal call

```json
{ "query": "<natural language question>" }
```

## Full parameter reference

| Parameter | Type | Default | Description |
|---|---|---|---|
| `query` | string | required | Natural language question or topic |
| `limit` | number | 5 | Max results (max 20) |
| `tenant_id` | string | — | Filter to a specific tenant |
| `category` | string | — | Filter by document category |
| `layer` | string | — | Filter by knowledge layer |
| `score_threshold` | number | 0.3 | Minimum similarity score (0–1) |

## Example — with filters

```json
{
  "query": "how does invoice approval work",
  "tenant_id": "acme-corp",
  "category": "finance",
  "limit": 5,
  "score_threshold": 0.5
}
```

## After the call

Results include `title`, `heading`, `content`, `prev_context`, `next_context`,
`score`, and `tags`. Present the most relevant `content` blocks and cite the
`title` + `heading` as the source. If `score` < 0.4, note that confidence is low.
