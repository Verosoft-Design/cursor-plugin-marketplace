---
name: search-business-answers
description: Search curated business Q&A pairs in the knowledge base. Use when the user asks a question that is likely to have a pre-written answer (policies, FAQs, standard procedures).
disable-model-invocation: true
---

# Search business answers

Call the `search_business_answers` MCP tool.

## Minimal call

```json
{ "query": "<question or topic>" }
```

## Full parameter reference

| Parameter | Type | Default | Description |
|---|---|---|---|
| `query` | string | required | The question or topic to search for |
| `limit` | number | 5 | Max results (max 20) |
| `tenant_id` | string | — | Filter to a specific tenant |
| `score_threshold` | number | 0.3 | Minimum similarity score (0–1). Use 0.6+ for exact policy lookups. |

## Example

```json
{
  "query": "what is the refund policy",
  "tenant_id": "acme-corp",
  "score_threshold": 0.55
}
```

## After the call

Surface the highest-scoring answer's `content` directly. Cite the `title` as the
source. If no result scores above 0.5, fall back to `search_knowledge` with the
same query.
