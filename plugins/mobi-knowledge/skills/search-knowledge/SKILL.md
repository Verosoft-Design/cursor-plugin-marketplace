---
name: search-knowledge
description: Semantic search over the Mobi product knowledge base — configuration guides, frontend flows, feature docs, and organisational knowledge. Use for platform, frontend, API, connector, or "how do I" questions. Prefer this over search_business_answers.
disable-model-invocation: true
---

# Search the knowledge base

Call the `search_knowledge` MCP tool on the **Mobi Knowledge Base** server.

## Minimal call

```json
{ "query": "<natural language question>" }
```

## Full parameter reference

| Parameter         | Type   | Default  | Description                                                                   |
| ----------------- | ------ | -------- | ----------------------------------------------------------------------------- |
| `query`           | string | required | Natural language question or topic                                            |
| `limit`           | number | 5        | Max results (max 20)                                                          |
| `tenant_id`       | string | —        | Filter to a specific tenant                                                   |
| `category`        | string | —        | Filter by document category (`overview`, `integration`, `api`, `guide`, etc.) |
| `layer`           | string | —        | Filter by knowledge layer                                                     |
| `score_threshold` | number | 0.3      | Minimum similarity score (0–1)                                                |

## Layer hints

| Layer                   | Use for                                 |
| ----------------------- | --------------------------------------- |
| `layer1-configuration`  | Setup, admin, configuration             |
| `layer2-frontend-flows` | UI flows, user guides, "how do I" steps |
| `business_logic`        | Domain rules and behaviour              |

## Example — "how do I" with layer

```json
{
  "query": "how do I create a work order",
  "layer": "layer2-frontend-flows",
  "limit": 5,
  "score_threshold": 0.3
}
```

## Example — with filters

```json
{
  "query": "how does invoice approval work",
  "tenant_id": "acme-corp",
  "category": "guide",
  "limit": 5,
  "score_threshold": 0.5
}
```

## After the call

Results include `title`, `file_name`, `file_path`, `layer`, `category`, `tags`,
and `score`. Present the most relevant content and cite `title` + `file_path`.
If `score` < 0.4, broaden the query or drop the `layer` filter and retry.

If results are thin, run a second query with a more specific term from the issue.
