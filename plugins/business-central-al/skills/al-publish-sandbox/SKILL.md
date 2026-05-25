---
name: al-publish-sandbox
description: Publish a built .app to a Business Central sandbox environment via the AL MCP. Handles Entra ID sign-in if needed and supports cloud (sandbox/production) and on-prem targets. Use after a successful al-build, or directly with an existing .app via skipBuild.
disable-model-invocation: true
---

# Publish AL to a sandbox environment

Call the AL MCP tool `al_publish`. This deploys a `.app` to a cloud (Sandbox or Production) or on-prem BC environment.

## Step 1 — Authenticate (cloud targets only)

For cloud environments, call `al_auth_login` first if no Entra ID token is cached this session:

```json
{
  "tenant": "<tenant id or domain>",
  "environmentType": "Sandbox",
  "environmentName": "<environment name>"
}
```

On-prem with Windows auth does not need this step.

## Step 2 — Decide the publish source

Either build-then-publish or publish-an-existing-`.app`:

- **Build then publish** — pass `projectPath` only. The tool builds first, then publishes the resulting `.app`.
- **Publish an existing `.app`** — pass `appPath` (absolute path) and `skipBuild: true`.

## Common parameter combinations

Publish active project to a cloud sandbox:

```json
{
  "environmentName": "sandbox",
  "environmentType": "Sandbox",
  "tenant": "<tenant>"
}
```

Publish a pre-built `.app` to a cloud sandbox:

```json
{
  "appPath": "<absolute path to .app>",
  "environmentName": "sandbox",
  "environmentType": "Sandbox",
  "tenant": "<tenant>",
  "skipBuild": true
}
```

Publish to on-prem with Windows auth:

```json
{
  "projectPath": "<absolute path to app.json folder>",
  "serverUrl": "http://myserver",
  "serverInstance": "BC",
  "port": 7049,
  "authentication": "Windows"
}
```

Build and publish the full dependency tree (active project + all dependencies in order):

```json
{ "buildDependencies": true }
```

## Schema update modes

`schemaUpdateMode` accepts:

- `"Synchronize"` (default) — apply additive schema changes.
- `"ForceSync"` — apply breaking changes; data may be lost on incompatible field changes.
- `"Recreate"` — drop and recreate the extension's tables. **DESTROYS DATA.** Reserve for explicit user-initiated resets.

Never default to `"Recreate"` or `"ForceSync"` in compound flows. When the user asks for one of these, restate it explicitly and confirm before invoking.

## After the call

On success, the extension is deployed and ready for use in the target environment. On failure, the tool returns the error reason. Common follow-ups:

- Authentication error → run `al_auth_login` again with `noCache: true`.
- Build error before publish → call `/al-diagnostics` (or `al_getdiagnostics`) and fix the issues.
- Version compatibility error → consider `forceUpgrade: true` after explicit user confirmation.
