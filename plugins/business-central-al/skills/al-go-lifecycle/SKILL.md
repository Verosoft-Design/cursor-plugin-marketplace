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
2. **Discover the AL-Go version.** Read `templateUrl` from `.github/AL-Go-Settings.json`. Format: `https://github.com/<owner>/<repo>[@branch-or-tag]`. **Never hardcode `@v9.0`** — the user's `Update AL-Go System Files` workflow moves this forward over time.
3. **Discover the workflow file's actual name.** AL-Go workflow names sometimes have leading spaces (e.g. ` CI/CD`). Use `gh workflow list --all` to find the workflow's filename and dispatch by file rather than display name when ambiguous.
4. **Check secret existence** (when relevant). Use `gh secret list` (or `gh secret list --env <env>` for environment secrets) before dispatching workflows that need a secret:
   - `GhTokenWorkflow` for `Update AL-Go System Files`, `Create release`, `Increment Version Number`, `Create a new app` family
   - `AuthContext` / `<env>_AuthContext` for `Publish To Environment`
   - `AppSourceContext` for `Publish To AppSource`
   - `AdminCenterApiCredentials` for `Create Online Dev. Environment`
   - `Azure_Credentials` when Azure KeyVault is wired
5. **For AppSource-publish or production-deploy operations**, require explicit user confirmation in the current turn before invoking. These are not reversible from the agent side.

If any preflight check fails, surface the gap and the suggested fix (e.g. "the `AppSourceContext` secret is missing — run `/al-secrets-setup` to mint it") rather than guessing.

## Dispatch pattern

The canonical shape:

```bash
gh workflow run "<Workflow Display Name>" \
  --repo <owner>/<repo> \
  --ref <branch> \
  -f <input1>=<value1> \
  -f <input2>=<value2>
```

When the workflow has multiple files with similar names, prefer `--workflow <filename>`:

```bash
gh workflow run --workflow CICD.yaml --ref main
```

After dispatch, immediately follow with:

```bash
# Get the run ID of the just-triggered run
gh run list --workflow "<name>" --branch <branch> --limit 1 --json databaseId --jq '.[0].databaseId'

# Watch it
gh run watch <run-id> --exit-status
```

`gh run watch --exit-status` blocks until completion and exits non-zero on failure. On failure, surface the run URL (`gh run view <run-id> --web`) plus the first ~20 lines of the failure log (`gh run view <run-id> --log-failed | head -50`).

## Routing user intent to workflows

| User intent                                      | Workflow                                                                             | Plugin command                                    |
| ------------------------------------------------ | ------------------------------------------------------------------------------------ | ------------------------------------------------- |
| Create a new PTE repo                            | (manual: `gh repo create --template microsoft/AL-Go-PTE`) + `Create a new app`       | `/al-new-pte`                                     |
| Create a new AppSource repo                      | (manual: `gh repo create --template microsoft/AL-Go-AppSource`) + `Create a new app` | `/al-new-appsource`                               |
| Add a test app                                   | `Create a new test app`                                                              | `/al-add-test-app`                                |
| Add a performance test app                       | `Create a new performance test app`                                                  | `/al-add-bcpt-app`                                |
| Import an existing `.app` / `.zip`               | `Add existing app or test app`                                                       | `/al-import-existing-app`                         |
| Spin up an online dev sandbox                    | `Create Online Dev. Environment`                                                     | `/al-create-online-dev-env`                       |
| Deploy a specific build to an env                | `Publish To Environment`                                                             | `/al-publish-to-environment`                      |
| Re-test against current/next BC                  | `Test Current` / `Test Next Minor` / `Test Next Major`                               | `/al-current`, `/al-next-minor`, `/al-next-major` |
| Diagnose AL-Go config                            | `Troubleshooting`                                                                    | `/al-troubleshoot`                                |
| Upgrade AL-Go system files                       | `Update AL-Go System Files`                                                          | `/al-update-system-files`                         |
| Bump version number                              | `Increment Version Number`                                                           | `/al-increment-version`                           |
| Cut a GitHub release                             | `Create release`                                                                     | `/al-release`                                     |
| Ship to AppSource                                | `Publish To AppSource`                                                               | `/al-publish-appsource`                           |
| Publish aldoc reference docs                     | `Deploy Reference Documentation`                                                     | `/al-deploy-docs`                                 |
| Compound (build → publish → release → AppSource) | composes multiple                                                                    | `/al-go-live`                                     |

## Settings discovery

When a workflow's inputs depend on project settings (e.g. `Publish To AppSource` needs `deliverToAppSource.productId`), read the relevant settings file:

- `.github/AL-Go-Settings.json` — repo-level settings (type, templateUrl, runs-on, environments, ContinuousDelivery, etc.).
- `.AL-Go/settings.json` — project-level settings (country, appFolders, testFolders, deliverToAppSource, appSourceCopMandatoryAffixes, etc.).
- For multi-project repos, each project folder has its own `.AL-Go/settings.json`.

When a required setting is missing, point the user at the right place to add it rather than guessing.

## Deprecated settings to avoid

When suggesting settings changes, do NOT use these (per Microsoft's deprecation calendar):

| Setting                          | Removed after         | Use instead                                                        |
| -------------------------------- | --------------------- | ------------------------------------------------------------------ |
| `unusedALGoSystemFiles`          | 2026-10-01            | `customALGoFiles.filesToExclude`                                   |
| `alwaysBuildAllProjects`         | past due (2025-10-01) | `incrementalBuilds.onPull_Request: false` (or `fullBuildPatterns`) |
| `<workflow>Schedule` dynamic key | past due (2025-10-01) | `workflowSchedule` per-workflow settings                           |
| `cleanModePreprocessorSymbols`   | past due (2025-04-01) | `preprocessorSymbols` + conditional settings on `buildModes`       |

## Common failure modes

| Symptom                                                               | Cause                                                                                 | Resolution                                                                           |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `Resource not accessible by integration` on Update AL-Go System Files | Missing `GhTokenWorkflow` secret or insufficient PAT/GitHub App permissions           | `/al-secrets-setup` then re-run                                                      |
| Publish job fails with auth error                                     | Missing or expired `AuthContext` / `<env>_AuthContext`                                | Regenerate via `New-BcAuthContext` + `New-ALGoAuthContext` (see `/al-secrets-setup`) |
| AppSource validation fails                                            | `appSourceCopMandatoryAffixes` not set, or analyzer violations                        | Run `/al-build` with `${AppSourceCop}` analyzer locally first                        |
| Build job hangs / OOM                                                 | Default 8G memory limit insufficient                                                  | Set `memoryLimit: "16G"` in `.AL-Go/settings.json`                                   |
| "Workflow not found"                                                  | Workflow display name has a leading space (e.g. ` CI/CD`)                             | Dispatch via `--workflow CICD.yaml` instead                                          |
| Create release fails on signing                                       | Missing codesign secrets (legacy path) or `keyVaultCodesignCertificateName` (KV path) | Wire signing per `/al-init-keyvault` flow                                            |

## Safety rules

- **Never dispatch a Production environment deployment** without explicit user confirmation containing the word "production" in this turn. AL-Go's `(PROD)` / `(FAT)` environment-name convention is the only thing protecting production from CD; honor it.
- **Never set `GoLive=true` on `Publish To AppSource`** without explicit user confirmation. The AppSource Preview → Live promotion is a public-facing action.
- **Never run `Update AL-Go System Files` with `directCommit=true`** unless the user explicitly opts in. Default to PR so changes are reviewable.
- **First AppSource upload is manual.** The first time a product appears in Partner Center, marketing materials must be uploaded by a human. Surface this when the user runs `/al-publish-appsource` on a never-shipped product.
