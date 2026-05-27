---
name: search-bc-knowledge
description: Semantic search over the TAG Business Central (BC) knowledge base — AL extensions, customisations, integration patterns, and BC-specific configuration. Use when the task involves Business Central, AL code, tag-bc, codeunits, tables, pages, or .al files.
disable-model-invocation: true
---

# Search BC knowledge

Call the `search_bc_knowledge` MCP tool on the **Mobi Knowledge Base** server.

## Minimal call

```json
{ "query": "<natural language question>" }
```

## Full parameter reference

| Parameter         | Type   | Default  | Description                        |
| ----------------- | ------ | -------- | ---------------------------------- |
| `query`           | string | required | Natural language question or topic |
| `limit`           | number | 5        | Max results (max 20)               |
| `tenant_id`       | string | —        | Filter to a specific tenant        |
| `category`        | string | —        | Filter by document category        |
| `score_threshold` | number | 0.3      | Minimum similarity score (0–1)     |

## Example

```json
{
  "query": "work order posting flow",
  "category": "relationships",
  "limit": 5,
  "score_threshold": 0.4
}
```

## After the call

Results include `title`, `file_name`, `file_path`, `layer`, `category`, `tags`, and `score`. Cite `title` + `file_path` as the source. If `score` < 0.4, run a second query with a more specific AL object or domain term.
