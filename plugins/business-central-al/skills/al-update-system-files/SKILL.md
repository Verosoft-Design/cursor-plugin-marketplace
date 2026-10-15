---
name: al-update-system-files
description: Dispatch the Update AL-Go System Files workflow to refresh AL-Go scripts and workflows from the template repo. Use when the user wants to pick up new AL-Go features, fixes, or to silence the "newer system files available" warning in CI/CD output.
disable-model-invocation: true
---

# Update AL-Go system files

Dispatches the `Update AL-Go System Files` workflow (`UpdateGitHubGoSystemFiles.yaml`; display name ` Update AL-Go System Files` has a leading space, so dispatch by file name), which syncs AL-Go scripts and workflow YAMLs from the template repository.

## Preflight

1. Confirm cwd is an AL-Go repo.
2. **Required secret: `GhTokenWorkflow`** (or the name in `ghTokenWorkflowSecretName`). This workflow modifies other workflow files, which requires elevated permissions that `GITHUB_TOKEN` doesn't have. The workflow always reads it; there is no input to switch it on. Use `gh secret list` to verify (or `gh secret list --env <env>` if `updateALGoSystemFilesEnvironment` is set). If missing, run `/al-secrets-setup` first — it walks through the GitHub App (recommended) or PAT setup.
3. Check the current `templateUrl` in `.github/AL-Go-Settings.json` to see what version is being tracked. Common values:
   - `https://github.com/microsoft/AL-Go-PTE@main` — track main (recommended for most)
   - `https://github.com/microsoft/AL-Go-PTE@preview` — track preview branch (for early adopters)
   - `https://github.com/microsoft/AL-Go-PTE@v10.0` — pin to a release branch (the template repos have one branch per release: `v9.0`, `v9.1`, `v9.2`, `v10.0`, …)
   - Same shapes with `AL-Go-AppSource` for AppSource repos.
4. If the repo still uses the `unusedALGoSystemFiles` setting, recommend moving it to `customALGoFiles.filesToExclude` first; its support window ended 2026-10-01 (v10.0 still reads it).

## Inputs

The v10.0 `workflow_dispatch` inputs are exactly these four (there is **no** `useGhTokenWorkflow` input on this workflow; passing it makes the dispatch fail with an "unexpected inputs" error):

- `templateUrl` (string, default empty) — override the configured `templateUrl` for this run (e.g. to move to a new release branch or test against a fork).
- `downloadLatest` (boolean, default `true`).
- `directCommit` (boolean, default `false`) — `false` opens a PR (recommended so the user can review the diff). Only pass `true` if the user explicitly asks for a direct commit.
- `includeBranches` (string, default empty) — comma-separated list of branches to update, wildcards supported; the settings are read per branch. Empty = only the branch the workflow runs on.

## Dispatch

```bash
gh workflow run UpdateGitHubGoSystemFiles.yaml \
  --ref main \
  -f downloadLatest=true \
  -f directCommit=false
```

For a one-off run against a specific template version:

```bash
gh workflow run UpdateGitHubGoSystemFiles.yaml \
  --ref main \
  -f templateUrl=https://github.com/microsoft/AL-Go-PTE@v10.0 \
  -f downloadLatest=true \
  -f directCommit=false
```

To update several branches in one run (still PR mode), add `-f includeBranches="main,release/*"`.

## Watch the run

```bash
RUN_ID=$(gh run list --workflow UpdateGitHubGoSystemFiles.yaml --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

## Review the PR

The PR diff shows every changed AL-Go script and workflow YAML. Walk the user through it carefully:

- Workflow YAML changes are usually safe; AL-Go's contract is that the dispatch shape and inputs are preserved across minor/patch.
- Action ref bumps (e.g. `microsoft/AL-Go-Actions/ReadSettings@v9.2` → `@v10.0`) signal the AL-Go version moving forward. That `@vX.Y` is the AL-Go version to reference everywhere else. Third-party actions are pinned by commit SHA with a version comment (e.g. `actions/checkout@<sha> # v7.0.1`).
- When moving from v9.x to v10.0, expect: a new `CheckForUpdates` job in `CreateRelease.yaml`, the inline device-login scripts in `PublishToEnvironment.yaml` and `CreateOnlineDevelopmentEnvironment.yaml` replaced by the `Authenticate` action, a `BuildInitialize` hook step and a `Download Previous Release` step in `_BuildALGoProject.yaml`, and `ACTIONS_RUNNER_DISABLE_NODE_MAGLEV` on artifact steps. No workflow inputs change.
- Custom workflows prefixed `my*` / `our*` / `<org>*` are preserved (not touched by the update).
- Files listed in `customALGoFiles.filesToExclude` are not synced.

If the user has custom scripts in `.AL-Go/` (script overrides like `NewBcContainer.ps1`), those are NEVER overwritten by this workflow.

## Failure modes

- `Resource not accessible by integration` — `GhTokenWorkflow` is missing or lacks Workflows scope. `/al-secrets-setup`.
- "No updates available" — the repo is already on the latest template version. Not an error. Since v10.0 this is also reported when only `templateSha` would change: no PR or commit is created, so CI/CD is not triggered.
- Merge conflict in the resulting PR — happens when the user has manually edited AL-Go system files. Resolve by hand or by moving the customizations into a custom template repo.

## Scheduling

A scheduled run keeps system files fresh without manual intervention:

```json
"conditionalSettings": [
  { "workflows": ["Update AL-Go System Files"],
    "settings": {
      "workflowSchedule": {
        "cron": "0 6 * * 1",
        "includeBranches": ["main"]
      },
      "commitOptions": {
        "createPullRequest": true
      }
    }
  }
]
```

On a `schedule` trigger the workflow ignores the dispatch inputs: `downloadLatest` is forced `true` and commit mode comes from `commitOptions.createPullRequest` (`directCommit = not createPullRequest`). In the v10.0 code `createPullRequest` defaults to `true`, so scheduled runs open a PR; note that `settings.md` still says scheduled runs commit directly, so set `createPullRequest: true` explicitly as above to be unambiguous. Keep PR mode unless the user explicitly opts into direct commits. `commitOptions.pullRequestAutoMerge`, `pullRequestMergeMethod` and `pullRequestLabels` tune the PR. Add `updateALGoSystemFilesEnvironment: "<env name>"` to gate `GhTokenWorkflow` access through a GitHub Environment approval rule. `includeBranches` in `workflowSchedule` is supported only for this workflow. The schedule itself takes effect after the next successful run of this workflow.
