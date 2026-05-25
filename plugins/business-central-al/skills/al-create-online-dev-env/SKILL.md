---
name: al-create-online-dev-env
description: Provision a Business Central online dev sandbox via the Create Online Dev. Environment workflow and update launch.json to target it. Use when the user wants a fresh BC environment for development against a specific app version, without needing local Docker.
disable-model-invocation: true
---

# Create an online dev environment

Dispatches the `Create Online Dev. Environment` workflow, which provisions an online sandbox via the BC Admin Center API and PRs an updated `launch.json` so VS Code F5 targets the new env.

## Preflight

1. Confirm cwd is an AL-Go repo.
2. Check secrets:
   - `AdminCenterApiCredentials` (JSON `{"refreshtoken":"..."}`) — needed for non-interactive provisioning.
   - If absent, the workflow falls back to printing a device-login code in its log. That works but interrupts the flow; suggest `/al-secrets-setup` first.
3. Gather inputs:
   - `project` (relative path)
   - `environmentName` — the BC environment name to create (e.g. `dev-alice`). MUST be unique within the tenant.
   - `reUseExistingEnvironment` (boolean) — if `true` and an env with that name exists, the workflow updates `launch.json` instead of creating new.
   - `directCommit` (boolean, default `false`) — PR mode keeps `launch.json` changes reviewable.

## Dispatch

```bash
gh workflow run "Create Online Dev. Environment" \
  --ref main \
  -f project=<project> \
  -f environmentName=<env name> \
  -f reUseExistingEnvironment=false \
  -f directCommit=false \
  -f useGhTokenWorkflow=true
```

## Watch the run

```bash
RUN_ID=$(gh run list --workflow "Create Online Dev. Environment" --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

If the workflow log contains a device-login URL (when `AdminCenterApiCredentials` is missing), surface that URL to the user and instruct them to complete sign-in in their browser.

## After success

The PR (or direct commit) updates `<project>/.vscode/launch.json` with a new entry whose `environmentName` matches. F5 in VS Code now publishes to the new env.

For a fully-Cursor-driven flow without VS Code, the user can publish via `/al-publish-sandbox` instead — pass the same `environmentName` and the env's tenant.

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

This spins up a BC Docker container via BcContainerHelper and patches `launch.json` to target it. Requires Docker Desktop for Windows containers.
