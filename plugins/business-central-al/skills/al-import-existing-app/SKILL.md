---
name: al-import-existing-app
description: Import an existing AL app (.app or .zip) into an AL-Go repository via the Add existing app or test app workflow. Use when migrating a legacy non-AL-Go project into the AL-Go lifecycle, or when a customer hands over a precompiled .app to onboard.
disable-model-invocation: true
---

# Import an existing AL app

Dispatches the `Add existing app or test app` workflow.

## What this command does

Takes a direct download URL pointing at:

- A `.app` file, OR
- A `.zip` containing AL source

and unpacks it into the AL-Go repo, generating the right project structure and registering the app in `.AL-Go/settings.json`.

## Step 1 — Confirm the source URL

Ask the user for the direct download URL. Common sources:

- A GitHub release asset URL (`https://github.com/<owner>/<repo>/releases/download/<tag>/<file>`).
- A signed Azure Blob URL.
- A pre-built `.app` artifact from a previous build run.

The URL must be reachable from the GitHub runner (i.e. publicly downloadable, or with credentials embedded in the URL if private).

## Step 2 — Preflight

1. Confirm cwd is an AL-Go repo.
2. Confirm the user's repo type (PTE vs AppSource App) matches what the imported app expects. Importing an AppSource app into a PTE repo will not enable the AppSource-specific lifecycle commands.

## Step 3 — Dispatch

```bash
gh workflow run "Add existing app or test app" \
  --ref main \
  -f project=. \
  -f url=<direct download URL> \
  -f directCommit=false \
  -f useGhTokenWorkflow=true
```

Use `directCommit=false` (PR mode) so the user can review the imported structure before merging.

## Step 4 — Watch + review

```bash
RUN_ID=$(gh run list --workflow "Add existing app or test app" --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

The PR will include:

- The unpacked AL source (in a new folder under the project root).
- Updated `.AL-Go/settings.json` listing the new folder in `appFolders` or `testFolders`.

## Onward steps

After merging:

1. Walk through the imported source to ensure naming, ID ranges, and analyzer compliance match the target repo's conventions.
2. Run a CI/CD build to verify it compiles in the AL-Go environment.
3. If the import is the FIRST app in a fresh repo, follow up with `/al-add-test-app` to ensure a test surface exists.

## Failure modes

- 404 on the URL — the URL is wrong or the resource is private without embedded credentials.
- "Unable to unpack" — the file is not a valid `.app` or `.zip`, or the `.zip` does not contain an `app.json` at a discoverable depth.
- Manifest collision — the imported `app.json` has the same `id` as an existing app in the repo. Pick one to keep.
