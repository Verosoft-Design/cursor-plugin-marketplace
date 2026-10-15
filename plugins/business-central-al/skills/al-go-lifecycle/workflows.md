# AL-Go workflow inventory

Reference catalog of AL-Go for GitHub workflows. Read on demand when you need a workflow's exact display name, file name, trigger, or input shape. Sourced from the `microsoft/AL-Go-PTE` and `microsoft/AL-Go-AppSource` templates as of **AL-Go v10.0** (released 2026-10-09; template `main`, actions pinned to `microsoft/AL-Go-Actions/*@v10.0`). No workflow was added, removed or renamed, and no `workflow_dispatch` input changed between v9.0 and v10.0. Later versions may add or rename inputs; when in doubt, re-read `.github/workflows/<file>.yaml` in the user's repo, because that is what `gh workflow run` dispatches against.

## Display names and leading spaces

Many AL-Go display names start with a space (the space sorts them to the top of the Actions list). `gh workflow run "<name>"` must match that name exactly, so **always dispatch and list by file name** (`gh workflow run CreateRelease.yaml`, `gh run list --workflow CreateRelease.yaml`). The table shows the exact `name:` values, with the leading space marked as `␠`.

| File                                      | Exact `name:`                          | Template       |
| ----------------------------------------- | -------------------------------------- | -------------- |
| `CICD.yaml`                               | `␠CI/CD`                               | both           |
| `PullRequestHandler.yaml`                 | `Pull Request Build` (no space)        | both           |
| `CreateApp.yaml`                          | `Create a new app` (no space)          | both           |
| `CreateTestApp.yaml`                      | `Create a new test app` (no space)     | both           |
| `CreatePerformanceTestApp.yaml`           | `Create a new performance test app`    | both           |
| `AddExistingAppOrTestApp.yaml`            | `Add existing app or test app`         | both           |
| `CreateOnlineDevelopmentEnvironment.yaml` | `␠Create Online Dev. Environment`      | both           |
| `CreateRelease.yaml`                      | `␠Create release`                      | both           |
| `IncrementVersionNumber.yaml`             | `␠Increment Version Number`            | both           |
| `PublishToEnvironment.yaml`               | `␠Publish To Environment`              | both           |
| `PublishToAppSource.yaml`                 | `␠Publish To AppSource`                | AppSource only |
| `UpdateGitHubGoSystemFiles.yaml`          | `␠Update AL-Go System Files`           | both           |
| `Current.yaml`                            | `␠Test Current`                        | both           |
| `NextMinor.yaml`                          | `␠Test Next Minor`                     | both           |
| `NextMajor.yaml`                          | `␠Test Next Major`                     | both           |
| `DeployReferenceDocumentation.yaml`       | `␠Deploy Reference Documentation`      | both           |
| `Troubleshooting.yaml`                    | `Troubleshooting` (no space)           | both           |
| `PullPowerPlatformChanges.yaml`           | `␠Pull Power Platform changes`         | PTE only       |
| `PushPowerPlatformChanges.yaml`           | `␠Push Power Platform changes`         | PTE only       |
| `_BuildALGoProject.yaml`                  | `_Build AL-Go project`                 | both (internal) |
| `_BuildPowerPlatformSolution.yaml`        | `_Build PowerPlatform Solution`        | PTE only (internal) |

Booleans are passed as `-f <input>=true|false`. Input names are case-sensitive as written below (note `GoLive`).

## CI/CD

- **File:** `CICD.yaml` (name ` CI/CD`)
- **Triggers:** `workflow_dispatch`; `push` to `main`, `release/*`, `feature/*` (paths-ignore `**.md` and `.github/workflows/*.yaml` except `CICD.yaml`). Branches are configurable via the `CICDPushBranches` setting; a `workflowSchedule` on CI/CD disables push triggers unless `CICDPushBranches` is also set.
- **Inputs:** none
- **What it does:** Initialization → CheckForUpdates → Build (matrix per project × buildMode; PTE also BuildPP for Power Platform) → CodeAnalysisUpload → Deploy (per environment) → Deliver (per delivery target) → DeployALDoc → PostProcess.
- **Notes (v9.1–v10.0):** the GitHub environment `copilot` (auto-created when the Copilot coding agent is enabled) is auto-excluded from deployment, like `github-pages`. Deliver jobs have no GitHub `environment:`, so delivery secrets are protected only by `DeliverTo<Target>.Branches` / `deliverToAppSource.branches` plus branch protection.

## Pull Request Build

- **File:** `PullRequestHandler.yaml` (name `Pull Request Build`, no leading space)
- **Triggers:** `pull_request` to `main` (configurable via `CICDPullRequestBranches`); `merge_group`. Can be switched to `pull_request_target` via the `pullRequestTrigger` setting (security caveats).
- **Inputs:** none
- **What it does:** Pre-gate check (`VerifyPRChanges`) + build of touched projects; `failOn: newWarning` also works with workspace compilation since v9.2.

## Create a new app

- **File:** `CreateApp.yaml` (name `Create a new app`)
- **Trigger:** `workflow_dispatch`
- **Inputs:**
  - `project` (string, default `.`) — project name if the repository is set up for multiple projects
  - `name` (string, required) — app name
  - `publisher` (string, required)
  - `idrange` (string, required) — `from..to`, e.g. `70015000..70016999`
  - `sampleCode` (boolean, default `true`)
  - `directCommit` (boolean, default `false`) — `false` opens a PR
  - `useGhTokenWorkflow` (boolean, default `false`) — use `GhTokenWorkflow` for the PR/commit (needed when PRs must trigger CI, or to push to protected branches)
- **What it does:** Calls the `CreateApp` action; the app type comes from the repo `type` setting (`PTE` or `AppSource App`), the YAML is identical in both templates.
- **Secret needs:** `GhTokenWorkflow` when `useGhTokenWorkflow=true`.

## Create a new test app

- **File:** `CreateTestApp.yaml`
- **Inputs:** `project` (default `.`), `name` (required, default `<YourAppName>.Test`), `publisher` (required), `idrange` (required, default `50000..99999`), `sampleCode` (boolean, default `true`), `directCommit` (boolean, default `false`), `useGhTokenWorkflow` (boolean, default `false`).
- **What it does:** Calls `CreateApp` with type Test App.

## Create a new performance test app

- **File:** `CreatePerformanceTestApp.yaml`
- **Inputs:** `project` (default `.`), `name` (required, default `<YourAppName>.PerformanceTest`), `publisher` (required), `idrange` (required, default `50000..99999`), `sampleCode` (boolean, default `true`), `sampleSuite` (boolean, default `true`), `directCommit` (boolean, default `false`), `useGhTokenWorkflow` (boolean, default `false`).
- **What it does:** Calls `CreateApp` for a BCPT app (Linux runner fix in v9.1).

## Add existing app or test app

- **File:** `AddExistingAppOrTestApp.yaml`
- **Inputs:** `project` (default `.`), `url` (required; direct download URL of `.app` or `.zip`), `directCommit` (boolean, default `false`), `useGhTokenWorkflow` (boolean, default `false`).
- **What it does:** Calls `AddExistingApp` to import a `.app` or `.zip` into the repo.

## Create Online Dev. Environment

- **File:** `CreateOnlineDevelopmentEnvironment.yaml` (name ` Create Online Dev. Environment`)
- **Inputs:** `project` (default `.`), `environmentName` (required), `reUseExistingEnvironment` (boolean, default `false`), `directCommit` (boolean, default `false`), `useGhTokenWorkflow` (boolean, default `false`).
- **What it does:** Calls `CreateDevelopmentEnvironment` to provision an online dev sandbox via the BC Admin Center API and update `launch.json`.
- **Secret needs:** `AdminCenterApiCredentials` (or the name in `adminCenterApiCredentialsSecretName`). Since v10.0 the check runs through the `Authenticate` action (`authType: AdminCenter`); without the secret it starts a device-code flow and prints the sign-in instructions in the **workflow summary** (and in the Initialization job's "Check AdminCenterApiCredentials / Initiate Device Login (open to see code)" step).

## Create release

- **File:** `CreateRelease.yaml` (name ` Create release`)
- **Trigger:** `workflow_dispatch`; `concurrency: group: ${{ github.workflow }}` (one release at a time)
- **Inputs:**
  - `buildVersion` (string, default `latest`) — `latest` = latest successful CI/CD build on the dispatched branch, or an explicit build version of a CI/CD artifact on that branch. PR builds (`PR_<id>`) are NOT accepted here.
  - `name` (string, required) — release display name, e.g. `v1.0`
  - `tag` (string, required) — semver tag, e.g. `1.0.0`
  - `releaseType` (choice: `Release` / `Prerelease` / `Draft`, default `Release`)
  - `createReleaseBranch` (boolean, default `false`)
  - `releaseBranchPrefix` (string, default `release/`) — used only when `createReleaseBranch=true`; branch = prefix + version from the tag (tag `1.0.0` → `release/1.0`, `1.0.1` → `release/1.0.1`)
  - `updateVersionNumber` (string, default empty) — `Major.Minor` (plus `.Build` for versioningStrategy 3) absolute, or `+1` / `+0.1` (`+0.0.1` for versioningStrategy 3) incremental; empty = no bump
  - `skipUpdatingDependencies` (boolean, default `false`) — skip updating dependency version numbers in all apps when bumping
  - `directCommit` (boolean, default `false`) — applies to the version bump; `false` opens a PR
  - `useGhTokenWorkflow` (boolean, default `false`)
- **What it does:** Validates inputs, determines artifacts, builds release notes, creates the GitHub release with `.app` artifacts, delivers to NuGet/Storage when those contexts exist (Apps only), optionally creates the release branch and the version bump (PR or commit). **v10.0:** the AL-Go system-file update check runs in a separate, parallel `CheckForUpdates` job that only reports; it never applies updates.
- **Secret needs:** `GhTokenWorkflow` when `useGhTokenWorkflow=true` (also read by the CheckForUpdates job if present).

## Increment Version Number

- **File:** `IncrementVersionNumber.yaml` (name ` Increment Version Number`)
- **Inputs:**
  - `projects` (string, default `*`) — comma-separated project name patterns
  - `versionNumber` (string, default empty) — `Major.Minor` (plus `.Build` for versioningStrategy 3) absolute, or `+1` / `+0.1` (`+0.0.1` for versioningStrategy 3)
  - `skipUpdatingDependencies` (boolean, default `false`)
  - `directCommit` (boolean, default `false`)
  - `useGhTokenWorkflow` (boolean, default `false`)
- **What it does:** Validates `versionNumber` against `versioningStrategy`, then updates `app.json` versions / `repoVersion` (and dependencies unless skipped).

## Publish To Environment

- **File:** `PublishToEnvironment.yaml` (name ` Publish To Environment`)
- **Inputs:**
  - `appVersion` (string, default `current`) — `current` / `prerelease` / `draft` / `latest` / version number / `PR_<id>`
  - `environmentName` (string, required) — environment mask (`*` for all, `PROD*` for all starting with PROD)
  - `createEnvIfNotExists` (boolean, default `false`) — use with care; `<env>_AuthContext`, `<env>_EnvironmentName` and `<env>_Scope` must exist as environment or repo secrets/variables
- **What it does:** Resolves matching environments (honoring `DeployTo<envName>` settings), authenticates, downloads the artifacts (`GetArtifactsForDeployment`), deploys, and deploys Power Platform solutions where configured.
- **Secret needs:** AuthContext, resolved in this order: `<EnvironmentName>-AuthContext`, `<EnvironmentName>_AuthContext`, `AuthContext` (or a GitHub environment secret `AuthContext` under the environment). Since v10.0 the lookup runs through the `Authenticate` action (`authType: Environment`); if nothing resolves it starts device login and lists the candidate names in the workflow summary. Azure Key Vault cannot hold names with `_`, so use the dash variant there. A missing per-environment secret silently falls back to the generic `AuthContext`.
- **Settings (v10.0):** `DeployTo<env>.unpublishOldVersions` (default `false`) unpublishes old, uninstalled app versions after a successful PTE-scope deployment (non-fatal).

## Publish To AppSource (AppSource template only)

- **File:** `PublishToAppSource.yaml` (name ` Publish To AppSource`)
- **Inputs:**
  - `appVersion` (string, default `current`) — `current` / `prerelease` / `draft` / `latest` / version number
  - `projects` (string, default `*`)
  - `GoLive` (boolean, default `false`) — promote the app to go live if it passes technical validation
- **What it does:** Calls `Deliver` with `deliveryTarget: AppSource`, `type: Release`, `goLive` from the input.
- **Secret needs:** `AppSourceContext` (or the name in `appSourceContextSecretName`). S2S with client secret or federated credential.
- **Settings needs:** `deliverToAppSource.productId`, `appSourceCopMandatoryAffixes`; optional `deliverToAppSource.mainAppFolder`, `includeDependencies`, `continuousDelivery`, `branches`.
- **Manual prereq:** The first time a product appears in Partner Center, the offer and marketing materials must be created by a human. This workflow handles subsequent versions.

## Update AL-Go System Files

- **File:** `UpdateGitHubGoSystemFiles.yaml` (name ` Update AL-Go System Files`)
- **Triggers:** `workflow_dispatch`, `workflow_call`, plus `schedule` when a `workflowSchedule` is configured for it.
- **`workflow_dispatch` inputs:**
  - `templateUrl` (string, default empty) — override the configured template URL for this run
  - `downloadLatest` (boolean, default `true`)
  - `directCommit` (boolean, default `false`)
  - `includeBranches` (string, default empty) — comma-separated branches, wildcards allowed; empty = current branch only
- **`workflow_call` inputs:** `caller` (string, required — pass `github.workflow`), plus the same `templateUrl`, `downloadLatest`, `directCommit`, `includeBranches`.
- There is **no** `useGhTokenWorkflow` input; the workflow always reads `GhTokenWorkflow`.
- **What it does:** Calls `CheckForUpdates` with `update: Y` per branch. On `schedule`, commit mode comes from `commitOptions.createPullRequest` (code default `true` → PR) and `downloadLatest` is forced `true`. **v10.0:** if only `templateSha` would change, nothing is committed and no PR is opened.
- **Secret needs:** `GhTokenWorkflow` (optionally guarded by `updateALGoSystemFilesEnvironment`).

## Test Current / Test Next Minor / Test Next Major

- **Files:** `Current.yaml`, `NextMinor.yaml`, `NextMajor.yaml` (names ` Test Current`, ` Test Next Minor`, ` Test Next Major`)
- **Trigger:** `workflow_dispatch` (plus `schedule` via `workflowSchedule`)
- **Inputs:** none
- **What it does:** Builds and tests every project against the artifact set in `.github/Test Current.settings.json` (`"artifact": "////latest"`), `.github/Test Next Minor.settings.json` (`////nextminor`), `.github/Test Next Major.settings.json` (`////nextmajor`). The template files also set `"cacheImageName": ""` and `"versioningStrategy": 15`.

## Deploy Reference Documentation

- **File:** `DeployReferenceDocumentation.yaml` (name ` Deploy Reference Documentation`)
- **Trigger:** `workflow_dispatch`
- **Inputs:** none
- **What it does:** Builds and deploys the `aldoc` site to GitHub Pages. Honors the `alDoc` setting. v9.2 fixed `--packagecache` use and TOC errors for app names with underscores.

## Troubleshooting

- **File:** `Troubleshooting.yaml` (name `Troubleshooting`, no leading space)
- **Trigger:** `workflow_dispatch`
- **Inputs:** `displayNameOfSecrets` (boolean, default `false`) — if `true`, shows the _names_ (not values) of secrets available to the repository.
- **What it does:** Diagnostic dump of repo settings and (optionally) configured secret names. The first thing to run when an AL-Go workflow misbehaves.

## Pull Power Platform changes / Push Power Platform changes (PTE template only)

- **Files:** `PullPowerPlatformChanges.yaml`, `PushPowerPlatformChanges.yaml`
- **Pull inputs:** `environment` (required), `solutionFolder` (optional; empty = AL-Go setting), `directCommit` (boolean, default `false`), `useGhTokenWorkflow` (boolean, default `false`).
- **Push inputs:** `environment` (required), `solutionFolder` (optional).
- **What they do:** Sync the Power Platform solution folder with the connected PP environment.

## Reusable / internal workflows (do NOT dispatch directly)

- `_BuildALGoProject.yaml` — reusable per-project build (called by CI/CD, PR, Current/NextMinor/NextMajor). v9.1 added the experimental `BuildInitialize` hook (`.AL-Go/BuildInitialize.ps1`); since v9.1 it also downloads the previous release (upgrade tests and AppSourceCop baseline) unless `skipUpgrade` is set; v9.2 added `doNotPerformUpgrade` (keep the baseline, skip the upgrade phase).
- `_BuildPowerPlatformSolution.yaml` — reusable PP build (PTE template).

## Secrets reference

| Secret                                                      | Purpose                                                                                      | Shape                                                                                                                                              |
| ----------------------------------------------------------- | -------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Azure_Credentials`                                         | Azure Key Vault + KV codesigning + Trusted Signing                                           | JSON `{keyVaultName, clientId, tenantId[, clientSecret]}`; managed identity requires federated credential                                          |
| `<env>-AuthContext`, `<env>_AuthContext` or `AuthContext`   | Deploy to BC environment (checked in that order)                                             | JSON; `refreshToken` (impersonation) or S2S (`clientId`+`clientSecret` or federated credential). Scope `https://api.businesscentral.dynamics.com/` |
| `AppSourceContext`                                          | Deliver to AppSource                                                                         | JSON for Partner Center API (client secret or federated credential). Scope `https://api.partner.microsoft.com/.default`                            |
| `StorageContext`                                            | Deliver to Azure Storage                                                                     | JSON with `containerName` + `blobName` placeholders `{project}`/`{version}`/`{branch}`/`{type}`                                                    |
| `GitHubPackagesContext`                                     | Deliver to GitHub Packages NuGet feed (+ auto dependency resolution)                         | JSON `{token, serverUrl}`; classic PAT with `write:packages`+`read:packages`                                                                       |
| `NuGetContext`                                              | Deliver to NuGet (not auto-used for resolution; add to `trustedNuGetFeeds` if needed)        | Provider-specific                                                                                                                                  |
| `GhTokenWorkflow`                                           | Update AL-Go System Files, Create release, Increment Version Number, Create a new app family | GitHub App: JSON `{GitHubAppClientId, PrivateKey}` (recommended). PAT: plain string. Required: R/W Contents + PRs + Workflows; R Actions.         |
| `GitSubmodulesToken`                                        | Private submodules when `useGitSubmodules` set                                               | PAT                                                                                                                                                |
| `LicenseFileUrl`                                            | Specific license file URL for CI/CD (AppSource pre-BC22)                                     | URL string                                                                                                                                         |
| `AdminCenterApiCredentials`                                 | BC Admin Center API for Create Online Dev. Environment                                       | JSON `{refreshtoken}`                                                                                                                              |
| `applicationInsightsConnectionString`                       | Telemetry connection string injected into apps                                               | Connection string                                                                                                                                  |

Delivery context secrets are read as repo/org secrets with no GitHub environment gate; protect the branches listed in `DeliverTo<Target>.Branches` / `deliverToAppSource.branches`.

For minting these JSONs, see the `/al-secrets-setup` command — it wraps BcContainerHelper's `New-BcAuthContext`, `New-ALGoAuthContext`, `New-ALGoAppSourceContext`, `New-ALGoStorageContext`, `New-ALGoNuGetContext` helpers.

## Settings indirection (when secret names differ from defaults)

Several settings let you point at differently-named secrets:

- `licenseFileUrlSecretName` (default `LicenseFileUrl`)
- `ghTokenWorkflowSecretName` (default `GhTokenWorkflow`)
- `adminCenterApiCredentialsSecretName` (default `AdminCenterApiCredentials`)
- `appSourceContextSecretName` (default `AppSourceContext`)
- `codeSignCertificateUrlSecretName` / `codeSignCertificatePasswordSecretName` (legacy signing)
- `keyVaultCodesignCertificateName` (KV-based signing — required when `useCompilerFolder: true`)
- `storageContextSecretName` (default `StorageContext`)
- `applicationInsightsConnectionStringSecretName` (default `applicationInsightsConnectionString`)

When the user has chosen non-default secret names (visible in `.AL-Go/settings.json` or `.github/AL-Go-Settings.json`), honor them.
