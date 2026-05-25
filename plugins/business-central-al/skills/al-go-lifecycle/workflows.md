# AL-Go workflow inventory

Reference catalog of AL-Go for GitHub workflows. Read on demand when you need a workflow's exact display name, file name, trigger, or input shape. Sourced from `microsoft/AL-Go-PTE` and `microsoft/AL-Go-AppSource` templates as of AL-Go v9.0; subsequent versions may add or rename inputs — re-read the template's `.github/workflows/<file>.yaml` when in doubt.

## CI/CD

- **Display name:** `CI/CD` (note: internal name has a leading space — ` CI/CD`)
- **File:** `CICD.yaml`
- **Triggers:** `push` (to `main` / `release/*` / `feature/*` by default; configurable via `CICDPushBranches`); `workflow_dispatch`
- **Inputs:** none
- **What it does:** Initialization → CheckForUpdates → Build (matrix per project × buildMode) → Deploy (per environment) → Deliver (per delivery target) → DeployALDoc → PostProcess

## Pull Request Build

- **Display name:** `Pull Request Build` (internal: ` Pull Request Build`)
- **File:** `PullRequestHandler.yaml`
- **Triggers:** `pull_request` (target `main` by default; configurable via `CICDPullRequestBranches`); `merge_group`. Can be switched to `pull_request_target` via the `pullRequestTrigger` setting (security caveats).
- **Inputs:** none
- **What it does:** Pre-gate check + build all touched projects with `failOn: error` / `newWarning`.

## Create a new app

- **Display name:** `Create a new app`
- **File:** `CreateApp.yaml`
- **Trigger:** `workflow_dispatch`
- **Inputs:**
  - `project` (string, default `.`) — relative path to the AL-Go project folder
  - `name` (string, required) — app name
  - `publisher` (string, required)
  - `idrange` (string, required) — e.g. `70015000..70016999`
  - `sampleCode` (boolean, default `true`)
  - `directCommit` (boolean, default `false`) — false ⇒ opens a PR
  - `useGhTokenWorkflow` (boolean, default `false`) — required `true` if `directCommit=true` against protected main
- **What it does:** Calls the `CreateApp` action with `type=PTE` (or `AppSource App` in the AppSource template).
- **Secret needs:** `GhTokenWorkflow` when `useGhTokenWorkflow=true`.

## Create a new test app

- **Display name:** `Create a new test app`
- **File:** `CreateTestApp.yaml`
- **Inputs:** Same as `Create a new app`, `name` defaults to `<YourAppName>.Test`, `idrange` defaults to `50000..99999`.
- **What it does:** Calls `CreateApp` with `type=Test App`.

## Create a new performance test app

- **Display name:** `Create a new performance test app`
- **File:** `CreatePerformanceTestApp.yaml`
- **Inputs:** Same as `Create a new test app` + `sampleSuite` (boolean).
- **What it does:** Calls `CreateApp` for BCPT.

## Add existing app or test app

- **Display name:** `Add existing app or test app`
- **File:** `AddExistingAppOrTestApp.yaml`
- **Inputs:** `project`, `url` (direct download URL of `.app` or `.zip`), `directCommit`, `useGhTokenWorkflow`.
- **What it does:** Calls `AddExistingApp` to import a `.app` or `.zip` into the repo.

## Create Online Dev. Environment

- **Display name:** `Create Online Dev. Environment`
- **File:** `CreateOnlineDevelopmentEnvironment.yaml`
- **Inputs:** `project`, `environmentName`, `reUseExistingEnvironment` (boolean), `directCommit`, `useGhTokenWorkflow`.
- **What it does:** Calls `CreateDevelopmentEnvironment` to provision an online dev sandbox via the BC Admin Center API and update `launch.json`.
- **Secret needs:** `AdminCenterApiCredentials` (refresh-token JSON) OR a device-login prompt in the workflow log.

## Create release

- **Display name:** `Create release`
- **File:** `CreateRelease.yaml`
- **Trigger:** `workflow_dispatch` (with concurrency lock)
- **Inputs:**
  - `buildVersion` (string, default `latest`)
  - `name` (string) — release display name, e.g. `v1.0`
  - `tag` (string) — semver tag, e.g. `1.0.0`
  - `releaseType` (enum) — `Release` / `Prerelease` / `Draft`
  - `createReleaseBranch` (boolean, default `false`)
  - `directCommit` (boolean, default `false`)
  - `useGhTokenWorkflow` (boolean)
  - `updateVersionNumber` (string) — e.g. `+0.1`, `+1`, or a literal version
- **What it does:** Tags HEAD, builds release notes, publishes a GitHub release with `.app` artifacts + source, opens an `Increment Version Number` PR for the next dev cycle.
- **Secret needs:** `GhTokenWorkflow` when `useGhTokenWorkflow=true`.

## Increment Version Number

- **Display name:** `Increment Version Number`
- **File:** `IncrementVersionNumber.yaml`
- **Inputs:** `projects` (string, default `*`), `versionNumber` (`Major.Minor[.Build]` OR `+1` / `+0.1` / `+0.0.1`), `skipUpdatingDependencies` (boolean), `directCommit`, `useGhTokenWorkflow`.

## Publish To Environment

- **Display name:** `Publish To Environment`
- **File:** `PublishToEnvironment.yaml`
- **Inputs:**
  - `appVersion` (string) — `current` / `prerelease` / `draft` / `latest` / `PR_<id>` / explicit version
  - `environmentName` (string) — env-name mask supported, e.g. `PROD*`
  - `createEnvIfNotExists` (boolean, default `false`)
- **What it does:** Resolves the matching environments (honoring `DeployTo<envName>` settings), downloads the matching artifact, and publishes.
- **Secret needs:** `AuthContext` or `<EnvironmentName>_AuthContext`.

## Publish To AppSource (AppSource template only)

- **Display name:** `Publish To AppSource`
- **File:** `PublishToAppSource.yaml`
- **Inputs:**
  - `appVersion` (string) — `current` / `prerelease` / `draft` / `latest` / version
  - `projects` (string, default `*`)
  - `GoLive` (boolean, default `false`) — `true` promotes the submission past Preview to public AppSource immediately
- **What it does:** Calls `Deliver` with `deliveryTarget=AppSource`, `type=Release`.
- **Secret needs:** `AppSourceContext`.
- **Settings needs:** `deliverToAppSource.productId` (AppSource product GUID), `appSourceCopMandatoryAffixes`.
- **Manual prereq:** The first time a product appears in Partner Center, marketing materials must be uploaded by a human. This workflow handles subsequent versions.

## Update AL-Go System Files

- **Display name:** `Update AL-Go System Files`
- **File:** `UpdateGitHubGoSystemFiles.yaml`
- **Triggers:** `workflow_dispatch` AND `workflow_call`
- **Inputs:** `templateUrl` (override), `downloadLatest` (boolean), `directCommit` (boolean), `includeBranches` (comma list), `caller` (for `workflow_call`)
- **What it does:** Calls `CheckForUpdates` with `update=Y`. Schedules via `workflowSchedule` setting use direct commit.
- **Secret needs:** `GhTokenWorkflow`.

## Test Current / Test Next Minor / Test Next Major

- **Display names:** `Test Current`, `Test Next Minor`, `Test Next Major`
- **Files:** `Current.yaml`, `NextMinor.yaml`, `NextMajor.yaml`
- **Trigger:** `workflow_dispatch`
- **Inputs:** none
- **What it does:** Re-runs the build against the current / next minor / next major BC version artifact. Uses `.github/Test Current.settings.json`, `.github/Test Next Minor.settings.json`, `.github/Test Next Major.settings.json` for overrides.

## Deploy Reference Documentation

- **Display name:** `Deploy Reference Documentation`
- **File:** `DeployReferenceDocumentation.yaml`
- **Trigger:** `workflow_dispatch`
- **Inputs:** none
- **What it does:** Builds and deploys the `aldoc` static site to GitHub Pages. Honors the `alDoc` setting.

## Troubleshooting

- **Display name:** `Troubleshooting`
- **File:** `Troubleshooting.yaml`
- **Trigger:** `workflow_dispatch`
- **Inputs:** `displayNameOfSecrets` (boolean) — if `true`, dumps the _names_ of available secrets (not values).
- **What it does:** Diagnostic dump of repo settings and (optionally) configured secret names. The first thing to run when an AL-Go workflow misbehaves.

## Pull Power Platform changes / Push Power Platform changes (PTE template only)

- **Files:** `PullPowerPlatformChanges.yaml`, `PushPowerPlatformChanges.yaml`
- **Inputs:** `environment` (string), `solutionFolder` (string), `directCommit`, `useGhTokenWorkflow` (Pull only)
- **What they do:** Sync the Power Platform solution folder with the connected PP environment.

## Reusable / internal workflows (do NOT dispatch directly)

- `_BuildALGoProject.yaml` — reusable per-project build (called by CI/CD, PR, Current/NextMinor/NextMajor).
- `_BuildPowerPlatformSolution.yaml` — reusable PP build (PTE template).

## Secrets reference

| Secret                                | Purpose                                                                                      | Shape                                                                                                                                              |
| ------------------------------------- | -------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Azure_Credentials`                   | Azure KeyVault + Trusted Signing                                                             | JSON `{keyVaultName, clientId, tenantId[, clientSecret]}`                                                                                          |
| `AuthContext` or `<env>_AuthContext`  | Deploy to BC environment                                                                     | JSON; `refreshToken` (impersonation) or S2S (`clientId`+`clientSecret` or federated credential). Scope `https://api.businesscentral.dynamics.com/` |
| `AppSourceContext`                    | Deliver to AppSource                                                                         | JSON for Partner Center API. Scope `https://api.partner.microsoft.com/.default`                                                                    |
| `StorageContext`                      | Deliver to Azure Storage                                                                     | JSON with `containerName` + `blobName` placeholders `{project}`/`{version}`/`{branch}`/`{type}`                                                    |
| `GitHubPackagesContext`               | Deliver to GitHub Packages NuGet feed (+ auto dependency resolution)                         | JSON `{token, serverUrl}`; classic PAT with `write:packages`+`read:packages`                                                                       |
| `NuGetContext`                        | Deliver to NuGet (not auto-used for resolution; add to `trustedNuGetFeeds` if needed)        | Provider-specific                                                                                                                                  |
| `GhTokenWorkflow`                     | Update AL-Go System Files, Create release, Increment Version Number, Create a new app family | GitHub App: JSON `{GitHubAppClientId, PrivateKey}` (recommended). PAT: plain string. Required scopes: R/W Contents + PRs + Workflows; R Actions.   |
| `GitSubmodulesToken`                  | Private submodules when `useGitSubmodules` set                                               | PAT                                                                                                                                                |
| `LicenseFileUrl`                      | Specific license file URL for CI/CD (AppSource pre-BC22)                                     | URL string                                                                                                                                         |
| `AdminCenterApiCredentials`           | BC Admin Center API for Create Online Dev. Environment                                       | JSON `{refreshtoken}`                                                                                                                              |
| `applicationInsightsConnectionString` | Telemetry connection string injected into apps                                               | Connection string                                                                                                                                  |

For minting these JSONs, see the `/al-secrets-setup` command — it wraps BcContainerHelper's `New-BcAuthContext`, `New-ALGoAuthContext`, `New-ALGoAppSourceContext`, `New-ALGoStorageContext`, `New-ALGoNuGetContext` helpers.

## Settings indirection (when secret names differ from defaults)

Several settings let you point at differently-named secrets:

- `licenseFileUrlSecretName` (default `LicenseFileUrl`)
- `ghTokenWorkflowSecretName` (default `GhTokenWorkflow`)
- `adminCenterApiCredentialsSecretName` (default `AdminCenterApiCredentials`)
- `codeSignCertificateUrlSecretName` / `codeSignCertificatePasswordSecretName` (legacy signing)
- `keyVaultCodesignCertificateName` (new KV-based signing — required when `useCompilerFolder: true`)
- `storageContextSecretName` (default `StorageContext`)
- `applicationInsightsConnectionStringSecretName` (default `applicationInsightsConnectionString`)

When the user has chosen non-default secret names (visible in `.AL-Go/settings.json` or `.github/AL-Go-Settings.json`), honor them.
