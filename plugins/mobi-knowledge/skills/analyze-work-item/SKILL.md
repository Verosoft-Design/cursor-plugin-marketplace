---
name: analyze-work-item
description: Analyze, investigate, or research a work item by searching the Mobi and BC knowledge bases and relevant code. Use when the user asks to analyze an issue, ticket, task, bug, feature request, or Linear work item and needs documentation context plus code locations.
---

# Analyze Work Item

When asked to analyze, investigate, research, or provide context for a work item, follow these steps:

## 1 — Identify the codebase

**BC / AL** if the issue has a `tag-bc` label, mentions Business Central, AL code, codeunits, tables, pages, or `.al` files → use BC tools below.

**Mobi** otherwise (platform, frontend, API, connectors, configuration) → use Mobi tools below.

If the issue clearly spans both, run both sets of searches.

## 2 — Search the knowledge base

Call the **Mobi Knowledge Base** MCP tools. Do **not** call `search_business_answers` — it is currently broken on the server (Qdrant named-vector error). Use the tools below instead.

**BC issue** → call `search_bc_knowledge`

(The tool automatically filters to BC documentation — no extra filter needed.)

- First query: the core concept from the issue title
- Second query (if needed): the specific AL object or domain mentioned (e.g. "work order posting", "equipment fault")

**Mobi issue** → call `search_knowledge`

- First query: the core concept from the issue title
- Use `layer` when the domain is clear: `layer1-configuration`, `layer2-frontend-flows`, `business_logic`, etc.
- Use `category` for scoped docs: `overview`, `integration`, `api`, `guide`, etc.

For "how do I …" product questions, always start with `search_knowledge` — not `search_business_answers`.

## 3 — Search for relevant code

**BC issue** → search `Verosoft-Design/tag-bc`

- Look for AL objects, codeunits, tables, or pages mentioned in the issue
- If it's a bug or regression, check recent commits touching those objects

**Mobi issue** → search `Verosoft-Design/mobi`

- Look for TypeScript files, API routes, components, or services related to the issue
- Check `packages/` for shared logic, `apps/mobi/src` for frontend, `apps/verovia/src/app/api` for API routes

Use whatever code-search tools are available in the current session (`Grep`, `SemanticSearch`, `gh`, etc.).

## 4 — Return a structured analysis

Your response should include:

- **Knowledge base findings** — relevant documentation, business logic, configuration patterns, or Q&A matches found
- **Code locations** — specific files, functions, codeunits, or objects in GitHub that are directly relevant
- **Suggested approach** — where to start, what to look at, any known patterns or gotchas to follow
- **Open questions** — anything the issue is missing that would help scope the work (acceptance criteria, affected tenants, related issues)
