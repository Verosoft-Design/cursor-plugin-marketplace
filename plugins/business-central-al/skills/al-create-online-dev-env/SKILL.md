---
name: al-create-online-dev-env
description: Provision a Business Central online dev sandbox via the Create Online Dev. Environment workflow and update launch.json to target it. Use when the user wants a fresh BC environment for development against a specific app version, without needing local Docker.
disable-model-invocation: true
---

# Create an online dev environment

Dispatches the `Create Online Dev. Environment` workflow (`CreateOnlineDevelopmentEnvironment.yaml`; its display name has a leading space, so dispatch by file name), which provisions an online sandbox via the BC Admin Center API and PRs an updated `launch.json` so VS Code F5 targets the new env.

## Preflight

1. Confirm cwd is an AL-Go repo.
2. Check secrets:
   - `AdminCenterApiCredentials` (JSON `{"refreshtoken":"..."}`, or the name set in `adminCenterApiCredentialsSecretName`) — needed for non-interactive provisioning.
   - If absent, the workflow starts a device-code flow. Since v10.0 this runs through the `Authenticate` action (`authType: AdminCenter`) and the sign-in instructions appear in the **workflow summary**. That works but interrupts the flow; suggest `/al-secrets-setup` first.
3. Gather inputs:
   - `project` (relative path)
   - `environmentName` — the BC environment name to create (e.g. `dev-alice`). MUST be unique within the tenant.
   - `reUseExistingEnvironment` (boolean) — if `true` and an env with that name exists, the workflow updates `launch.json` instead of creating new.
   - `directCommit` (boolean, default `false`) — PR mode keeps `launch.json` changes reviewable.
   - `useGhTokenWorkflow` (boolean, default `false` in the workflow) — `true` uses the `GhTokenWorkflow` secret for the PR/commit so the PR triggers CI; requires that secret.

   `project` defaults to `.` and `environmentName` is required. These are the full v10.0 inputs.

## Dispatch

```bash
gh workflow run CreateOnlineDevelopmentEnvironment.yaml \
  --ref main \
  -f project=<project> \
  -f environmentName=<env name> \
  -f reUseExistingEnvironment=false \
  -f directCommit=false \
  -f useGhTokenWorkflow=true
```

## Watch the run

```bash
RUN_ID=$(gh run list --workflow CreateOnlineDevelopmentEnvironment.yaml --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

If `AdminCenterApiCredentials` is missing, the run waits for device login. Read the code from the run's summary page (`gh run view $RUN_ID --web`; `gh run view` in the terminal does not print job summaries) or from the Initialization job's step "Check AdminCenterApiCredentials / Initiate Device Login (open to see code)" (`gh run view $RUN_ID --log | grep -i devicelogin`), surface `https://aka.ms/devicelogin` plus the code to the user, and instruct them to complete sign-in in their browser. v10.0 fixed a bug where this device-login initialization failed when no authentication secret was available.

## After success

The PR (or direct commit) updates `<project>/.vscode/launch.json` with a new entry whose `environmentName` matches. F5 in VS Code now publishes to the new env.

For a fully agent-driven flow without VS Code, the user can publish via `/al-publish-sandbox` instead — pass the same `environmentName` and the env's tenant.

## Local alternative

For developers who prefer to provision from their machine without touching CI:

```powershell
.AL-Go/cloudDevEnv.ps1
```

This is the script AL-Go ships in the `.AL-Go/` folder. It does the same provisioning + `launch.json` update locally via device login.

## Local Docker alternative

If the user wants a local container instead of a cloud env:

```powershell
.AL-Go/localDevEnv.ps1
```

This spins up a BC Docker container via BcContainerHelper and patches `launch.json` to target it. Requires Docker Desktop for Windows containers. Since v10.0, localDevEnv passes the configured `cacheImageName` so BcContainerHelper can reuse artifact-specific images; set `"cacheImageName": ""` in `.AL-Go/localDevEnv.settings.json` to get the old behavior.
