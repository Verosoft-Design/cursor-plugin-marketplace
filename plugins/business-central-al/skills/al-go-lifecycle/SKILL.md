---
name: al-go-lifecycle
description: Orchestrates the AL-Go for GitHub lifecycle for Business Central AL projects via gh workflow run. Use when the user asks to scaffold a new app, add a test app, deploy to a sandbox or production environment, create a release, publish to AppSource, update AL-Go system files, increment version numbers, run tests against current or next BC versions, or otherwise drive any AL-Go workflow from Cursor.
---

# AL-Go Lifecycle Orchestrator

This skill turns user intent into the correct `gh workflow run` invocation against an AL-Go for GitHub repository. It handles preflight checks (repo detection, secret presence), dispatches the workflow, watches the run, and surfaces failures.

For the full inventory of AL-Go workflows with every input documented, refer the agent to [`workflows.md`](workflows.md). Read it on demand when you need a workflow's exact input shape.

## Prerequisites in the agent's environment

- `gh` CLI installed and authenticated against the repo's host (`gh auth status` should show a logged-in user with workflow permissions).
- Network access to GitHub.
- The current working directory MUST be inside the AL-Go repo, OR the user explicitly supplies a `<owner>/<repo>` value.

## Preflight checks (run these before any workflow dispatch)

1. **Confirm AL-Go repo.** Check that `.github/AL-Go-Settings.json` exists. If not, the repo is not an AL-Go project — surface that and stop.
2. **Discover the AL-Go version.** Read `templateUrl` from `.github/AL-Go-Settings.json`. Format: `https://github.com/<owner>/<repo>[@branch-or-tag]`. The actual AL-Go version is the `@vX.Y` suffix on the `microsoft/AL-Go-Actions/*` refs in `.github/workflows/*.yaml` (e.g. `@v10.0`). **Never hardcode a version** — the user's `Update AL-Go System Files` workflow moves this forward over time. The inputs documented in `workflows.md` match v10.0; if the repo is older or newer, check the repo's own YAML before passing `-f` inputs.
3. **Dispatch by workflow file name.** Most AL-Go display names start with a space (` CI/CD`, ` Create release`, ` Publish To Environment`, ` Update AL-Go System Files`, ` Test Next Major`, …), which makes `gh workflow run "<name>"` fail. Always use the file name (`CreateRelease.yaml`) for both `gh workflow run` and `gh run list --workflow`. Confirm it exists with `gh workflow list --all` (or `ls .github/workflows`).
4. **Check secret existence** (when relevant). Use `gh secret list` (or `gh secret list --env <env>` for environment secrets) before dispatching workflows that need a secret:
   - `GhTokenWorkflow` for `Update AL-Go System Files`, `Create release`, `Increment Version Number`, `Create a new app` family
   - `<env>-AuthContext`, `<env>_AuthContext` or `AuthContext` (checked in that order; or `AuthContext` as a GitHub environment secret) for `Publish To Environment`
   - `AppSourceContext` for `Publish To AppSource`
   - `AdminCenterApiCredentials` for `Create Online Dev. Environment`
   - `Azure_Credentials` when Azure KeyVault, KV codesigning or Trusted Signing is wired (if KV is wired, the other secrets may live in the vault and not show in `gh secret list` — use `/al-troubleshoot` instead)
5. **For AppSource-publish or production-deploy operations**, require explicit user confirmation in the current turn before invoking. These are not reversible from the agent side.

If any preflight check fails, surface the gap and the suggested fix (e.g. "the `AppSourceContext` secret is missing — run `/al-secrets-setup` to mint it") rather than guessing.

## Dispatch pattern

The canonical shape:

```bash
gh workflow run <WorkflowFile>.yaml \
  --repo <owner>/<repo> \
  --ref <branch> \
  -f <input1>=<value1> \
  -f <input2>=<value2>
```

For example `gh workflow run CICD.yaml --ref main`. (`gh workflow run` takes the workflow as a positional argument; it has no `--workflow` flag.)

After dispatch, immediately follow with:

```bash
# Get the run ID of the just-triggered run
gh run list --workflow <WorkflowFile>.yaml --branch <branch> --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId'

# Watch it
gh run watch <run-id> --exit-status
```

`gh run watch --exit-status` blocks until completion and exits non-zero on failure. On failure, surface the run URL (`gh run view <run-id> --web`) plus the first ~20 lines of the failure log (`gh run view <run-id> --log-failed | head -50`).

## Routing user intent to workflows

| User intent                                      | Workflow (file)                                                                                         | Plugin command                                    |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| Create a new PTE repo                            | (manual: `gh repo create --template microsoft/AL-Go-PTE`) + `Create a new app` (`CreateApp.yaml`)       | `/al-new-pte`                                     |
| Create a new AppSource repo                      | (manual: `gh repo create --template microsoft/AL-Go-AppSource`) + `Create a new app` (`CreateApp.yaml`) | `/al-new-appsource`                               |
| Add a test app                                   | `Create a new test app` (`CreateTestApp.yaml`)                                                          | `/al-add-test-app`                                |
| Add a performance test app                       | `Create a new performance test app` (`CreatePerformanceTestApp.yaml`)                                   | `/al-add-bcpt-app`                                |
| Import an existing `.app` / `.zip`               | `Add existing app or test app` (`AddExistingAppOrTestApp.yaml`)                                         | `/al-import-existing-app`                         |
| Spin up an online dev sandbox                    | `Create Online Dev. Environment` (`CreateOnlineDevelopmentEnvironment.yaml`)                            | `/al-create-online-dev-env`                       |
| Deploy a specific build to an env                | `Publish To Environment` (`PublishToEnvironment.yaml`)                                                  | `/al-publish-to-environment`                      |
| Re-test against current/next BC                  | `Test Current` / `Test Next Minor` / `Test Next Major` (`Current.yaml` / `NextMinor.yaml` / `NextMajor.yaml`) | `/al-current`, `/al-next-minor`, `/al-next-major` |
| Diagnose AL-Go config                            | `Troubleshooting` (`Troubleshooting.yaml`)                                                              | `/al-troubleshoot`                                |
| Upgrade AL-Go system files                       | `Update AL-Go System Files` (`UpdateGitHubGoSystemFiles.yaml`)                                          | `/al-update-system-files`                         |
| Bump version number                              | `Increment Version Number` (`IncrementVersionNumber.yaml`)                                              | `/al-increment-version`                           |
| Cut a GitHub release                             | `Create release` (`CreateRelease.yaml`)                                                                 | `/al-release`                                     |
| Ship to AppSource                                | `Publish To AppSource` (`PublishToAppSource.yaml`, AppSource template only)                             | `/al-publish-appsource`                           |
| Publish aldoc reference docs                     | `Deploy Reference Documentation` (`DeployReferenceDocumentation.yaml`)                                  | `/al-deploy-docs`                                 |
| Sync a Power Platform solution (PTE only)        | `Pull Power Platform changes` / `Push Power Platform changes` (`PullPowerPlatformChanges.yaml` / `PushPowerPlatformChanges.yaml`) | none — dispatch directly with inputs from `workflows.md`; Push deploys to an environment, so apply the production-confirmation rule |
| Compound (build → publish → release → AppSource) | composes multiple                                                                                       | `/al-go-live`                                     |

## Settings discovery

When a workflow's inputs depend on project settings (e.g. `Publish To AppSource` needs `deliverToAppSource.productId`), read the relevant settings file:

- `.github/AL-Go-Settings.json` — repo-level settings (type, templateUrl, runs-on, environments, ContinuousDelivery, etc.).
- `.AL-Go/settings.json` — project-level settings (country, appFolders, testFolders, deliverToAppSource, appSourceCopMandatoryAffixes, etc.).
- For multi-project repos, each project folder has its own `.AL-Go/settings.json`.

When a required setting is missing, point the user at the right place to add it rather than guessing.

## Deprecated settings to avoid

When suggesting settings changes, do NOT use these (per Microsoft's `DEPRECATIONS.md`, unchanged in v10.0):

| Setting                          | Support removed after             | Use instead                                                        |
| -------------------------------- | --------------------------------- | ------------------------------------------------------------------ |
| `unusedALGoSystemFiles`          | past due (2026-10-01)             | `customALGoFiles.filesToExclude`                                   |
| `alwaysBuildAllProjects`         | past due (2025-10-01)             | `incrementalBuilds.onPull_Request: false` (or `fullBuildPatterns`) |
| `<workflow>Schedule` dynamic key | past due (2025-10-01)             | `workflowSchedule` per-workflow settings                           |
| `cleanModePreprocessorSymbols`   | past due (2025-04-01)             | `preprocessorSymbols` + conditional settings on `buildModes`       |

v10.0 still reads `unusedALGoSystemFiles`, but its support window has ended and it can disappear in any release. If a repo still uses it, recommend migrating to `customALGoFiles.filesToExclude` before the next system-file update.

## Changes since v9.0 worth knowing (v9.1, v9.2, v10.0)

No workflow was added, removed or renamed and no dispatch input changed. Behavior and settings that matter when driving the workflows:

- **Publish To Environment / Create Online Dev. Environment** use a new `Authenticate` action (v10.0). Missing credentials start device login, with instructions in the workflow summary. AuthContext lookup order: `<env>-AuthContext`, `<env>_AuthContext`, `AuthContext`. Azure Key Vault skips names containing `_`.
- **Create release** checks for AL-Go updates in a separate parallel `CheckForUpdates` job (v10.0, report only).
- **Update AL-Go System Files** no longer opens a PR or commit when only `templateSha` would change (v10.0).
- **New settings:** `DeployTo<env>.unpublishOldVersions` (v10.0), `nuGetFeedSelectMode` suffix `-allowPrerelease` (v10.0), `doNotPerformUpgrade` (v9.2), `ConditionalSettings` `triggers` condition (v9.1), compiler-folder hooks `PreNewBcCompilerFolder.ps1` / `PostNewBcCompilerFolder.ps1` and the experimental `.AL-Go/BuildInitialize.ps1` hook (v9.1).
- **localDevEnv** now passes `cacheImageName` (v10.0); set it to `""` in `.AL-Go/localDevEnv.settings.json` for the old behavior.
- **Copilot:** the `copilot` GitHub environment created by the Copilot coding agent is auto-excluded from deployments (v9.1).
- **Delivery security:** Deliver jobs (AppSource, NuGet, Storage, GitHub Packages) run without a GitHub environment gate; protect every branch listed in `deliverToAppSource.branches` / `DeliverTo<Target>.Branches`.
- **Workspace compilation** (preview, BC v28+) gained upgrade tests, BCPT, incremental builds, `failOn: newWarning` and AL alerts support.

## Common failure modes

| Symptom                                                               | Cause                                                                                 | Resolution                                                                           |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `Resource not accessible by integration` on Update AL-Go System Files | Missing `GhTokenWorkflow` secret or insufficient PAT/GitHub App permissions           | `/al-secrets-setup` then re-run                                                      |
| Publish job fails with auth error, or waits on device login           | Missing or expired `<env>-AuthContext` / `<env>_AuthContext` / `AuthContext`          | Regenerate via `New-BcAuthContext` + `New-ALGoAuthContext` (see `/al-secrets-setup`) |
| Deploys to the wrong tenant in a multi-env repo                       | Per-environment AuthContext missing; AL-Go silently fell back to generic `AuthContext` | Add `<env>-AuthContext` (dash form if stored in Key Vault)                           |
| AppSource validation fails                                            | `appSourceCopMandatoryAffixes` not set, or analyzer violations                        | Run `/al-build` with `${AppSourceCop}` analyzer locally first                        |
| Build job hangs / OOM                                                 | Default 8G memory limit insufficient                                                  | Set `memoryLimit: "16G"` in `.AL-Go/settings.json`                                   |
| "Workflow not found" / "could not find any workflows named"           | Workflow display name has a leading space (e.g. ` CI/CD`)                             | Dispatch by file name instead: `gh workflow run CICD.yaml`                           |
| Create release fails on signing                                       | Missing codesign secrets (legacy path) or `keyVaultCodesignCertificateName` (KV path) | Wire signing per `/al-init-keyvault` flow                                            |

## Safety rules

- **Never dispatch a Production environment deployment** without explicit user confirmation containing the word "production" in this turn. AL-Go's `(PROD)` / `(FAT)` environment-name convention is the only thing protecting production from CD; honor it. An `environmentName` mask (`*`, `PROD*`, …) that matches any production environment counts as a production deployment.
- **Never set `GoLive=true` on `Publish To AppSource`** without explicit user confirmation. The AppSource Preview → Live promotion is a public-facing action.
- **Never run `Update AL-Go System Files` with `directCommit=true`** unless the user explicitly opts in. Default to PR so changes are reviewable. The same applies to scheduled runs: do not set `commitOptions.createPullRequest: false` for that workflow unless the user explicitly opts in.
- **First AppSource upload is manual.** The first time a product appears in Partner Center, marketing materials must be uploaded by a human. Surface this when the user runs `/al-publish-appsource` on a never-shipped product.
