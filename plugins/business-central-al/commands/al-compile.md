---
name: al-compile
description: Validate AL code without producing a .app package via the AL MCP. Faster than al-build. Use when the goal is to surface compile errors and analyzer findings quickly (PR gate, save-time check, before iterating on a fix).
---

# Compile AL (validate only)

Call the AL MCP tool `al_compile`. Unlike `al_build`, this does NOT produce a `.app` file — it is purely a validation pass and runs faster.

## Decide whether to enable analyzers

- **Errors only, no analyzers** (fastest, default): omit `enableCodeAnalysis`.
- **Errors + a specific analyzer** (e.g. AppSourceCop gate before release): set `enableCodeAnalysis: true` and pass the analyzers you want.

The analyzer placeholders are literal strings with dollar-brace syntax: `"${CodeCop}"`, `"${AppSourceCop}"`, `"${PerTenantExtensionCop}"`, `"${UICop}"`.

## Common parameter combinations

Fast validation (PR gate):

```json
{ "onlyErrors": true, "maxDiagnosticsPerCompilation": 100 }
```

AppSourceCop gate:

```json
{
  "onlyErrors": false,
  "enableCodeAnalysis": true,
  "codeAnalyzers": ["${AppSourceCop}"]
}
```

Full strictness (all analyzers, all severities):

```json
{
  "onlyErrors": false,
  "enableCodeAnalysis": true,
  "codeAnalyzers": [
    "${CodeCop}",
    "${AppSourceCop}",
    "${PerTenantExtensionCop}",
    "${UICop}"
  ]
}
```

## Workspace with multiple projects

Pass `projectPath` (absolute path to the `app.json` folder) when the workspace contains more than one AL project. Without it, the tool targets "the first project in the workspace" which may be wrong.

## After the call

The response includes `{ Succeeded, Diagnostics: [{ Severity, Code, Location, Description }], Message }`. When errors are present, follow up with `/al-diagnostics` (or call `al_getdiagnostics` directly) for the full filtered list. When no errors, recommend `/al-build` if a `.app` is needed.
