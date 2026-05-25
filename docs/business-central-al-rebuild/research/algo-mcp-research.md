# AL‑Go for GitHub + Business Central MCP — Exhaustive Research

> Compiled 2026‑05‑25 by direct inspection of the cloned Microsoft repositories
> (`microsoft/AL-Go`, `microsoft/AL-Go-Actions`, `microsoft/AL-Go-PTE`,
> `microsoft/AL-Go-AppSource`) and the official Microsoft Learn docs for the
> Business Central MCP server, the AL MCP server, ALTool, and the AL Language
> Model Tools for Visual Studio Code. Citations follow each major section.

---

## 1. Executive summary

**End‑to‑end picture.** A Business Central AL extension travels through a
well‑defined lifecycle: scaffold the app folder → develop in VS Code against a
local Docker container or an online sandbox → push to GitHub where AL‑Go
workflows compile, sign, test, package, and version the apps → AL‑Go publishes
the build to one or more sandbox / production environments and/or delivers it
to AppSource, NuGet, GitHub Packages, or Azure Storage. Two complementary
Microsoft MCP servers cover the *development* side and the *runtime* side of
this loop:

- **AL MCP Server** (`altool launchmcpserver`, ships with the AL Language
  extension v17+). A standalone MCP process that exposes the AL compiler,
  publisher, symbol/diagnostic engines, and Entra ID auth helpers as MCP tools
  for any agent (CI, Cursor, Claude, Copilot, etc.). This is the one the user
  was told about — *"deploy the apps, pull symbols from BC environment"*.
- **Business Central MCP Server** (hosted by Microsoft at
  `https://mcp.businesscentral.dynamics.com`). A cloud MCP endpoint that lets
  any MCP client read/write Business Central business data and run bound
  actions through API pages — backed by per‑tenant `MCP Server
  Configuration` records.

**What a Cursor plugin should wrap.** The plugin should orchestrate the
*lifecycle* (scaffolding, settings/secrets management, dispatching AL‑Go
workflows via `gh workflow run` and PRs, watching runs) **and** the
*development inner loop* (symbol pulls, local compile/publish via the AL MCP
server). When the plugin needs to **read or write data** in a deployed BC
tenant (e.g. trigger a test company setup, post a sales order, query telemetry
data, etc.), it can layer the Business Central MCP server on top of the same
agent. Both MCPs are first‑party Microsoft surfaces, so wrapping them is the
sanctioned path.

Sources: <https://github.com/microsoft/AL-Go>,
<https://github.com/microsoft/AL-Go-Actions>,
<https://github.com/microsoft/AL-Go-PTE>,
<https://github.com/microsoft/AL-Go-AppSource>,
<https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-mcp-server>,
<https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-agent-tools-overview>,
<https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/ai/mcp-overview>,
<https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/ai/configure-mcp-server>,
<https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/ai/use-mcp-server-non-microsoft>.

---

## 2. AL‑Go: actions catalog

AL‑Go ships its building blocks as composite GitHub actions in
[`microsoft/AL-Go-Actions`](https://github.com/microsoft/AL-Go-Actions).
Every workflow calls these via `microsoft/AL-Go-Actions/<ActionName>@<ref>`
(the templates currently pin `@v9.0`). Each action is a thin YAML wrapper that
shells into `Invoke-AlGoAction.ps1` → `<ActionName>.ps1`.

The full action set in `AL-Go-Actions/` (verified by `ls` of the cloned
repo):

| Action | Required inputs (key ones) | Outputs (key ones) | Purpose / When to invoke directly |
|---|---|---|---|
| **AddExistingApp** | `project`, `url` (direct download URL of `.app` or `.zip`), `directCommit` | — | Imports an existing AL app folder or compiled `.app` into the repo (used by *Add existing app or test app* workflow). Useful for the plugin's "import a customer's existing PTE" wizard. |
| **AnalyzeTests** | `project`, `testType` | Test summary written to workflow output | Parses results from the test run, used by build job. |
| **BuildPowerPlatform** | `solutionFolder`, `outputFolder`, `outputFileName`, `companyId`, `environmentName`, `appBuild`, `appRevision` | The packed Power Platform solution `.zip` | Builds a Power Platform solution (PAC CLI) inside a build job, stamps version. |
| **BuildReferenceDocumentation** | `artifacts`, `artifactUrl`, `token` | aldoc site folder | Generates the `aldoc` static site for the apps. |
| **CalculateArtifactNames** | `project`, `buildMode`, `suffix` | `AppsArtifactsName`, `TestAppsArtifactsName`, `DependenciesArtifactsName`, `TestResultsArtifactsName`, `BcptTestResultsArtifactsName`, `PageScriptingTestResultsArtifactsName`, `PageScriptingTestResultDetailsArtifactsName`, `BuildOutputArtifactsName`, `ContainerEventLogArtifactsName`, `ErrorLogsArtifactsName`, `PowerPlatformSolutionArtifactsName` | Produces the standardized artifact names so build + publish + deploy + deliver agree. |
| **CheckForUpdates** | `templateUrl`, `downloadLatest`, `update`, `updateBranch`, `directCommit`, `token` (GhTokenWorkflow) | — | Detects (and optionally performs) updates of the AL‑Go *system files* against the template repo. Backs the *Update AL‑Go System Files* workflow. |
| **CompileApps** | `artifact`, `project`, `buildMode`, `dependencyAppsJson`, `dependencyTestAppsJson`, `baselineWorkflowRunId`, `baselineWorkflowSHA` | `.app` files in the configured output folder | Invoked by the workspace‑compilation path (newer container‑less compile mode). |
| **CreateApp** | `project`, `type` (PTE / AppSource App / Test App), `name`, `publisher`, `idrange`, `sampleCode`, `sampleSuite`, `updateBranch`, `directCommit` | — | Scaffolds a new app folder (with `app.json`, `HelloWorld.al`, etc.) and opens a PR (or commits) for the change. Backs *Create a new app*, *Create a new test app*, *Create a new performance test app*. |
| **CreateDevelopmentEnvironment** | `environmentName`, `project`, `adminCenterApiCredentials`, `reUseExistingEnvironment`, `updateBranch`, `directCommit` | — | Provisions an online dev sandbox via the BC Admin Center API and updates `launch.json`. Backs *Create Online Dev. Environment*. |
| **CreateReleaseNotes** | `buildVersion`, `tag_name`, `target_commitish`, `token` | `ReleaseVersion`, `ReleaseNotes` | Builds Markdown release notes from commit history; used by Create Release. |
| **Deliver** | `projects`, `deliveryTarget` (`AppSource` / `Storage` / `NuGet` / `GitHubPackages` / custom), `artifacts`, `type` (`CD` or `Release`), `atypes` (`Apps,Dependencies,TestApps`), `goLive` (AppSource only) | — | **The action that hands a successful build to the outside world.** This is the single point of integration for AppSource delivery (it backs the *Publish To AppSource* workflow), and for NuGet/GitHubPackages/Storage delivery during CI/CD. |
| **Deploy** | `environmentName`, `artifactsFolder`, `type` (`CD` / `Publish`), `deploymentEnvironmentsJson`, `artifactsVersion` | `environmentUrl` | Publishes built `.app`s to a Business Central environment. Honors `DeployTo<EnvironmentName>` settings (SyncMode, Scope, BuildMode, runs‑on, etc.). |
| **DeployPowerPlatform** | `environmentName`, `artifactsFolder`/`solutionFolder`, `deploymentEnvironmentsJson` | — | Push Power Platform solution to a connected PP environment. |
| **DetermineArtifactsForRelease** | `buildVersion`, `GITHUB_TOKEN`, `TOKENFORPUSH`, `ProjectsJson` | `artifacts`, `commitish` | Picks the artifacts to attach to a release tag. |
| **DetermineArtifactUrl** | `project` | `ArtifactUrl` (sandbox or specific country/version) | Resolves the **BC artifact URL** (the platform image used for compilation/test). |
| **DetermineBuildProject** | `skippedProjectsJson`, `project`, `baselineWorkflowRunId` | `BuildIt` | Used by incremental builds to decide whether a project must be rebuilt. |
| **DetermineDeliveryTargets** | `projectsJson`, `checkContextSecrets` | `DeliveryTargetsJson`, `ContextSecrets` | Lists which delivery targets are wired up for the repo (based on which `<Target>Context` secrets exist, plus AL‑Go settings). |
| **DetermineDeploymentEnvironments** | `getEnvironments` (`*`), `type` (`CD` / `Publish` / `All`), `createEnvIfNotExists` | `EnvironmentsMatrixJson`, `DeploymentEnvironmentsJson`, `EnvironmentCount`, `UnknownEnvironment`, `GenerateALDocArtifact`, `DeployALDocArtifact` | Resolves the GitHub environments (and their `DeployTo<env>` settings) into a build matrix. |
| **DetermineProjectsToBuild** | `maxBuildDepth` | `ProjectsJson`, `SkippedProjectsJson`, `ProjectDependenciesJson`, `BuildOrderJson`, `BuildAllProjects`, `BaselineWorkflowRunId`, `BaselineWorkflowSHA` | Scans the repo for AL‑Go projects, calculates dependency graph + build order (multi‑project, multi‑stage CI/CD). |
| **DownloadProjectDependencies** | `project`, `buildMode`, `projectDependenciesJson`, `baselineWorkflowRunId` | `DownloadedApps`, `DownloadedTestApps` | Downloads built artifacts from earlier jobs in the same workflow (and resolves `appDependencyProbingPaths` to other repos). |
| **DumpWorkflowInfo** | — | — | Logs workflow context for support/telemetry. |
| **GetArtifactsForDeployment** | `artifactsVersion` (`current` / `prerelease` / `draft` / `latest` / `PR_<id>` / version no.), `artifactsFolder`, `buildMode`, `token` | — | Resolves which build's artifacts to deploy when running *Publish To Environment* manually. |
| **GetWorkflowMultiRunBranches** | `workflowEventName`, `includeBranches` (comma‑separated patterns) | `Result` (JSON `{branches: []}`) | Calculates which branches to fan out to (used by Update AL‑Go System Files when configured to update multiple branches). |
| **IncrementVersionNumber** | `projects`, `versionNumber` (`Major.Minor[.Build]` *or* `+1` / `+0.1` / `+0.0.1`), `skipUpdatingDependencies`, `updateBranch`, `directCommit` | — | Bumps repo / app version numbers. Backs *Increment Version Number*. |
| **PipelineCleanup** | `project` | — | Cleans up local artifacts / containers after a build. |
| **ProcessALCodeAnalysisLogs** | `errorLogsFolder` | SARIF uploaded to GitHub Security tab | Converts AL compiler error logs to SARIF; used when `trackALAlertsInGitHub` = true. |
| **PullPowerPlatformChanges** | `environmentName`, `solutionFolder`, `deploymentEnvironmentsJson`, `updateBranch`, `directCommit` | — | Pulls latest from PP environment into the repo (PR or direct commit). |
| **PullRequestStatusCheck** | — | — | The mandatory “status check” job at the tail of PR builds (gate). |
| **ReadPowerPlatformSettings** | `deploymentEnvironmentsJson`, `environmentName` | `ppEnvironmentUrl`, `ppUserName`, `ppPassword`, `ppApplicationId`, `ppTenantId`, `ppClientSecret`, `companyId`, `environmentName` | Parses `DeployTo<env>` + `<env>_AUTHCONTEXT` for Power Platform deployments. |
| **ReadSecrets** | `gitHubSecrets`, `getSecrets` (comma‑separated, `*` prefix for encrypted), `useGhTokenWorkflowForPush` | `Secrets` (JSON), `TokenForPush` | The single, sanctioned way to read GH secrets / Azure KeyVault secrets in AL‑Go workflows. |
| **ReadSettings** | `project`, `buildMode`, `workflowName`, `get` (specific keys to extract) | `GitHubRunnerJson`, `GitHubRunnerShell` (and writes other keys as env vars) | Merges org → template‑repo → repo → repo‑var → template‑project → project → workflow → user settings into a final settings object (see §4 for the precedence). |
| **RunPipeline** | `artifact`, `project`, `buildMode`, `installAppsJson`, `installTestAppsJson`, `baselineWorkflowRunId`, `baselineWorkflowSHA`, `token` | Build/test artifacts | The big one — calls `Run-AlPipeline` (BcContainerHelper) inside the build job to create a container, compile, publish, test, sign, etc. Honors every script override in `.AL-Go/`. |
| **RunPSScriptAnalyzer** | — | PSScriptAnalyzer report | Lints PS scripts in `.github` / `.AL-Go`. |
| **Sign** | `azureCredentialsJson`, `pathToFiles`, `timestampService` (default `http://timestamp.digicert.com`), `digestAlgorithm` (default `SHA256`) | — | Signs `.app` files using a certificate stored in an Azure Key Vault (new mechanism — see [Codesigning.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/Codesigning.md)). |
| **Troubleshooting** | `gitHubSecrets`, `displayNameOfSecrets` | — | Diagnostic dump used by the *Troubleshooting* workflow. |
| **ValidateWorkflowInput** | — | — | Validates the workflow's `inputs` against the project settings. |
| **VerifyPRChanges** | `token`, `prBaseRepository`, `pullRequestId` | — | Guards against changes to AL‑Go system files coming from forks. |
| **WorkflowInitialize** | `actionsRepo`, `actionsRef` | `telemetryScopeJson` | First step of every workflow — sets up telemetry scope and prints info. |
| **WorkflowPostProcess** | `telemetryScopeJson`, `currentJobContext`, `actionsRepo`, `actionsRef` | — | Last step of every workflow — finalizes telemetry, summarizes outcome. |
| **DownloadPreviousRelease** | (in newer AL‑Go versions) | — | Pulls the previous release `.app`s for upgrade tests in CI/CD. |
| **RunHook** | hook name + parameters hashtable | — | Executes a `.AL-Go/<HookName>.ps1` script if present. First supported hook: `BuildInitialize` (immediately after `Read settings`). [Experimental] — described in [CustomizingALGoForGitHub.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/CustomizingALGoForGitHub.md). |

Source: directly verified from
`microsoft/AL-Go-Actions/<ActionName>/action.yaml` for every entry above, and
[`README.md`](https://github.com/microsoft/AL-Go-Actions/blob/main/README.md).

---

## 3. AL‑Go: workflows catalog

The PTE and AppSource templates ship **one workflow file per use case**. The
verbatim file list from `AL-Go-PTE/.github/workflows/` (cloned from
`microsoft/AL-Go-PTE@main`):

```
_BuildALGoProject.yaml            (reusable; called by CICD / Current / NextMinor / NextMajor / PR)
_BuildPowerPlatformSolution.yaml  (PTE only; reusable PP build)
AddExistingAppOrTestApp.yaml
CICD.yaml
CreateApp.yaml
CreateOnlineDevelopmentEnvironment.yaml
CreatePerformanceTestApp.yaml
CreateRelease.yaml
CreateTestApp.yaml
Current.yaml
DeployReferenceDocumentation.yaml
IncrementVersionNumber.yaml
NextMajor.yaml
NextMinor.yaml
PublishToEnvironment.yaml
PullPowerPlatformChanges.yaml     (PTE only)
PullRequestHandler.yaml
PushPowerPlatformChanges.yaml     (PTE only)
Troubleshooting.yaml
UpdateGitHubGoSystemFiles.yaml
```

The AppSource template is **identical except** it has no Power Platform
workflows and *adds* `PublishToAppSource.yaml`.

| Workflow | Trigger(s) | Inputs (key) | What it does |
|---|---|---|---|
| **CI/CD** (`CICD.yaml`) — internal name has a leading space ` CI/CD` | `push` to `main` / `release/*` / `feature/*` (configurable via `CICDPushBranches`); `workflow_dispatch` | none | The canonical pipeline. Jobs (in order): `Initialization` → `CheckForUpdates` → `Build` (matrix per project × `buildMode`) → `Deploy` (per environment) → `Deliver` (per delivery target) → `DeployALDoc` → `PostProcess`. Honors `incrementalBuilds`, `useProjectDependencies`, `useGitSubmodules`, runners, deployment branch filters, `(PROD)` / `(FAT)` environment naming convention, etc. |
| **Pull Request Build** (`PullRequestHandler.yaml`) | `pull_request` (default target `main` — configurable via `CICDPullRequestBranches`); `merge_group`. Can be switched to `pull_request_target` (with security caveats) via `pullRequestTrigger`. | none | Pregate check + build all touched projects with `failOn: error` / `newWarning`. Concurrency group cancels prior PR runs. |
| **Create a new app** (`CreateApp.yaml`) | `workflow_dispatch` | `project`, `name`, `publisher`, `idrange`, `sampleCode`, `directCommit`, `useGhTokenWorkflow` | Calls `CreateApp` action with `type=PTE` (or `AppSource App` in the AppSource template). |
| **Create a new test app** (`CreateTestApp.yaml`) | `workflow_dispatch` | Same as CreateApp, `name` defaults to `<YourAppName>.Test`, `idrange` defaults to `50000..99999` | Calls `CreateApp` with `type=Test App`. |
| **Create a new performance test app** (`CreatePerformanceTestApp.yaml`) | `workflow_dispatch` | Same + `sampleSuite` | Calls `CreateApp` for BCPT. |
| **Add existing app or test app** (`AddExistingAppOrTestApp.yaml`) | `workflow_dispatch` | `project`, `url`, `directCommit`, `useGhTokenWorkflow` | Calls `AddExistingApp` to import a `.app` or `.zip`. |
| **Create Online Dev. Environment** (`CreateOnlineDevelopmentEnvironment.yaml`) | `workflow_dispatch` | `project`, `environmentName`, `reUseExistingEnvironment`, `directCommit`, `useGhTokenWorkflow` | Calls `CreateDevelopmentEnvironment`. Needs `AdminCenterApiCredentials` secret (or initiates device login). |
| **Create release** (`CreateRelease.yaml`) | `workflow_dispatch` (with concurrency lock) | `buildVersion` (default `latest`), `name`, `tag` (semver), `releaseType` (`Release` / `Prerelease` / `Draft`), `createReleaseBranch`, `directCommit`, `useGhTokenWorkflow`, `updateVersionNumber` | Promotes a build to a GitHub release, attaches `.app` artifacts + source, kicks off an *Increment Version Number* PR for the next dev cycle. |
| **Increment Version Number** (`IncrementVersionNumber.yaml`) | `workflow_dispatch` | `projects`, `versionNumber`, `skipUpdatingDependencies`, `directCommit`, `useGhTokenWorkflow` | Calls `IncrementVersionNumber`. |
| **Publish To Environment** (`PublishToEnvironment.yaml`) | `workflow_dispatch` | `appVersion` (`current` / `prerelease` / `draft` / `latest` / `PR_<id>` / version), `environmentName` (mask, e.g. `PROD*`), `createEnvIfNotExists` | Calls `GetArtifactsForDeployment` then `Deploy` for the resolved environments. Used for production / manual deploys (since `(PROD)` environments are filtered out of CD). |
| **Publish To AppSource** (`PublishToAppSource.yaml`, AppSource template only) | `workflow_dispatch` | `appVersion` (`current` / `prerelease` / `draft` / `latest` / version), `projects`, `GoLive` (boolean) | Reads `AppSourceContext` secret, calls `Deliver` with `deliveryTarget=AppSource`, `type=Release`, optional `goLive=true` to promote. |
| **Update AL‑Go System Files** (`UpdateGitHubGoSystemFiles.yaml`) | `workflow_dispatch` and `workflow_call` | `templateUrl`, `downloadLatest`, `directCommit`, `includeBranches`, `caller` (for `workflow_call`) | Calls `CheckForUpdates` with `update=Y`. Needs `GhTokenWorkflow` secret (PAT or GitHub App). Can be put on a schedule via `workflowSchedule`. |
| **Test Current** (`Current.yaml`) | `workflow_dispatch` | none | Re‑runs build against the *current* Business Central version. Uses `.github/Test Current.settings.json`. |
| **Test Next Minor** (`NextMinor.yaml`) | `workflow_dispatch` | none | Re‑runs build against the upcoming minor release artifact. Uses `.github/Test Next Minor.settings.json`. |
| **Test Next Major** (`NextMajor.yaml`) | `workflow_dispatch` | none | Re‑runs build against the upcoming major release artifact. Uses `.github/Test Next Major.settings.json`. |
| **Deploy Reference Documentation** (`DeployReferenceDocumentation.yaml`) | `workflow_dispatch` | none | Builds and deploys the `aldoc` site to GitHub Pages. Honors the `alDoc` setting. |
| **Pull Power Platform changes** (`PullPowerPlatformChanges.yaml`, PTE only) | `workflow_dispatch` | `environment`, `solutionFolder`, `directCommit`, `useGhTokenWorkflow` | Calls `PullPowerPlatformChanges`. |
| **Push Power Platform changes** (`PushPowerPlatformChanges.yaml`, PTE only) | `workflow_dispatch` | `environment`, `solutionFolder` | Calls `DeployPowerPlatform`. |
| **Troubleshooting** (`Troubleshooting.yaml`) | `workflow_dispatch` | `displayNameOfSecrets` | Dumps repo settings + (optionally) the *names* of available secrets. Useful diagnostic when wiring up a plugin. |
| `_BuildALGoProject.yaml` | `workflow_call` only (reusable) | `shell`, `runsOn`, `checkoutRef`, `project`, `projectName`, `skippedProjectsJson`, `buildMode`, … | Reusable workflow that performs *one* project build. CI/CD, PR, Current/NextMinor/NextMajor all delegate to it. |
| `_BuildPowerPlatformSolution.yaml` | `workflow_call` only (PTE) | Similar shape | Reusable workflow that builds a Power Platform solution. |

Sources: all `.github/workflows/*.yaml` in
[`microsoft/AL-Go-PTE@main`](https://github.com/microsoft/AL-Go-PTE/tree/main/.github/workflows)
and
[`microsoft/AL-Go-AppSource@main`](https://github.com/microsoft/AL-Go-AppSource/tree/main/.github/workflows);
the *Customizing AL‑Go* doc
([CustomizingALGoForGitHub.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/CustomizingALGoForGitHub.md))
describes how to add custom jobs / scripts / workflows without losing them on
upgrade.

---

## 4. AL‑Go: settings schema

### 4.1 Settings precedence (top → bottom; later wins)

Verbatim from [`Scenarios/settings.md`](https://github.com/microsoft/AL-Go/blob/main/Scenarios/settings.md):

1. `ALGoOrgSettings` — GitHub **org variable** (org‑wide defaults).
2. `.github/AL-Go-TemplateRepoSettings.doNotEdit.json` — custom template repo
   defaults (created automatically when you use a custom template).
3. `.github/AL-Go-Settings.json` — **repository settings file**. Also holds
   `BcContainerHelper` settings (which are NOT read from GH variables).
4. `ALGoRepoSettings` — GitHub **repo variable** (per‑repo override).
5. `.github/AL-Go-TemplateProjectSettings.doNotEdit.json` — custom template
   project defaults.
6. `.AL-Go/settings.json` — **project settings file** (one per AL‑Go project
   folder; root in single‑project repos).
7. `.github/<workflow>.settings.json` — workflow‑specific overrides for *all*
   projects (e.g. `Test Current.settings.json`, `Test Next Minor.settings.json`,
   `Test Next Major.settings.json`).
8. `.AL-Go/<workflow>.settings.json` — workflow‑specific overrides for **one**
   project.
9. `.AL-Go/<username>.settings.json` — per‑developer overrides (rare).

Merging rule: scalar settings are **overwritten**; arrays/objects are
**merged**. Use an `overwriteSettings: [ "key1", "key2" ]` property on a
settings file to force overwrite instead of merge.

`ConditionalSettings` (an array on any settings file) applies settings only
when at least one of `repositories`, `projects`, `buildModes`, `branches`,
`workflows`, `users`, `triggers` matches the current run. Example pattern:

```json
{
  "conditionalSettings": [
    {
      "branches": ["feature/*"],
      "settings": { "doNotPublishApps": true, "doNotSignApps": true }
    }
  ]
}
```

### 4.2 Repository settings (only valid in `.github/AL-Go-Settings.json`)

| Key | Type | Default | Description |
|---|---|---|---|
| `type` | enum | `PTE` | `PTE` or `AppSource App`. The two AL‑Go templates each ship this preset. |
| `projects` | string[] | (auto‑enumerated, 2 levels deep) | List of folders containing `.AL-Go/settings.json` (multi‑project mode). |
| `powerPlatformSolutionFolder` | string | — | The single Power Platform solution folder. |
| `templateUrl` | string | (set by Use this template) | `https://github.com/<owner>/<repo>[@branch]`. Used by *Update AL‑Go System Files*. |
| `runs-on` | string / array | `windows-latest` | Default runner for non‑build housekeeping jobs. |
| `shell` | enum | `powershell` (or `pwsh` if `runs-on` = `ubuntu-*`) | Default shell. |
| `githubRunner` | string / array | (`runs-on`) | Runner for the *build* job (where Docker + alc.exe live). |
| `githubRunnerShell` | enum | (`shell`) | Shell for build job. |
| `environments` | string[] | [] | Logical environments (used when GitHub Environments aren't available, e.g. on free SKUs). |
| `DeliverTo<deliveryTarget>` | object | — | Per‑delivery‑target config; supports `Branches`, `CreateContainerIfNotExist`, `ContinuousDelivery`, etc. |
| `DeployTo<envName>` | object | — | Per‑GitHub‑environment config. Properties: `EnvironmentType` (default `SaaS`), `EnvironmentName`, `Branches`, `Projects`, `DependencyInstallMode` (`install` / `ignore` / `upgrade` / `forceUpgrade`), `includeTestAppsInSandboxEnvironment`, `excludeAppIds`, `Scope` (`Dev` / `PTE`), `SyncMode` (`Add` / `ForceSync` / `Development` / `Clean`), `BuildMode`, `ContinuousDeployment`, `runs-on`, `shell`, `companyId`, `ppEnvironmentUrl`. |
| `alDoc` | object | — | `continuousDeployment`, `deployToGitHubPages` (default `true`), `maxReleases` (default `3`), `groupByProject`, `includeProjects`, `excludeProjects`, `header`, `footer`, `defaultIndexMD`, `defaultReleaseMD`. |
| `useProjectDependencies` | boolean | `false` | Enable multi‑stage builds with cross‑project dependencies. |
| `CICDPushBranches` | string[] | `[ "main", "release/*", "feature/*" ]` | Branches that trigger CI/CD. Recognized release branch patterns: `releases/26`, `releases/26.x`, `releases/26x`, `releases/v26`, `releases/v26.x`, `releases/v26x`, `releases/26.3`. |
| `CICDPullRequestBranches` | string[] | `[ "main" ]` | PR target branches that trigger PR build. |
| `pullRequestTrigger` | enum | `pull_request` | Or `pull_request_target` for secret access from forks (security caveats!). |
| `buildModes` | string[] | `[]` (implicit `Default`) | Each project gets built once per build mode. Reserved names: `Default`, `Clean`, `Translated`. |
| `useGitSubmodules` | enum | `false` | `true` or `recursive`. Uses `gitSubmodulesToken` (or `gitSubmodulesTokenSecretName`) for private submodules. |
| `commitOptions` | object | — | `messageSuffix`, `createPullRequest`, `pullRequestAutoMerge`, `pullRequestMergeMethod` (`merge` / `squash`), `pullRequestLabels`. |
| `incrementalBuilds` | object | `{ onPush:false, onPull_Request:true, onSchedule:false, retentionDays:30, mode:"modifiedProjects" }` | Mode can be `modifiedProjects` or `modifiedApps`. |
| `workflowDefaultInputs` | array of `{name, value}` | `[]` | Per‑workflow defaults for `workflow_dispatch` / `workflow_call` inputs. Subject to type/choice validation by Update AL‑Go System Files. |
| `unusedALGoSystemFiles` | string[] | `[]` | **Deprecated after 2026‑10‑01** — use `customALGoFiles.filesToExclude` instead. |
| `customALGoFiles` | object | `{filesToInclude:[], filesToExclude:[]}` | Each item: `sourceFolder`, `filter`, `destinationFolder`, `perProject`. |
| `updateALGoSystemFilesEnvironment` | string | — | If set, Update AL‑Go System Files reads `GhTokenWorkflow` from this GitHub environment (approval gate possible). |

### 4.3 Basic project settings (`.AL-Go/settings.json`)

| Key | Type | Default | Description |
|---|---|---|---|
| `country` | string | `us` | Country localization to build/test against. |
| `repoVersion` | string | `1.0` | Major.Minor (.Build for vs 3 / 3+16). Drives build artifact naming. |
| `projectName` | string | (relative path) | Friendly project name. |
| `appFolders` | string[] | `[]` (auto‑discovered) | Folders with apps; built and published in dependency order. |
| `testFolders` | string[] | `[]` | Folders with test apps. |
| `bcptTestFolders` | string[] | `[]` | Folders with performance‑test apps. |
| `pageScriptingTests` | string[] | `[]` | Page scripting test specs (`recordings/*.yml`). |
| `doNotRunpageScriptingTests` | boolean | `false` | Build but don't run page scripting tests. |
| `restoreDatabases` | string[] | `[]` | Events: `BeforeBcpTests`, `BeforePageScriptingTests`, `BeforeEachTestApp`, `BeforeEachBcptTestApp`, `BeforeEachPageScriptingTest`. |
| `appDependencyProbingPaths` | array of `{repo, version, release_status, projects, branch, AuthTokenSecret}` | `[]` | Cross‑repo dependencies. |
| `preprocessorSymbols` | string[] | `[]` | AL preprocessor symbols (combine with conditional settings for per‑buildMode). |
| `bcptThresholds` | object | `{ DurationWarning:10, DurationError:25, NumberOfSqlStmtsWarning:5, NumberOfSqlStmtsError:10 }` | BCPT regression thresholds. |
| `postponeProjectInBuildOrder` | boolean | `false` | Push project to the tail of the build sequence when no one depends on it. |
| `projectsToTest` | string[] | `[]` | Marks the project as a *test‑only* project that installs other projects' apps and runs tests against them. |

#### AppSource‑specific basic settings

| Key | Type | Default | Description |
|---|---|---|---|
| `appSourceCopMandatoryAffixes` | string[] | `[]` | Affixes enforced by AppSourceCop AS0011. |
| `deliverToAppSource` | object | — | `{ branches, productId, mainAppFolder, continuousDelivery, includeDependencies }`. `productId` (AppSource product GUID) is mandatory. |
| `obsoleteTagMinAllowedMajorMinor` | string | — | Enables AppSourceCop rule AS0105. |

### 4.4 Advanced settings (relevant ones)

| Key | Default | Description |
|---|---|---|
| `artifact` | (latest sandbox for `country`) | Search pattern `<storageaccount>/<type>/<version>/<country>/<select>` (or absolute URL). `version="*"` + `select="first"|"latest"` picks based on `app.json` application dependency. |
| `updateDependencies` | `false` | Stamps actual BC build version into app.json deps (⚠ not recommended for AppSource). |
| `generateDependencyArtifact` | `false` | Produces an extra `-Dependencies-...` artifact. |
| `companyName` | (default for country) | Company used inside the build container. |
| `versioningStrategy` | `0` | `0`=run_number, `2`=date/time, `3`=app.json+run_number, `15`=max/run_number; `+16` → use `repoVersion` for Major.Minor. |
| `additionalCountries` | `[]` | Extra countries to build+publish+test against per workflow. |
| `keyVaultName` | — | Azure KeyVault name (if not in `AZURE_CREDENTIALS`). |
| `licenseFileUrlSecretName` | `LicenseFileUrl` | Indirection for license URL secret. |
| `ghTokenWorkflowSecretName` | `GhTokenWorkflow` | Indirection for PAT/GitHub App secret. |
| `adminCenterApiCredentialsSecretName` | `AdminCenterApiCredentials` | Indirection for BC Admin Center refresh token. |
| `installApps` | `[]` | URLs/paths to 3rd‑party `.app`s to install before compile. Supports `${{SECRETNAME}}` substitution. |
| `installTestApps` | `[]` | Same for test apps. Wrap a value in `()` to install but not run the tests. |
| `runTestsInAllInstalledTestApps` | `false` | PREVIEW — run tests in apps published earlier in the pipeline. |
| `configPackages`, `configPackages.<country>` | `[]` | RapidStart packages (`STANDARD` / `EXTENDED` / `EVALUATION` or relative file path). |
| `installOnlyReferencedApps` | `true` | Otherwise installs all found apps. |
| `enableCodeCop` / `enableUICop` / `enableAppSourceCop` / `enablePerTenantExtensionCop` | calc / `false` | Toggle analyzers. |
| `customCodeCops` | `[]` | Paths/URLs to custom analyzer DLLs. |
| `features` | `[]` | Compiler features: `LcgTranslationFile`, `TranslationFile`, `GenerateCaptions`. |
| `enableCodeAnalyzersOnTestApps` | `false` | Apply analyzers to test apps too. |
| `trackALAlertsInGitHub` | `false` | Upload AL diagnostics as SARIF to GitHub Security tab. |
| `failOn` | `error` | `none` / `warning` / `newWarning` / `error`. `newWarning` only fails PRs that *add* warnings. |
| `rulesetFile` | — | Custom AL ruleset filename. |
| `enableExternalRulesets` | `false` | Allow external ruleset references. |
| `vsixFile` | `default` | `default` / `latest` / `preview` / URL — picks the AL Language extension version. |
| `codeSignCertificateUrlSecretName` / `codeSignCertificatePasswordSecretName` | `CodeSignCertificateUrl` / `CodeSignCertificatePassword` | Legacy signing path. |
| `keyVaultCodesignCertificateName` | — | Name of the codesign certificate inside Azure Key Vault (new mechanism — required when `useCompilerFolder: true`). |
| `applicationInsightsConnectionStringSecretName` | `applicationInsightsConnectionString` | App insights connection string secret name. |
| `storageContextSecretName` | `StorageContext` | Indirection for `StorageContext` secret. |
| `alwaysBuildAllProjects` | `false` | **Deprecated after 2025‑10‑01** — use `incrementalBuilds.onPull_Request:false` instead. |
| `fullBuildPatterns` | `[]` | Paths whose changes force a full PR build (e.g. `["Build/*"]`). |
| `skipUpgrade` | `false` | Skip upgrade test step. |
| `cacheImageName` / `cacheKeepDays` | `my` / `3` | Self‑hosted runner Docker image cache. |
| `assignPremiumPlan` | `false` | Auto‑user gets Premium plan in BC container. |
| `enableTaskScheduler` | `false` | Container starts with task scheduler running. |
| `useCompilerFolder` | `false` | Containerless compile path. Use new code signing (Sign action) when enabled. |
| `workspaceCompilation` | `{ enabled:false, parallelism:1 }` | PREVIEW — use `ALTool` `workspace compile` for multi‑project; requires BC 28+; supports incremental in `modifiedApps` mode. |
| `excludeEnvironments` | `[]` | GitHub Environments to ignore for deployment matrix (`github-pages` already excluded). |
| `trustMicrosoftNuGetFeeds` | `true` | Trust the public MS NuGet feeds for symbol/dependency resolution. |
| `trustedNuGetFeeds` | `[]` | Array of `{url, authTokenSecret, patterns, fingerprints}`. |
| `nuGetFeedSelectMode` | `LatestMatching` | `Earliest` / `EarliestMatching` / `Exact` / `Latest` / `LatestMatching`. |
| `trustedSigning` | — | `{ Account, Endpoint, CertificateProfile }` for Azure Trusted Signing. |
| `shortLivedArtifactsRetentionDays` | `1` | Retention for ephemeral artifacts (PR builds, NextMinor/NextMajor). |

#### Expert‑level / rarely used settings

`repoName`, `runNumberOffset`, `applicationDependency` (default `18.0.0.0`),
`installTestRunner`, `installTestFramework`, `installTestLibraries`,
`installPerformanceToolkit`, `doNotBuildTests`, `doNotRunTests`,
`doNotRunBcptTests`, `memoryLimit` (default `8G`), `BcContainerHelperVersion`
(default `latest` or `preview`), `reportSuppressedDiagnostics`.

#### Workflow‑specific settings (only valid in workflow settings files or
conditional settings)

| Key | Description |
|---|---|
| `workflowSchedule` | `{ cron: "<crontab>", includeBranches: [...] }`. Setting cron on CI/CD *stops* push‑triggered runs unless `CICDPushBranches` is set. Default for Update AL‑Go System Files when on a schedule: direct commit, not PR. |
| `workflowConcurrency` | Array of `concurrency:` lines, e.g. `[ "group: ${{ github.workflow }}-${{ github.ref }}", "cancel-in-progress: true" ]`. Recommended for incremental builds. |

#### BcContainerHelper settings (`.github/AL-Go-Settings.json` only — not read
from GH variables)

`baseUrl`, `apiBaseUrl`, `PartnerTelemetryConnectionString`,
`SendExtendedTelemetryToMicrosoft`, `ObjectIdForInternalUse` (default `88123`),
`TreatWarningsAsErrors` (list of AL codes), `DefaultNewContainerParameters`.

### 4.5 Custom delivery / deployment / script overrides

- **Custom delivery target**: drop `.github/DeliverTo<TargetName>.ps1` +
  define `<TargetName>Context` secret. Script receives `$parameters` with
  `project`, `projectName`, `type` (`CD` / `Release`), `appsFolder`,
  `testAppsFolder`, `dependenciesFolder`, `appsFolders[]`,
  `testAppsFolders[]`, `dependenciesFolders[]`, `context`, `RepoSettings`,
  `ProjectSettings`. Default supported targets: `AppSource`, `Storage`,
  `NuGet`, `GitHubPackages` (experimental flags).
- **Custom deployment type**: drop `.github/DeployTo<EnvironmentType>.ps1`
  and reference it via `DeployTo<envName>.EnvironmentType =
  "<EnvironmentType>"`. Default `EnvironmentType` is `SaaS`.
- **`Run-AlPipeline` script overrides**: drop any of `PipelineInitialize.ps1`,
  `DockerPull.ps1`, `NewBcContainer.ps1`, `NewBcCompilerFolder.ps1`,
  `ImportTestToolkitToBcContainer.ps1`, `CompileAppInBcContainer.ps1`,
  `GetBcContainerAppInfo.ps1`, `PublishBcContainerApp.ps1`,
  `UnPublishBcContainerApp.ps1`, `InstallBcAppFromAppSource.ps1`,
  `SignBcContainerApp.ps1`, `ImportTestDataInBcContainer.ps1`,
  `RunTestsInBcContainer.ps1`, `GetBcContainerAppRuntimePackage.ps1`,
  `GetBcContainerEventLog.ps1`, `RemoveBcContainer.ps1`,
  `RemoveBcCompilerFolder.ps1`, `InstallMissingDependencies.ps1`,
  `BackupBcContainerDatabases.ps1`, `RestoreDatabasesInBcContainer.ps1`,
  `PreCompileApp.ps1`, `PostCompileApp.ps1`, `PipelineFinalize.ps1`
  inside `.AL-Go/`.
- **AL‑Go hooks (experimental)**: `.AL-Go/<HookName>.ps1`; only
  `BuildInitialize` is supported today, after `Read settings` and before
  secrets are loaded.
- **Custom jobs**: jobs named `CustomJob<something>` are preserved by Update
  AL‑Go System Files; you can wire them into `needs:` of stock jobs.

### 4.6 Secrets used by AL‑Go

| Secret | Purpose |
|---|---|
| `Azure_Credentials` | Connect to Azure KeyVault (and Trusted Signing). JSON: `{keyVaultName, clientId, tenantId[, clientSecret]}`. Managed identity → federated credential is the recommended path. |
| `AuthContext` or `<EnvironmentName>_AuthContext` | Deploy to BC environment. JSON. Either `refreshToken` (impersonation, ~90 days) or S2S (`clientId`+`clientSecret` or federated credential). Scope `https://api.businesscentral.dynamics.com/`. |
| `AppSourceContext` | Deliver to AppSource (Partner Center API). Scope `https://api.partner.microsoft.com/.default`. |
| `StorageContext` | Deliver to Azure Storage. Supports managed identity, app‑reg/federated, app‑reg/secret, SAS token, account key. JSON includes `containerName` + `blobName` with placeholders `{project}`, `{version}`, `{branch}`, `{type}`. |
| `GitHubPackagesContext` | Deliver to GitHub Packages NuGet feed *and* use it for dependency resolution. JSON: `{token, serverUrl}`. Currently requires classic PAT with `write:packages` + `read:packages` (+ `repo` for private). |
| `NuGetContext` | Deliver to NuGet (Azure DevOps Artifacts, NuGet.org, etc.). Not auto‑used for dependency resolution — add it to `trustedNuGetFeeds` if you want that. |
| `GhTokenWorkflow` | Required for *Update AL‑Go System Files* + workflows that need to modify other workflows. PAT (fine‑grained or classic) **or** `{GitHubAppClientId, PrivateKey}` JSON (recommended). Required scopes: read/write `Contents` + `Pull Requests` + `Workflows`, read `Actions`. |
| `GitSubmodulesToken` | Read access to private submodules when `useGitSubmodules` is set. |
| `LicenseFileUrl` | Specific license file URL for CI/CD (required for AppSource apps pre‑BC22; CRONUS is enough for 22+). |
| `AdminCenterApiCredentials` | Refresh token (`{refreshtoken}`) for the BC Admin Center API used by Create Online Dev. Environment. |
| `applicationInsightsConnectionString` | Telemetry connection string injected into the apps. |

Sources: [settings.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/settings.md),
[secrets.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/secrets.md),
[DEPRECATIONS.md](https://github.com/microsoft/AL-Go/blob/main/DEPRECATIONS.md).

---

## 5. AL‑Go project structure

```
<repo-root>/
├── .github/
│   ├── AL-Go-Settings.json          # repo-level settings: type, templateUrl, ...
│   ├── AL-Go-TemplateRepoSettings.doNotEdit.json    # (if custom template)
│   ├── AL-Go-TemplateProjectSettings.doNotEdit.json # (if custom template)
│   ├── Test Current.settings.json
│   ├── Test Next Minor.settings.json
│   ├── Test Next Major.settings.json
│   ├── RELEASENOTES.copy.md
│   ├── workflows/                    # all AL-Go workflow YAMLs
│   ├── DeliverTo<Target>.ps1         # (optional, custom delivery)
│   ├── DeployTo<EnvType>.ps1         # (optional, custom deployment)
│   └── (optional) custom workflows prefixed with my*/our*/<org>*
├── .AL-Go/                           # project-level (root for single-project)
│   ├── settings.json
│   ├── localDevEnv.ps1
│   ├── cloudDevEnv.ps1
│   ├── <username>.settings.json      # (rare)
│   ├── <workflow>.settings.json      # (rare)
│   ├── <ScriptOverride>.ps1          # (optional; see §4.5)
│   └── <HookName>.ps1                # BuildInitialize hook (experimental)
├── al.code-workspace
├── <app folder 1>/
│   ├── app.json
│   ├── HelloWorld.al                 # etc.
│   ├── .vscode/launch.json
│   └── ...
├── <test app folder>/
│   └── app.json (with test framework dep)
├── <bcpt test app folder>/
│   └── app.json (with performance toolkit dep)
└── <PowerPlatformSolution>/          # (PTE only)
    └── src/, ...
```

For **multi‑project** repos, each subfolder that contains a `.AL-Go/settings.json`
is its own AL‑Go project — they share the repo settings but each has its own
country, app folders, dependencies, build matrix slot. The `projects` repo
setting can pin the exact list (otherwise AL‑Go auto‑enumerates 2 levels deep
under the root). With `useProjectDependencies = true`, builds are staged
through a topologically sorted dependency graph.

Verified by inspecting the bare `AL-Go-PTE` and `AL-Go-AppSource` templates:

```
$ cat AL-Go-PTE/.github/AL-Go-Settings.json
{"$schema": "https://raw.githubusercontent.com/microsoft/AL-Go-Actions/v9.0/.Modules/settings.schema.json",
 "type": "PTE",
 "templateUrl": "https://github.com/microsoft/AL-Go-PTE@main"}

$ cat AL-Go-PTE/.AL-Go/settings.json
{"$schema": "...settings.schema.json",
 "country": "us", "appFolders": [], "testFolders": [], "bcptTestFolders": []}
```

Note that the AppSource template additionally pre‑populates
`appSourceCopMandatoryAffixes: ["<affix>"]`.

---

## 6. AL‑Go scenarios — end‑to‑end recipes

The README enumerates 23 scenarios + 2 migration scenarios. Below is the
condensed recipe for each (every recipe is in `Scenarios/<file>.md` — links
provided).

### 6.1 Get started — new PTE from scratch ([GetStarted.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/GetStarted.md))

Prereq: GitHub account, VS Code (+ AL, git, PowerShell extensions), Docker
(for local container).

1. Navigate to `https://aka.ms/algopte`, **Use this template** → name the
   repo (public or private). The template clones in `.github/`, `.AL-Go/`,
   and an `al.code-workspace`.
2. Actions → **Show more workflows** → **Create a new app** → Run workflow.
   Fill in Name, Publisher, ID range, check **Direct Commit** (else PR).
3. The workflow scaffolds an app folder.
4. `git clone` the repo, `code .`, open the workspace.
5. Run `.AL-Go/localDevEnv.ps1` interactively — it spins up a BC Docker
   container and patches `launch.json`.
6. Press `F5` in `HelloWorld.al`; container is published to.
7. Stage / commit / push → CI/CD workflow auto‑builds the app.

### 6.2 Add a test app ([AddATestApp.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/AddATestApp.md))

Actions → **Create a new test app** → name, publisher, ID range (default
`50000..99999`). Creates a PR with a test app folder; merge it; CI/CD builds
and runs tests. Note: organizational permission *Allow GitHub Actions to
create and approve pull requests* may need enabling.

### 6.3 Register a sandbox environment for CD via S2S ([RegisterSandboxEnvironment.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/RegisterSandboxEnvironment.md))

Prereqs: An online sandbox + an Entra app registered as per [BC docs (S2S)](https://go.microsoft.com/fwlink/?linkid=2217415).

1. Settings → Environments → **New Environment**, name it the same as the
   sandbox.
2. Environment secret `AUTHCONTEXT` =
   `{"TenantID":"...","ClientID":"...","ClientSecret":"..."}` (compressed JSON,
   no newlines).
3. Run **Publish To Environment** workflow with `appVersion=latest`,
   `environmentName=<your env>` (or `*`).
4. CI/CD will deploy on every push to `main` (default for non‑PROD envs).

### 6.4 Create a release ([CreateRelease.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/CreateRelease.md))

Actions → **Create release** → set Name (e.g. `v1.0`), Tag (`1.0.0`,
semver), Release type (Release / Prerelease / Draft), set new version
(`+0.1`). Workflow: tags HEAD, builds release notes, publishes a GH release
with apps + source, opens an *Increment Version Number* PR for `+0.1`.
Subsequent CI/CD uses the prior release as upgrade baseline for tests.

### 6.5 Register a production env for manual deploy ([RegisterProductionEnvironment.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/RegisterProductionEnvironment.md))

Add a GH Environment named `MYPROD (Production)` — the `(Production)` /
`(FAT)` suffix tells AL‑Go *not* to CD here. Set `AUTHCONTEXT` secret. Use
**Publish To Environment** with `appVersion=current` to push the latest
*release* (not latest CI build) to MYPROD. If the BC env name differs from
the GH env name, set `DeployTo<GitHubEnvName>.EnvironmentName`.

### 6.6 Create a GhTokenWorkflow secret ([GhTokenWorkflow.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/GhTokenWorkflow.md))

Two flavors:

- **GitHub App** (recommended). Create app under
  `https://github.com/settings/apps/new` (or `…/organizations/<org>/settings/apps/new`).
  Permissions: R/W Contents, Pull Requests, Workflows; R Actions. Generate a
  private key, install the app in target repos, then run:

  ```powershell
  $appId = '<client id>'
  $pk    = '<path to .pem>'
  @{"GitHubAppClientId"=$appId; "PrivateKey"=([string]::Join('',[IO.File]::ReadAllLines($pk)))} |
      ConvertTo-Json -Compress -Depth 99 | Set-Clipboard
  ```

  Save as repo/org secret `GhTokenWorkflow`.
- **Personal Access Token** — fine‑grained (preferred) or classic. Same
  permissions (Contents/PR/Workflows R+W; Actions R).

Also optional: gate the secret behind a GitHub Environment via
`updateALGoSystemFilesEnvironment` setting.

### 6.7 Update AL‑Go system files ([UpdateAlGoSystemFiles.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/UpdateAlGoSystemFiles.md))

CI/CD prints a warning whenever the `templateUrl` repo has newer system
files. Run *Update AL‑Go System Files* → optional templateUrl override
(`<url>[@branch]`) → optional includeBranches comma list (wildcards) →
creates PR (or direct commit if scheduled / `directCommit=true`). Requires
`GhTokenWorkflow`.

### 6.8 Use Azure KeyVault ([UseAzureKeyVault.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/UseAzureKeyVault.md))

Set up Azure_Credentials per [BC docs](https://learn.microsoft.com/azure/developer/github/connect-from-azure).
Add `"keyVaultName": "<kv>"` to the JSON. Move sensitive secrets (`authContext`,
`ghTokenWorkflow`, `LicenseFileUrl`, codesign cert, etc.) into the KeyVault.
Use the `<secret>SecretName` settings to indirect to the KV secret names
when they differ from defaults.

### 6.9 Create online dev env from VS Code ([CreateOnlineDevEnv.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/CreateOnlineDevEnv.md))

Run `.AL-Go/cloudDevEnv.ps1` locally. Device login to BC Admin Center API.
Compiles and publishes apps into the new env (Dev scope), updates
`launch.json`. Now F5 from VS Code goes to the cloud env.

### 6.10 Create online dev env from GitHub ([CreateOnlineDevEnv2.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/CreateOnlineDevEnv2.md))

Create `AdminCenterApiCredentials` secret =
`{"refreshtoken":"..."}` via
`New-BcAuthContext -includeDeviceLogin | New-ALGoAuthContext | Set-Clipboard`.
Run **Create Online Dev. Environment** workflow → PR updates `launch.json`.
If no secret, the workflow prints a device code in its log for interactive
auth.

### 6.11 Setup CI/CD for existing PTE ([SetupCiCdForExistingPTE.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/SetupCiCdForExistingPTE.md))

Use AL‑Go‑PTE template → run **Add existing app or test app** with the
direct download URL of the existing `.app` / `.zip` → merge the PR → CI/CD
runs.

### 6.12 Setup CI/CD for existing AppSource App ([SetupCiCdForExistingAppSourceApp.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/SetupCiCdForExistingAppSourceApp.md))

Use AL‑Go‑AppSource template, same import flow. **Must** set
`appSourceCopMandatoryAffixes`. For BC <22, set `LicenseFileUrl` secret.
Set `CodeSignCertificateUrl` + `CodeSignCertificatePassword` (or use the
new KeyVault‑based codesigning).

### 6.13 Enable KeyVault for AppSource App ([EnableKeyVaultForAppSourceApp.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/EnableKeyVaultForAppSourceApp.md))

Provide `KeyVaultClientId`, `KeyVaultCertificateUrl`,
`KeyVaultCertificatePassword` (secrets), and set the matching
`...SecretName` properties in `.AL-Go/settings.json` so the build container
loads the KV creds.

### 6.14 Self‑hosted GitHub runner ([SelfHostedGitHubRunner.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/SelfHostedGitHubRunner.md))

Use the [Azure VM Template](https://aka.ms/getbuildagent) (resource group,
VM name, password, number of agents, registration token from GH) **or**
provision manually (Docker + AZ + GIT + 7zip + gh + PowerShell 7 +
VC redist + .NET + .NET SDK). Set `githubRunner: "self-hosted"` (or
specific labels) in repo settings + run Update AL‑Go System Files.
`runs-on` controls housekeeping jobs (use `ubuntu-latest` to save cost),
`githubRunner` controls the heavy build/test job.

### 6.15 Cross‑repo dependencies ([AppDependencies.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/AppDependencies.md))

Add an entry to `appDependencyProbingPaths`:

```json
{"repo":"https://github.com/<owner>/<repo>",
 "version":"latest", "release_status":"release",
 "authTokenSecret":"<secretName>",
 "projects":"*"}
```

The CI/CD workflow downloads apps from the referenced repo (releases /
prereleases / drafts) and installs them in the build container.

### 6.16 DeliveryTargets & NuGet / GitHub Packages ([DeliveryTargets.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/DeliveryTargets.md))

Stable targets: `AppSource`, `Storage`. Experimental: `GitHubPackages`,
`NuGet`. Each target wants:

1. `<Target>Context` secret.
2. Optional `DeliverTo<Target>` object in settings (branch filter,
   `ContinuousDelivery`, etc.).
3. For NuGet feeds you want used for dependency resolution, also add them to
   `trustedNuGetFeeds`. (GitHubPackagesContext is *auto*‑used for both
   delivery and resolution within the same org.)

Custom targets: drop `.github/DeliverTo<X>.ps1` + a `<X>Context` secret
(JSON).

### 6.17 Enable telemetry ([EnablingTelemetry.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/EnablingTelemetry.md))

In `.github/AL-Go-Settings.json`:

```json
"PartnerTelemetryConnectionString": "<App Insights conn string>",
"SendExtendedTelemetryToMicrosoft": true,
"microsoftTelemetryConnectionString": ""   // (to opt out of MS basic telemetry)
```

Telemetry events: `AL-Go action ran/failed`, `AL-Go workflow ran/failed`,
`AL-Go Test Results - Tests`, `AL-Go Test Results - Page scripting Tests`,
`AL-Go Test Results - BCPT Tests`. Common dimensions include
`PowerShellVersion`, `BcContainerHelperVersion`, `WorkflowName`,
`RunnerOs`, `RunId`, `RunNumber`, `RunAttempt`, `Repository`, `ALGoVersion`,
`RepoType` (`AppSource` / `PTE`), etc. Ready‑made KQL queries shipped in the
scenario doc.

### 6.18 Add a performance test (BCPT) app ([AddAPerformanceTestApp.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/AddAPerformanceTestApp.md))

Actions → **Create a new performance test app**. Builds & runs BCPT in CI.
Upload `bcptBaseLine.json` to project root to compare. Set
`bcptThresholds.json` (or `bcptThresholds` setting) for warning/error
thresholds.

### 6.19 Publish to AppSource ([PublishToAppSource.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/PublishToAppSource.md))

Prereqs: an AppSource offer already created manually in Partner Center
(first upload + marketing materials are NOT automatable).

1. Create `AppSourceContext` secret with `New-BcAuthContext` +
   `New-ALGoAppSourceContext` (S2S or device‑login impersonation).
2. Add to `.AL-Go/settings.json`:

```json
"deliverToAppSource": {
  "productId": "<AppSource product GUID>",
  "continuousDelivery": false,
  "mainAppFolder": "BingMaps-AppSource",
  "includeDependencies": ["Freddy Kristiansen_*.app"]
},
"generateDependencyArtifact": true
```

3. Run **Publish To AppSource** with `appVersion=current` (or specific) and
   `GoLive=true` to immediately promote past validation. Otherwise the app
   sits in AppSource as Preview until Go Live is pressed in Partner Center.

### 6.20 Connect to Power Platform ([SetupPowerPlatform.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/SetupPowerPlatform.md))

1. Build `<EnvName>_AUTHCONTEXT` JSON via
   `New-BcAuthContext | New-ALGoAuthContext -ppClientSecret ... -ppApplicationId ...`
   (S2S; or user/pwd for tenants without MFA).
2. Repo settings:

```json
{
  "type":"PTE",
  "powerPlatformSolutionFolder":"<solutionName>",
  "environments":["<GitHubEnv>"],
  "DeployTo<GitHubEnv>":{
    "environmentName":"<BC env>", "companyId":"<BC company id>",
    "ppEnvironmentUrl":"<PP env url>"
  }
}
```

3. Use **Pull Power Platform changes** / **Push Power Platform changes** to
   sync the PP solution folder with the environment.

### 6.21 Service principal for Power Platform ([SetupServicePrincipalForPowerPlatform.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/SetupServicePrincipalForPowerPlatform.md))

Register app in Entra ID with client secret. Add the app as an Application
User of the PP environment with **System admin** (or **Super**) role via
Power Platform admin center.

### 6.22 Try BC + Power Platform samples ([TryPowerPlatformSamples.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/TryPowerPlatformSamples.md))

Two sample repos: [bcsamples‑takeorder](https://github.com/microsoft/bcsamples-takeorder),
[bcsamples‑warehousehelper](https://github.com/microsoft/bcsamples-warehousehelper).
Either fork (full ALM) or manually import the solution + extension `.zip`
files from the latest release.

### 6.23 Customizing AL‑Go ([CustomizingALGoForGitHub.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/CustomizingALGoForGitHub.md))

Five levels, in order of risk:

1. Hide/remove workflows via `customALGoFiles.filesToExclude` (or the
   deprecated `unusedALGoSystemFiles`).
2. Custom delivery / deployment scripts in `.github/`.
3. Custom workflows (prefix `my*` / `our*` / `<org>*`).
4. Custom scripts + `Run-AlPipeline` overrides in `.AL-Go/`.
5. Custom jobs (`CustomJob<…>`) in existing workflows.
6. Custom template repo (recommended for sharing customizations across many
   repos).
7. Fork AL‑Go itself (last resort, hardest to maintain).

`customALGoFiles` settings control which template files Update AL‑Go System
Files syncs — `filesToInclude` and `filesToExclude` each take
`{sourceFolder, filter, destinationFolder, perProject}` items.

### 6.24 Migration A — from Azure DevOps without history ([MigrateFromAzureDevOpsWithoutHistory.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/MigrateFromAzureDevOpsWithoutHistory.md))

Clone ADO repo locally → create new GH repo from AL‑Go template → drag app
folders (NOT `.git`, `.azureDevOps`, `.pipelines`, `scripts`) into the new
repo → set `appFolders`/`testFolders`/`appSourceMandatoryAffixes`/etc. → push.

### 6.25 Migration B — from Azure DevOps with history ([MigrateFromAzureDevOpsWithHistory.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/MigrateFromAzureDevOpsWithHistory.md))

Use GitHub's **Import repository** (paste ADO Git URL + Git credentials) →
clone the imported repo → delete `.github`, `.azureDevOps`, `.pipelines`,
`scripts` → drag the relevant pieces of the AL‑Go template (`.AL-Go`,
`.github`) over → modify settings → push → enable Actions → manually run
CI/CD the first time.

### 6.26 Codesigning ([Codesigning.md](https://github.com/microsoft/AL-Go/blob/main/Scenarios/Codesigning.md))

New (post‑2023‑06‑01) signing path: store certificate in a Premium SKU
Azure Key Vault, RBAC roles **Key Vault Crypto User** + **Key Vault
Certificate User** on the app reg / managed identity used in
`Azure_Credentials`. Set
`"keyVaultCodesignCertificateName": "<cert name>"`. AL‑Go uses `.NET Sign`
to sign apps via KV.

---

## 7. AL Language MCP Server (the "development" MCP)

> Sourced verbatim and paraphrased from Microsoft Learn pages dated
> 2026‑05‑03; URLs are the source of record.

### 7.1 What it is

`altool launchmcpserver` is a standalone MCP process that ships with the AL
Language extension for VS Code (v17+) and with the *AL Development Tools*
NuGet package (`Microsoft.Dynamics.BusinessCentral.Development.Tools`,
provides the `al` alias). It exposes the AL compiler, publisher, symbol
search, diagnostics and Entra ID auth helpers as MCP tools, over **stdio**
(recommended) or **HTTP**. Requires .NET 8 runtime.

Source: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-mcp-server>
and <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-agent-tools-overview>.

```bash
# stdio (most common)
altool launchmcpserver --transport stdio
# http (e.g. for shared / remote agents)
altool launchmcpserver --transport http --port 5010
```

`ALTool` also has the related commands `workspace compile`, `compile`,
`GetPackageManifest`, `CreateSymbolPackage`, `GetLatestSupportedRuntimeVersion`,
and `launchlspserver` (a Language Server Protocol surface for autonomous AI
agents). See [ALTool docs](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-tool).

### 7.2 Tool catalog

| Tool | VS Code (LM Tools) | AL MCP | Description |
|---|---|---|---|
| `al_build` | ✓ | ✓ | Compile the project and produce a `.app`. |
| `al_compile` | — | ✓ | Compile **without** producing `.app` (faster validation). |
| `al_publish` | ✓ | ✓ | Publish to a cloud or on‑prem BC environment. |
| `al_downloadsymbols` | ✓ | ✓ | Download symbol packages (from connected BC env or global NuGet/AppSource feeds). |
| `al_symbolsearch` | ✓ | ✓ | Search AL symbols across the project + dependencies. |
| `al_getdiagnostics` | ✓ | ✓ | Retrieve compilation diagnostics with filters. |
| `al_getpackagedependencies` | — | ✓ | List declared `app.json` deps. |
| `al_auth_login` | — | ✓ | Interactive MSAL Entra ID sign‑in; caches token. |
| `al_auth_logout` | — | ✓ | Clear cached MSAL tokens. |
| `al_debug` | ✓ | — | Attach debugger without republishing. |
| `al_setbreakpoint` | ✓ | — | Add/remove/toggle a breakpoint at file+line. |
| `al_snapshotdebugging` | ✓ | — | Snapshot debugging session control. |

#### `al_build` — `tools/call` parameters

| Parameter | Type | Default | Notes |
|---|---|---|---|
| `scope` | enum (`current`/`all`) | `current` | `all` builds the whole workspace in dependency order. |
| `projectPath` | string | first project | Absolute path to the `app.json` folder. |
| `outputPath` | string | default in `app.json` | Override `.app` output folder. |
| `onlyErrors` | bool | `false` | Suppress warnings/info/hints in returned diagnostics. |
| `maxDiagnostics` | int | `100` | — |
| `enableCodeAnalysis` | bool | server default | — |
| `codeAnalyzers` | string[] | server default | `${CodeCop}`, `${AppSourceCop}`, `${PerTenantExtensionCop}`, `${UICop}`. |

Returns: `{ success, diagnostics[] }`. `.app` only produced when build has
no errors.

Source: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-build>

#### `al_compile` (MCP‑only) parameters

| Parameter | Type | Default |
|---|---|---|
| `onlyErrors` | bool | `true` |
| `maxDiagnosticsPerCompilation` | int | `100` |
| `enableCodeAnalysis` | bool | server default |
| `codeAnalyzers` | string[] | server default |

Returns `{ Succeeded, Diagnostics: [{Severity, Code, Location, Description}], Message }`.

Source: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-compile>

#### `al_publish` parameters (MCP variant)

App source:

| Parameter | Type | Description |
|---|---|---|
| `appPath` | string | Absolute path to a `.app` to publish. |
| `projectPath` | string | AL project folder; tool builds then publishes. |

Cloud target:

| Parameter | Type | Description |
|---|---|---|
| `environmentName` | string | e.g. `"sandbox"`. |
| `environmentType` | enum | `"Sandbox"` / `"Production"`. |
| `tenant` | string | tenant domain or GUID. |

On‑prem target:

| Parameter | Type | Description |
|---|---|---|
| `serverUrl` | string | e.g. `http://myserver`. |
| `serverInstance` | string | e.g. `BC`. |
| `port` | int | dev service port. |
| `authentication` | enum | `AAD` / `Windows` / `UserPassword`. |

Deployment options:

| Parameter | Type | Default | Description |
|---|---|---|---|
| `schemaUpdateMode` | enum | `Synchronize` | `Synchronize` / `ForceSync` / `Recreate`. |
| `forceUpgrade` | bool | `false` | Skip version compatibility check. |
| `skipBuild` | bool | `false` | Publish an existing `.app` without rebuilding. |
| `buildDependencies` | bool | `false` | Build & publish all dependencies first. |
| `useInteractiveLogin` | bool | `true` | Open browser for Entra sign‑in if needed. |
| `noCache` | bool | `false` | Force a fresh token. |

VS Code variant exposes `{ debug, type ("full"/"incremental"), fulldependencytree, skipbuild }`.

Source: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-publish>

#### `al_downloadsymbols` parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `projectPath` | string | first project | — |
| `globalSourcesOnly` | bool | `false` | Pulls only from MS NuGet feeds + AppSource (no BC server / auth needed; great for CI). |
| `force` | bool | `false` | Re‑download even if cached. |
| `noCache` | bool | `false` | Bypass token cache. |
| `useInteractiveLogin` | bool | `true` | — |
| `environmentName` | string | — | Overrides `launch.json`. |
| `environmentType` | enum | — | `Sandbox`/`Production`. |
| `tenant` | string | — | — |
| `serverUrl` / `serverInstance` / `port` | — | — | On‑prem overrides. |
| `authentication` | enum | `AAD` | `AAD`/`Windows`/`UserPassword`. |

Saves `.app` symbols into the project's `.alpackages/`.

Source: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-download-symbols>

#### `al_symbolsearch` parameters

**Important:** In AL MCP, parameters are wrapped under a `parameters` key
(unlike every other tool). Example:

```json
{
  "parameters": {
    "query": "Post",
    "filters": {
      "kinds": ["Codeunit"],
      "scope": "project"
    }
  }
}
```

Filters: `kinds`, `objectName`, `memberKinds` (`Field`/`Method`/`Key`/`Action`/`Trigger`),
`namespace`, `access` (`Public`/`Internal`), `obsoleteState`
(`No`/`Pending`/`Removed`), `match` (`name`/`doc`/`all`), `scope`
(`project`/`dependencies`/`all`), `limit` (≤ 200).

Returns `symbols: [{id, name, fullName, kind, namespace, containerName, signature, docSummary, path}]` and a `truncated` flag.

Source: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-symbol-search>

#### `al_getdiagnostics` parameters (AL MCP variant)

`filePath` (single .al/.dal), `folderPath` (recursive), `projectPath`,
`severities[]` (`error`/`warning`/`info`/`hint`), `areas[]`
(`AL`/`AppSourceCop`/`CodeCop`/`PerTenantExtensionCop` etc.),
`limit` (≤ 500).

Source: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-get-diagnostics>

#### `al_getpackagedependencies` parameters

`projectPath`, optional `name` (filter to a single dep).

Returns `{ Succeeded, ModuleName, Dependencies: [{Name, Publisher, Id (GUID), Version}], ErrorMessage }`.

Source: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-get-package-dependencies>

#### `al_auth_login` / `al_auth_logout`

`al_auth_login` parameters:

| Parameter | Type | Default |
|---|---|---|
| `tenant` | string | `"common"` |
| `environmentType` | enum (`OnPrem`/`Sandbox`/`Production`) | `Sandbox` |
| `environmentName` | string | — |
| `applicationFamily` | string | — |
| `usernameHint` | string | — |
| `noCache` | bool | `false` |

Source: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-auth>

### 7.3 Common AL MCP workflows

```text
# Validate-only (PR gate)
al_downloadsymbols (globalSourcesOnly:true)
al_compile (onlyErrors:true)
al_getdiagnostics (severities:["error"])

# Full build & deploy to sandbox
al_auth_login (tenant:"contoso.onmicrosoft.com", environmentType:"Sandbox", environmentName:"sandbox")
al_downloadsymbols
al_build (scope:"current")
al_publish (environmentName:"sandbox", environmentType:"Sandbox", tenant:"contoso.onmicrosoft.com")

# Code quality gate (AppSourceCop)
al_compile (enableCodeAnalysis:true, codeAnalyzers:["${AppSourceCop}"])
al_getdiagnostics (areas:["AppSourceCop"])
```

### 7.4 Cursor `mcp.json` entry (AL MCP)

```json
{
  "mcpServers": {
    "al": {
      "command": "altool",
      "args": ["launchmcpserver", "--transport", "stdio"]
    }
  }
}
```

If `altool` isn't on PATH, point at the AL Language extension's binary
(e.g. `~/.vscode/extensions/ms-dynamics-smb.al-*/bin/win64/altool.exe`) or
install [`Microsoft.Dynamics.BusinessCentral.Development.Tools`](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-tool-package)
NuGet package, which exposes an `al` alias.

---

## 8. Business Central MCP Server (the "runtime data" MCP)

> Microsoft hosts this MCP at `https://mcp.businesscentral.dynamics.com`. It
> is **per‑tenant** (auth via Entra ID, scoped via HTTP headers) and is
> declarative — tools are *not hard‑coded*; an admin curates them by adding
> Business Central API page objects to *MCP Server Configurations* records
> inside the tenant.

Sources:
<https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/ai/mcp-overview>,
<https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/ai/configure-mcp-server>,
<https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/ai/use-mcp-server-non-microsoft>.

### 8.1 Endpoint + headers

- URL: `https://mcp.businesscentral.dynamics.com`
- Transport: HTTP (MCP over HTTPS).
- Headers per request:

| Header | Description | Example |
|---|---|---|
| `TenantId` | Entra tenant GUID | `aaaabbbb-0000-cccc-1111-dddd2222eeee` |
| `EnvironmentName` | BC environment name | `Production` |
| `Company` | Company display name in BC | `CRONUS USA, Inc.` |
| `ConfigurationName` | (optional) The MCP Server Configuration record name (else default behavior applies) | `SalesTeamConfig` |

### 8.2 Authentication (non‑MSFT clients like Cursor)

Microsoft's first‑party clients (VS Code Copilot, Copilot Studio) use a
pre‑registered Entra app. For Cursor / Claude / ChatGPT / MCP Inspector
you **must register your own Entra app**:

1. Microsoft Entra admin center → App registrations → New registration
   (e.g. `BC MCP - Cursor`). Copy the **Application (client) ID**.
2. Authentication → Add redirect URI (Mobile and desktop) using your MCP
   client's redirect URI (Cursor: per Cursor's MCP docs).
3. Add a client secret (if required by the client).
4. API permissions → Microsoft APIs → **Dynamics 365 Business Central** →
   Delegated → `user_impersonation` + `Financials.ReadWrite.All` → Grant
   admin consent.
5. (Optional) Record the registration in BC's *Model Context Protocol (MCP)
   Server Entra Applications* page so end users can discover it.

OAuth params:

| Setting | Value |
|---|---|
| Authorization endpoint | `https://login.microsoftonline.com/{tenant}/oauth2/v2.0/authorize` |
| Token endpoint | `https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token` |
| Scope | `https://mcp.businesscentral.dynamics.com/.default` |
| Auth flow | OAuth 2.0 Authorization Code + PKCE (per MCP auth spec). |

BC MCP exposes Protected Resource Metadata so MCP clients can discover the
above automatically.

### 8.3 How tools are exposed (and how to control them)

This is the key insight for plugin authors: the BC MCP doesn't have a fixed
tool catalog. Tools materialize from **MCP Server Configuration** records
in the BC environment, each of which lists API page objects and
per‑page permissions.

In BC, search for **Model Context Protocol (MCP) Server Configurations** →
New (requires `MCP - ADMIN` permission set):

| General field | Meaning |
|---|---|
| Name | Surface as `ConfigurationName` header. |
| Description | — |
| Active | Disable to instantly kill agents using this config. |
| Dynamic Tool Mode | Tools discovered at runtime (lets you exceed Copilot Studio's 70‑tool limit). |
| Discover Additional Objects | When ON (and Dynamic Tool Mode ON), agent has read‑only access to **all** API pages in the environment, even those not added to the config. |
| Unblock Edit Tools | Master switch — when OFF, every Allow Create/Modify/Delete/Bound Action is forced to `false`. |

Per **Available Tool** entry (one row per API page object):

| Permission | Meaning |
|---|---|
| Allow Read | Read operations enabled. |
| Allow Create | Create operations enabled. |
| Allow Modify | Update operations enabled. |
| Allow Delete | Delete operations enabled. |
| Allow Bound Actions | OData bound actions enabled (e.g. "Post Sales Order"). |

Each permission produces a tool with a name following:

```
List<ObjectName>_PAG<ObjectID>          # Allow Read
Create<ObjectName>_PAG<ObjectID>        # Allow Create
ListUpdate<ObjectName>_PAG<ObjectID>    # Allow Modify
Delete<ObjectName>_PAG<ObjectID>        # Allow Delete
<ActionName><ObjectName>_PAG<ObjectID>  # Allow Bound Actions
```

Example: API page `30009 APIV2 - Customer` with R+M+C+D produces:

- `ListAPIV2 - Customer_PAG30009`
- `CreateAPIV2 - Customer_PAG30009`
- `ListUpdateAPIV2 - Customer_PAG30009`
- `DeleteAPIV2 - Customer_PAG30009`

Configurations can be **Exported / Imported** as JSON (Advanced → Export /
Import) which makes them portable across environments.

**Connection string** (BC: Advanced → Connection String) returns the exact
JSON snippet for an MCP client:

```json
"businesscentral": {
  "url": "https://mcp.businesscentral.dynamics.com",
  "type": "http",
  "headers": {
    "TenantId": "aaaabbbb-0000-cccc-1111-dddd2222eeee",
    "EnvironmentName": "Production",
    "Company": "CRONUS USA, Inc.",
    "ConfigurationName": "MyMCPConfig"
  }
}
```

### 8.4 What BC MCP is *not* good for (for the plugin)

- It is **NOT a deploy/build/publish surface**. Publishing apps, pulling
  symbols, and building `.app` files are not exposed here — those are the
  AL MCP's job.
- It can't directly run `gh workflow run`. Use the GitHub REST/CLI for
  that.
- Tools are constrained to the API page objects an admin has explicitly
  exposed. If your plugin needs an operation that has no API page, the
  partner has to ship a Custom API page first (the
  [Stoneridge article](https://stoneridgesoftware.com/extending-mcp-server-in-business-central-with-custom-api-pages/)
  walks through this; tools follow the same `_PAG<id>` naming).

### 8.5 Cursor `mcp.json` entry (BC MCP)

```json
{
  "mcpServers": {
    "businesscentral": {
      "url": "https://mcp.businesscentral.dynamics.com",
      "type": "http",
      "headers": {
        "TenantId": "<your-entra-tenant-guid>",
        "EnvironmentName": "Production",
        "Company": "CRONUS USA, Inc.",
        "ConfigurationName": "<your MCP Server Configuration name>"
      }
    }
  }
}
```

Cursor still needs to know about your Entra app registration for the OAuth
flow. Provide:

- `clientId` = the Application (client) ID from §8.2 step 1.
- `clientSecret` = (optional, depending on Cursor's MCP support).
- Authority/Authorization URLs as in §8.2.
- Scope: `https://mcp.businesscentral.dynamics.com/.default`.

Cursor will trigger the browser flow on first request; subsequent requests
reuse the cached refresh token.

---

## 9. Related tooling worth wrapping

| Tool | What it does | Why the plugin should know about it |
|---|---|---|
| [**BcContainerHelper**](https://github.com/microsoft/navcontainerhelper) (PowerShell module, [PowerShell Gallery](https://www.powershellgallery.com/packages/BcContainerHelper)) | Docker‑backed BC sandbox helper. Core functions: `New-BcContainer`, `Remove-BcContainer`, `Publish-BcContainerApp`, `Sync-BcContainerApp`, `Install-BcContainerApp`, `Compile-AppInBcContainer`, `Run-TestsInBcContainer`, `Run-AlPipeline` (the engine AL‑Go's `RunPipeline` action calls), `New-BcImage`, `Get-BcArtifactUrl`. Also `New-BcAuthContext`, `New-ALGoAuthContext`, `New-ALGoNuGetContext`, `New-ALGoAppSourceContext`, `New-ALGoStorageContext` (helpers to mint the JSON secrets AL‑Go consumes). | The plugin can call these locally for the inner dev loop (`localDevEnv.ps1` already does) **and** as a setup helper to mint compressed‑JSON secrets for AL‑Go (especially `AppSourceContext`, `AuthContext`, `AdminCenterApiCredentials`, `StorageContext`, `NuGetContext`). |
| [`bccontainerhelper.io`](https://bccontainerhelper.io) | Dedicated docs site for BcContainerHelper. | — |
| [**AL Language extension** for VS Code](https://marketplace.visualstudio.com/items?itemName=ms-dynamics-smb.al) | Provides `altool` (with `launchmcpserver`, `launchlspserver`, `workspace compile`, etc.) and the VS Code Language Model Tools (`al_build`, `al_publish`, `al_downloadsymbols`, `al_symbolsearch`, `al_getdiagnostics`, `al_debug`, `al_setbreakpoint`, `al_snapshotdebugging`). | Wrap the VS Code commands (`AL: Download Symbols`, `AL: Publish`, `AL: Package`) as Cursor commands. The MCP variant is preferable for Cursor agent flows. |
| [**AL Development Tools** NuGet package](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-tool-package) (`Microsoft.Dynamics.BusinessCentral.Development.Tools`) | Cross‑platform `al` alias for headless CI. Same ALTool commands. | Lets a Cursor plugin install ALTool without VS Code (e.g. for headless agents). |
| [**AL LSP server**](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-tool) (`altool launchlspserver`) | LSP surface designed for AI agents. | Alternative integration path if MCP is unavailable. |
| [**BC Admin Center API**](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/administration-center-api) | REST API for managing online environments (create/delete sandboxes, install apps, schedule upgrades, etc.). Used by AL‑Go's `CreateDevelopmentEnvironment` action and `cloudDevEnv.ps1`. | The plugin can hit this directly (with the same refresh token) for environment lifecycle commands beyond what AL‑Go provides. |
| [**GitHub CLI** (`gh`)](https://cli.github.com/) | Required for dispatching AL‑Go workflows, fetching artifacts, watching runs, viewing PRs. | The plugin's spine for invoking AL‑Go workflows. |
| Community MCPs (for context only — **NOT** the Microsoft MCP) | [MS‑Cloud‑Experts/mcp‑business‑central](https://github.com/MS-Cloud-Experts/mcp-business-central) (npm: `@mscloudexperts/mcp-business-central`, 115 tools over OData), [SShadowS/bc‑webclient‑mcp‑server](https://github.com/SShadowS/bc-webclient-mcp-server) (reverse‑engineered WebUI WebSocket protocol), [knowall‑ai/mcp‑business‑central](https://github.com/knowall-ai/mcp-business-central), [yahyatouil-dev/BC‑MCP‑Server](https://github.com/yahyatouil-dev/BC-MCP-Server), [StefanMaron/AL‑Dependency‑MCP‑Server](https://github.com/StefanMaron/AL-Dependency-MCP-Server). | Useful as fallback if the user doesn't want the cloud BC MCP. None are Microsoft‑official; treat as third‑party. |
| [**ALOps**](https://www.alops.eu/) | Commercial Azure DevOps alternative to AL‑Go. | Out‑of‑scope for the plugin but mention for context. |

---

## 10. Concrete Cursor plugin command/skill suggestions

Each row pairs a high‑level Cursor command/skill with the precise AL‑Go
workflow + action invocation (or MCP tool call) it should drive. The "How
the plugin triggers it" column shows the `gh workflow run` form (assuming
the user has authenticated `gh` and is in the repo).

| Cursor command / skill | What it does | How the plugin triggers it |
|---|---|---|
| `/al-new-pte` | Scaffold a new PTE repo. | (1) `gh repo create --template microsoft/AL-Go-PTE …`; (2) `gh workflow run "Create a new app" -f project=. -f name=<n> -f publisher=<p> -f idrange=<r> -f sampleCode=true -f directCommit=true`. |
| `/al-new-appsource` | Scaffold a new AppSource repo. | `gh repo create --template microsoft/AL-Go-AppSource …` + same Create a new app workflow (sets `type=AppSource App` automatically). |
| `/al-new-test-app` | Add a test app. | `gh workflow run "Create a new test app" -f project=<proj> -f name=<n> -f publisher=<p> -f idrange=50000..99999 -f directCommit=false` (creates PR). |
| `/al-new-bcpt-app` | Add a BCPT performance test app. | `gh workflow run "Create a new performance test app" -f project=<proj> -f name=<n> -f publisher=<p> -f idrange=50000..99999 -f sampleSuite=true`. |
| `/al-import-existing-app <url>` | Pull a customer's existing `.app` into a fresh AL‑Go repo. | `gh workflow run "Add existing app or test app" -f project=. -f url=<download URL>`. |
| `/al-create-online-dev-env <env>` | Provision an online dev sandbox + update `launch.json`. | (Pre)check `AdminCenterApiCredentials` secret; `gh workflow run "Create Online Dev. Environment" -f project=<proj> -f environmentName=<env> -f reUseExistingEnvironment=false`. Alt: run `.AL-Go/cloudDevEnv.ps1` locally. |
| `/al-symbols` | Pull symbols for the current project. | **MCP**: `al_downloadsymbols` (with `globalSourcesOnly:true` for offline, or `environmentName`+`tenant` for live). |
| `/al-compile` | Validate AL without producing `.app`. | **MCP**: `al_compile` (then `al_getdiagnostics` if errors). |
| `/al-build` | Build the `.app`. | **MCP**: `al_build` (`scope="current"` or `"all"`). |
| `/al-publish <env>` | Publish to a sandbox env. | **MCP**: `al_auth_login` + `al_publish` (with `environmentName`, `environmentType`, `tenant`). Use `skipBuild:true` to publish an already‑built `.app`. |
| `/al-publish-to-environment <env> <version>` | CI‑driven deploy (uses already‑built artifacts). | `gh workflow run "Publish To Environment" -f appVersion=<ver|current|latest|PR_xxx> -f environmentName=<mask> -f createEnvIfNotExists=false`. |
| `/al-release v1.0` | Cut a GitHub release + auto‑bump version. | `gh workflow run "Create release" -f buildVersion=latest -f name=v1.0 -f tag=1.0.0 -f releaseType=Release -f createReleaseBranch=false -f directCommit=false -f useGhTokenWorkflow=true -f updateVersionNumber=+0.1`. |
| `/al-publish-appsource [--go-live]` | Push the current release to AppSource. | Verify `AppSourceContext` + `deliverToAppSource.productId`. `gh workflow run "Publish To AppSource" -f appVersion=current -f projects=* -f GoLive=<bool>`. (Behind the scenes calls `Deliver` action with `deliveryTarget=AppSource`, `type=Release`.) |
| `/al-version <bump>` | Bump version number(s). | `gh workflow run "Increment Version Number" -f projects=* -f versionNumber=<+0.1|+1|1.2.3> -f skipUpdatingDependencies=false -f directCommit=false -f useGhTokenWorkflow=true`. |
| `/al-update-system-files` | Pull the latest AL‑Go workflows/scripts. | Requires `GhTokenWorkflow` secret. `gh workflow run "Update AL-Go System Files" -f downloadLatest=true -f directCommit=false -f includeBranches=""`. |
| `/al-troubleshoot` | Diagnostic dump. | `gh workflow run "Troubleshooting" -f displayNameOfSecrets=true`. |
| `/al-current` `/al-next-minor` `/al-next-major` | Re‑run build against current/next BC version. | `gh workflow run "Test Current"` / `"Test Next Minor"` / `"Test Next Major"`. |
| `/al-deploy-docs` | Deploy aldoc reference docs to GH Pages. | `gh workflow run "Deploy Reference Documentation"`. |
| `/al-pp-pull <env>` `/al-pp-push <env>` | Sync Power Platform solution. | `gh workflow run "Pull Power Platform changes" -f environment=<env> -f directCommit=false` and `"Push Power Platform changes"`. |
| `/al-symbol-search <query>` | Search AL symbols (IDE+agent). | **MCP**: `al_symbolsearch` (remember the `parameters` wrapper!). |
| `/al-diagnostics` | List compiler/analyzer diagnostics. | **MCP**: `al_getdiagnostics` (filter by `severities`, `areas`). |
| `/al-deps` | List `app.json` dependencies. | **MCP**: `al_getpackagedependencies`. |
| `/bc-query <natural language>` | Query BC business data via Copilot‑style agent. | **BC MCP**: client makes MCP `tools/call` against the user's BC env (with the right `ConfigurationName`). E.g. "List my top 10 customers by sales" → `ListAPIV2 - Customer_PAG30009` + agent reasoning. |
| `/bc-post <doc>` | Run a bound action (e.g. post sales order). | **BC MCP**: requires Allow Bound Actions on the relevant API page. |
| `/al-secrets-setup` | Interactive wizard that mints the various AL‑Go context secrets. | Local PS: `New-BcAuthContext` + `New-ALGoAppSourceContext`/`New-ALGoAuthContext`/`New-ALGoNuGetContext`/`New-ALGoStorageContext` from BcContainerHelper. Pipe to clipboard for the user to paste into `gh secret set <NAME>`. |
| `/al-init-keyvault` | Wire up Azure KeyVault. | Build the `Azure_Credentials` JSON (managed identity + federated credential preferred); `gh secret set AZURE_CREDENTIALS …`; set `keyVaultName` (or include in JSON). |
| `/al-init-self-hosted-runner` | Stand up a self‑hosted runner. | Open `https://aka.ms/getbuildagent` (deploy Azure VM template) **or** write the manual checklist. Then set `githubRunner: "self-hosted"` in repo settings + run Update AL‑Go System Files. |

The plugin can also expose **lifecycle wrappers** that string several of
these together:

- **`/al-go-live`** — `al-build` → `al-publish` to sandbox → run tests via
  AL MCP → `al-release` → `al-publish-appsource --go-live`.
- **`/al-onboard-customer`** — interactive: pick repo template, create new
  repo, scaffold first app, register sandbox env, set up secrets,
  validate by running CI/CD.
- **`/al-migrate-from-ado`** — guides through Migration A or B
  (history/no‑history) flow.

---

## 11. Open questions / risks

1. **Cursor MCP support for hosted HTTP MCP with custom headers + OAuth +
   PKCE.** The BC MCP requires per‑request HTTP headers (`TenantId`,
   `EnvironmentName`, `Company`, optional `ConfigurationName`) and an Entra
   ID OAuth flow. Confirm Cursor's MCP client supports both (this is what
   Microsoft Learn calls out specifically for "non‑Microsoft clients").
2. **`altool` discoverability.** `altool` is shipped inside the AL Language
   VS Code extension; users without VS Code need the AL Development Tools
   NuGet package. The plugin should detect both, and prefer the
   cross‑platform `al` alias when present (mention paths under
   `~/.vscode/extensions/ms-dynamics-smb.al-*/bin/<os>/altool[.exe]`).
3. **AL‑Go pinned `@v9.0` references.** Today's templates pin
   `microsoft/AL-Go-Actions@v9.0`. Update AL‑Go System Files will move
   these forward; the plugin should *not* hard‑code the version. Read
   `templateUrl` and `.github/workflows/*.yaml` to discover the current pin.
4. **First AppSource upload is manual.** No automation can do the initial
   product registration / marketing artifact upload in Partner Center —
   the plugin should make this clear in `/al-publish-appsource`.
5. **Continuous Delivery to AppSource.** When `deliverToAppSource.continuousDelivery=true`,
   every successful CI/CD build is submitted to AppSource validation but
   stays in Preview until someone clicks Go Live (or runs Publish To
   AppSource with `GoLive=true`). The plugin should surface this state.
6. **AppSource S2S vs impersonation.** S2S (recommended) requires Partner
   Center → developer account registration. Plugin should detect missing
   ClientId/TenantId/ClientSecret and offer the device‑login impersonation
   path as a fallback.
7. **Deprecations to avoid baking into the plugin.**
   - `unusedALGoSystemFiles` (removed after **2026‑10‑01**) → use
     `customALGoFiles.filesToExclude`.
   - `alwaysBuildAllProjects` (removed after **2025‑10‑01**) → use
     `incrementalBuilds.onPull_Request:false` (or `fullBuildPatterns`).
   - `<workflow>Schedule` dynamic setting (removed after **2025‑10‑01**) →
     use `workflowSchedule` setting (per‑workflow settings file or
     conditional settings).
   - `cleanModePreprocessorSymbols` (removed after **2025‑04‑01**) → use
     `preprocessorSymbols` + conditional settings on `buildModes`.
8. **AL‑Go is Windows‑centric for the build job.** Despite supporting
   `ubuntu-latest` for housekeeping (`runs-on`), the build job requires
   Windows + Docker. The plugin should not promise Linux/macOS runners for
   the build stage.
9. **PowerShell 5.1 vs 7 (pwsh).** Default `shell` is `powershell` (5.1) on
   Windows runners. Surface this in any plugin command that suggests
   adding script overrides.
10. **GitHub App vs PAT for `GhTokenWorkflow`.** Microsoft now recommends
    GitHub App auth (no human creator, bot commits). The plugin's secret
    wizard should default to GitHub App and only fall back to PATs.
11. **Custom delivery script API surface.** The `$parameters` hashtable
    passed to `.github/DeliverTo<X>.ps1` includes folder paths that can be
    `$null` if no artifacts of that type were produced. Plugin‑generated
    custom delivery scripts must handle null. (See
    [DeliveryTargets.md → Supported Parameters](https://github.com/microsoft/AL-Go/blob/main/Scenarios/DeliveryTargets.md).)
12. **BC MCP write surface.** The default BC MCP behavior is **read‑only**.
    Any write/post/delete tools must be explicitly enabled by a tenant
    admin on an *MCP Server Configuration* with `Unblock Edit Tools`. The
    plugin's BC MCP write commands should check whether the configured
    `ConfigurationName` permits the relevant operation before issuing it.
13. **API page coverage in BC MCP.** Many BC tables are NOT exposed via
    standard API pages. The plugin might need to ship sample
    *custom API page* AL snippets (under the user's TAG ID range) when a
    requested operation has no exposed surface — Stoneridge's article is a
    good reference for that pattern.

---

## 12. Quick‑reference appendix — URLs

### AL‑Go
- Main repo: <https://github.com/microsoft/AL-Go>
- Actions repo: <https://github.com/microsoft/AL-Go-Actions>
- PTE template: <https://github.com/microsoft/AL-Go-PTE> (`https://aka.ms/algopte`)
- AppSource template: <https://github.com/microsoft/AL-Go-AppSource> (`https://aka.ms/algoappsource`)
- Settings doc: <https://github.com/microsoft/AL-Go/blob/main/Scenarios/settings.md> (`https://aka.ms/algosettings`)
- Secrets doc: <https://github.com/microsoft/AL-Go/blob/main/Scenarios/secrets.md> (`https://aka.ms/algosecrets`)
- Release notes: <https://github.com/microsoft/AL-Go/blob/main/RELEASENOTES.md>
- Deprecations: <https://github.com/microsoft/AL-Go/blob/main/DEPRECATIONS.md>
- Workshop index: <https://github.com/microsoft/AL-Go/blob/main/Workshop/Index.md> (`https://aka.ms/algoworkshop`)
- Roadmap: `https://aka.ms/ALGoRoadmap`
- Issues: <https://github.com/microsoft/AL-Go/issues>
- Contribute: <https://github.com/microsoft/AL-Go/blob/main/Scenarios/Contribute.md>

### MCP / AL development tools
- AI agent tools overview: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-agent-tools-overview>
- AL MCP server: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-mcp-server>
- VS Code Language Model tools: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-language-model-tools-vscode>
- `al_build` ref: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-build>
- `al_compile` ref: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-compile>
- `al_publish` ref: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-publish>
- `al_downloadsymbols` ref: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-download-symbols>
- `al_symbolsearch` ref: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-symbol-search>
- `al_getdiagnostics` ref: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-get-diagnostics>
- `al_getpackagedependencies` ref: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-get-package-dependencies>
- `al_auth_login`/`al_auth_logout` ref: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/al-agent-tools/al-tool-auth>
- ALTool: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-tool>
- AL Development Tools NuGet package: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-tool-package>

### BC MCP (data‑side, hosted)
- MCP overview: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/ai/mcp-overview>
- Configure MCP server: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/ai/configure-mcp-server>
- Use with non‑Microsoft clients (Cursor, Claude, etc.): <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/ai/use-mcp-server-non-microsoft>
- Use with VS Code: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/ai/use-mcp-server-vscode>
- Endpoint: `https://mcp.businesscentral.dynamics.com`

### Adjacent tools
- BcContainerHelper repo: <https://github.com/microsoft/navcontainerhelper>
- BcContainerHelper docs: <https://www.bccontainerhelper.io/>
- BcContainerHelper NuGet (PowerShell Gallery): <https://www.powershellgallery.com/packages/BcContainerHelper>
- BC Admin Center API: <https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/administration/administration-center-api>
- AL Language extension (Marketplace): <https://marketplace.visualstudio.com/items?itemName=ms-dynamics-smb.al>
- `aka.ms/getbuildagent` (self‑hosted runner Azure VM template).
- Freddy K's AL‑Go blog series: <https://freddysblog.com/2022/04/26/al-go-for-github/> (and follow‑ups).
