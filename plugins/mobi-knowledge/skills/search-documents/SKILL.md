---
name: search-documents
description: Search user-uploaded document chunks (PDF, Word, Excel, media). Use when the user is looking for content from a specific uploaded file or any stored document.
disable-model-invocation: true
---

# Search uploaded documents

Call the `search_documents` MCP tool.

## Minimal call

```json
{ "query": "<content to find>" }
```

## Full parameter reference

| Parameter | Type | Default | Description |
|---|---|---|---|
| `query` | string | required | What to search for inside uploaded documents |
| `limit` | number | 5 | Max results (max 20) |
| `tenant_id` | string | — | Filter to a specific tenant |
| `scope` | string | — | Filter by scope (`"private"`, `"shared"`, etc.) |
| `score_threshold` | number | 0.3 | Minimum similarity score (0–1) |

## Example — find content in a shared document

```json
{
  "query": "onboarding checklist steps",
  "tenant_id": "acme-corp",
  "scope": "shared",
  "limit": 8
}
```

## After the call

Results include `content` (the chunk text), `chunk_index`, `prev_context`,
`next_context`, `title` (file name), and `score`. Reconstruct context by reading
`prev_context` + `content` + `next_context` when the chunk alone is insufficient.
