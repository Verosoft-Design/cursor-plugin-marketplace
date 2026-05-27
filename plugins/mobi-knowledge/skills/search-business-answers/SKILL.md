---
name: search-business-answers
description: DEPRECATED — do not call search_business_answers. The hosted server returns a Qdrant named-vector error. Use search-knowledge instead for FAQ and procedural questions.
disable-model-invocation: true
---

# Search business answers (deprecated)

**Do not call `search_business_answers`.** The hosted MCP server returns:

```
Collection requires specified vector name in the request, available names: answer, question
```

Use `search_knowledge` instead for FAQ-style and procedural questions:

```json
{
  "query": "<question or topic>",
  "limit": 5,
  "score_threshold": 0.3
}
```

For BC-specific Q&A, use `search_bc_knowledge`.

This skill remains only so slash-invocations redirect to the working tool. Follow
the `search-knowledge` skill for parameters and examples.
