---
name: al-build
description: Build the AL project and produce a .app package via the AL MCP. Use when the goal is a deployable artifact — before publishing, before delivering to a release artifact store, or to validate that the full pipeline (including .app generation) succeeds.
---

# Build AL (produce `.app`)

Call the AL MCP tool `al_build`. This produces a `.app` file (only when the build has no errors) plus diagnostics. For fast validation without a `.app`, use `/al-compile` instead.

## Scope

- `"current"` (default) — build the active project only.
- `"all"` — build every project in the workspace in dependency order, one `.app` per project.

## Common parameter combinations

Build the active project, errors only:

```json
{ "scope": "current", "onlyErrors": true }
```

Build with analyzers enabled (use the same analyzer set the user's `ruleset.json` expects):

```json
{
  "scope": "current",
  "enableCodeAnalysis": true,
  "codeAnalyzers": ["${CodeCop}", "${AppSourceCop}"]
}
```

Build everything in the workspace:

```json
{ "scope": "all" }
```

Build a specific project with a custom output path:

```json
{
  "projectPath": "<absolute path to app.json folder>",
  "outputPath": "<absolute path to output dir>"
}
```

## Analyzer placeholders

Pass these literal strings (with dollar-brace) in `codeAnalyzers`:

- `${CodeCop}`
- `${AppSourceCop}` — only meaningful for AppSource apps
- `${PerTenantExtensionCop}` — only meaningful for PTEs
- `${UICop}`

If the workspace has a `rulesetFile` configured (e.g. via `/al-apply-rulesets`), the analyzers' exception list is honored automatically.

## After the call

The response includes `{ success, diagnostics[] }`. The `.app` file lands in the output directory (or `app.json`'s default output folder) only when the build has zero errors. Warnings do not block the `.app`.

On success, recommend `/al-publish-sandbox` to deploy. On failure, follow up with `/al-diagnostics` for the full diagnostic list.

## Symbol prerequisites

If the build fails with "symbol not found" errors, the project's `.alpackages` folder is missing or stale. Run `/al-symbols` first, then retry.
