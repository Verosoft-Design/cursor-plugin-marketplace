---
name: al-build-and-publish
description: Orchestrates the AL inner-development loop using the altool launchmcpserver MCP. Use when the user asks to build, compile, validate, publish, deploy, or roll an AL extension out to a sandbox or production environment, or asks the agent to download symbols, check diagnostics, or chain any of these steps together.
---

# AL Build and Publish

This skill orchestrates the AL MCP tools (`altool launchmcpserver`) into the three canonical inner-loop workflows: validate-only, build-and-deploy, and AppSourceCop quality gate.

## Tools you control

- `al_downloadsymbols` — pull dependent symbol packages into `.alpackages/`.
- `al_compile` — validate source without producing `.app`. Fastest.
- `al_build` — compile and produce a `.app`.
- `al_getdiagnostics` — list compiler/analyzer findings with filters.
- `al_publish` — deploy a `.app` to a BC environment (cloud or on-prem).
- `al_auth_login` / `al_auth_logout` — Entra ID auth for cloud operations.
- `al_symbolsearch` — locate symbols (note the `parameters` wrapper quirk).
- `al_getpackagedependencies` — list `app.json` dependencies.

For the full tool reference, parameter shapes, and gotchas, refer the agent to the `al-mcp-usage` rule.

## Decide the workflow

Pick one of the three based on the user's intent. Do not skip steps or invent new compositions unless the user asks for it.

### Workflow A — Validate only (fastest, no `.app`)

Use when: the user wants to know if the code compiles, or wants to surface lint findings without producing an artifact (PR gate, save-time check, "is this clean?").

```text
1. al_downloadsymbols  ({ "globalSourcesOnly": true })   — only if .alpackages is missing/stale
2. al_compile          ({ "onlyErrors": true })
3. al_getdiagnostics   ({ "severities": ["error"] })     — only if step 2 reports failures
```

### Workflow B — Build and deploy to sandbox

Use when: the user wants the extension running in a BC environment.

```text
1. al_auth_login       ({ "tenant": "...", "environmentType": "Sandbox", "environmentName": "..." })
2. al_downloadsymbols  (no globalSourcesOnly — refresh from the live env)
3. al_build            ({ "scope": "current" })
4. al_publish          ({ "environmentName": "...", "environmentType": "Sandbox", "tenant": "..." })
```

Skip step 1 when targeting on-prem with Windows auth. Skip step 2 when symbols are already current. Skip step 3 and pass `skipBuild: true` + `appPath` on step 4 when publishing a pre-built `.app`.

### Workflow C — AppSourceCop quality gate

Use when: the user is preparing an AppSource release and wants to confirm no AppSourceCop violations.

```text
1. al_compile          ({ "enableCodeAnalysis": true, "codeAnalyzers": ["${AppSourceCop}"] })
2. al_getdiagnostics   ({ "areas": ["AppSourceCop"] })
```

Fail the flow if step 2 returns any errors.

## Reporting back

After each tool call, summarize:

- Which tool was called.
- Whether it succeeded.
- A short list of any errors (file, line, code, message). For large diagnostic lists, group by `code` and report top counts; offer to drill in.
- The recommended next step.

## Safety rules

- Never invoke `al_publish` with `schemaUpdateMode: "Recreate"` or `"ForceSync"` without explicit user confirmation in the current turn. These destroy data.
- Never invoke `al_publish` to a Production environment unless the user explicitly says "production" in this turn.
- When the user's project folder cannot be unambiguously determined (multiple `app.json` files in the workspace), ask which project rather than guessing.
- When `al_auth_login` fails twice in a session, suggest `noCache: true` rather than looping retries.

## When the AL MCP is unavailable

If the `al` MCP server is not configured or its binary is not on PATH, invoke `/al-setup`. That command probes for `altool` and `al`, walks the user through installing the VS Code AL Language extension or the `Microsoft.Dynamics.BusinessCentral.Development.Tools` NuGet package (with explicit user confirmation), and fixes the `altool` vs `al` mismatch when only the NuGet variant is present. Do not attempt manual installation flows here — defer to `/al-setup`.
