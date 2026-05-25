---
name: al-symbol-search
description: Search AL symbols (objects, fields, methods, keys, actions, triggers) across the project and its dependencies via the AL MCP. Use when the agent needs to locate a codeunit, table, page, enum, interface, or member by name, namespace, or documentation text.
disable-model-invocation: true
---

# Search AL symbols

Call the AL MCP tool `al_symbolsearch`.

## Critical: parameter wrapping

`al_symbolsearch` is the ONLY AL MCP tool that requires its arguments inside a `parameters` key. Every other tool takes arguments at the top level. Use this exact shape:

```json
{
  "parameters": {
    "query": "Post",
    "filters": {
      "kinds": ["Codeunit"],
      "scope": "project"
    }
  }
}
```

## Available filters (all optional)

| Filter          | Values                                                                                                                                                         |
| --------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `kinds`         | `"Table"`, `"Codeunit"`, `"Page"`, `"Report"`, `"Query"`, `"Enum"`, `"Interface"`, `"XmlPort"`, `"PageExtension"`, `"TableExtension"`, `"EnumExtension"`, etc. |
| `objectName`    | Restrict to members of a named object.                                                                                                                         |
| `memberKinds`   | `"Field"`, `"Method"`, `"Key"`, `"Action"`, `"Trigger"`.                                                                                                       |
| `namespace`     | Restrict to a specific namespace.                                                                                                                              |
| `access`        | `"Public"`, `"Internal"`.                                                                                                                                      |
| `obsoleteState` | `"No"`, `"Pending"`, `"Removed"`. Obsolete symbols included by default.                                                                                        |
| `match`         | `"name"` (default), `"doc"` (XML doc summaries), `"all"`.                                                                                                      |
| `scope`         | `"project"`, `"dependencies"`, `"all"` (default).                                                                                                              |
| `limit`         | Integer ≤ 200.                                                                                                                                                 |

## Common query shapes

Find all codeunits matching a keyword in the current project:

```json
{
  "parameters": {
    "query": "Post",
    "filters": { "kinds": ["Codeunit"], "scope": "project" }
  }
}
```

Find a specific table's fields:

```json
{
  "parameters": {
    "query": "*",
    "filters": {
      "kinds": ["Table"],
      "objectName": "Customer",
      "memberKinds": ["Field"]
    }
  }
}
```

Find public methods on an interface across dependencies:

```json
{
  "parameters": {
    "query": "*",
    "filters": {
      "kinds": ["Interface"],
      "memberKinds": ["Method"],
      "access": ["Public"],
      "scope": "dependencies"
    }
  }
}
```

Search documentation text (not just symbol names):

```json
{ "parameters": { "query": "rate limit", "filters": { "match": "doc" } } }
```

## After the call

The response includes `symbols[]` with `id`, `name`, `fullName`, `kind`, `namespace`, `containerName`, `signature`, `docSummary`, `path` per match, plus a `truncated` boolean. When `truncated: true`, narrow the filters and re-call rather than raising the `limit` blindly.
