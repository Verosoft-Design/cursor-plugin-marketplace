---
name: al-symbols
description: Download dependent AL symbol packages into the project's .alpackages folder via the AL MCP. Use when symbols are missing, after editing app.json dependencies, or to refresh symbols from a connected BC environment.
---

# Download AL symbols

Call the AL MCP tool `al_downloadsymbols` to populate the project's `.alpackages` folder.

## Decide the mode

1. **Offline / CI / no BC server access** → call with `globalSourcesOnly: true`. Pulls from Microsoft NuGet feeds and AppSource. No authentication needed.
2. **Connected to a live BC environment** → omit `globalSourcesOnly`. Reads connection details from `launch.json` if present, otherwise prompts. May trigger an interactive Entra ID sign-in (call `al_auth_login` first if it has not been done in this session).

## Resolve the project path

If the workspace contains a single AL project (one `app.json`), `al_downloadsymbols` targets it by default. If multiple projects exist, set `projectPath` explicitly to the absolute path of the `app.json` folder you want symbols for.

## Common parameter combinations

Refresh from global sources (recommended default for first-time setup or CI):

```json
{ "globalSourcesOnly": true }
```

Refresh from a specific cloud sandbox (overrides `launch.json`):

```json
{
  "projectPath": "<absolute path>",
  "environmentName": "sandbox",
  "environmentType": "Sandbox",
  "tenant": "<tenant>"
}
```

Force a complete re-download (use when symbol packages are corrupted):

```json
{ "force": true }
```

## After the call

If successful, the workspace is automatically reloaded. Recommend `/al-compile` or `/al-build` as the next step. If the call returns an authentication error, run `al_auth_login` first or pass `noCache: true`.
