---
name: al-publish-to-environment
description: Deploy a specific build's artifacts to one or more BC environments via the Publish To Environment workflow. Use for production manual deploys (since (PROD)/(FAT) environments are excluded from CD), for promoting a PR build to a sandbox, or for re-deploying an older release.
disable-model-invocation: true
---

# Publish to a BC environment (via AL-Go)

Dispatches the `Publish To Environment` workflow (`PublishToEnvironment.yaml`; display name ` Publish To Environment` has a leading space, so dispatch by file name), which downloads the matching artifact (current / latest / specific version / PR build) and deploys it to the matching GitHub Environments.

## When to use this vs `/al-publish-sandbox`

| Need                                                                | Use                                                        |
| ------------------------------------------------------------------- | ---------------------------------------------------------- |
| Quick deploy from dev machine to a sandbox during the inner loop    | `/al-publish-sandbox` (direct AL MCP call, no CI involved) |
| Promote a successful CI build to one or more managed environments   | `/al-publish-to-environment` (this command)                |
| Deploy to a `(PROD)` / `(FAT)` environment that CI excludes from CD | `/al-publish-to-environment`                               |
| Re-deploy a specific historical release to a env                    | `/al-publish-to-environment` with `appVersion=<version>`   |

## Preflight

1. Confirm cwd is an AL-Go repo.
2. Confirm the target GitHub Environment exists: `gh api /repos/{owner}/{repo}/environments` should list it. Ignore `github-pages` and `copilot` (the environment GitHub creates for the Copilot coding agent): AL-Go always excludes both from deployment, as well as anything in the `excludeEnvironments` setting.
3. Confirm an AuthContext secret will resolve for every matched environment. AL-Go v10.0 checks, in order: `<EnvName>-AuthContext`, `<EnvName>_AuthContext`, then the generic `AuthContext` (repo/org secret, or `AuthContext` as a secret on the GitHub environment). Use `gh secret list --env <EnvName>` and `gh secret list` to check.
   - In multi-environment or multi-tenant repos, a missing per-environment secret **silently falls back** to the generic `AuthContext`. If the user expects per-environment credentials, verify the per-environment secret exists rather than accepting the fallback.
   - If secrets live in Azure Key Vault, names containing `_` are skipped there; the dash form `<EnvName>-AuthContext` is the one that works.
   - If no secret resolves, the `Authenticate` action starts device login and lists the candidate names and sign-in instructions in the workflow summary.
4. **If the target is a Production environment**, require explicit user confirmation containing the word "production" in this turn before proceeding. Resolve the mask first: a mask such as `*` or `PROD*` that matches any production environment counts as a production deployment.

## Gather inputs

- `appVersion` — one of:
  - `current` → the latest release tag
  - `prerelease` → the latest pre-release
  - `draft` → the latest draft release
  - `latest` → the latest CI/CD build (use with care for prod)
  - `PR_<id>` → a specific pull request's build artifact
  - explicit semver like `1.2.3`
- `environmentName` — mask supported. E.g. `PROD*` deploys to every env whose GitHub name starts with `PROD`. A single name targets one env.
- `createEnvIfNotExists` (boolean, default `false`) — only set `true` for first-time provisioning, and only after the user confirms. `<EnvName>_AuthContext`, `<EnvName>_EnvironmentName` and `<EnvName>_Scope` must then exist as environment or repo secrets/variables.

These are the only three inputs in v10.0 (`environmentName` is required; `appVersion` defaults to `current`).

## Dispatch

```bash
gh workflow run PublishToEnvironment.yaml \
  --ref main \
  -f appVersion=<value> \
  -f environmentName=<mask or name> \
  -f createEnvIfNotExists=false
```

## Watch the run

```bash
RUN_ID=$(gh run list --workflow PublishToEnvironment.yaml --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

## After success

The workflow's "Deploy" job per matched environment writes a deployment record visible at `gh api /repos/{owner}/{repo}/deployments`. The user can also see it in GitHub's Deployments tab.

## Production guardrails

AL-Go's convention: environments named with a trailing `(PROD)` or `(FAT)` suffix are EXCLUDED from CI/CD auto-deploy. The only way to push to them is via this command. Honor that convention — never suggest renaming a Production env to bypass the gate.

Each environment can also have `DeployTo<EnvName>` settings in `.github/AL-Go-Settings.json` controlling:

- `SyncMode` — `Add` (default), `ForceSync` (data loss possible), and on the dev endpoint `Development` or `Clean` (also destructive to schema/data). Never suggest `ForceSync` or `Clean` without restating the data-loss consequence and getting explicit confirmation.
- `Scope` — `Dev` or `PTE`
- `DependencyInstallMode` — `install` / `ignore` / `upgrade` / `forceUpgrade`
- `Branches` — restrict deployment to specific branches
- `Projects` — restrict to specific projects
- `unpublishOldVersions` (v10.0, default `false`) — after a successful PTE-scope deployment, unpublish old, uninstalled versions of the deployed apps; failures are only warnings
- `ContinuousDeployment`, `BuildMode`, `includeTestAppsInSandboxEnvironment`, `excludeAppIds`, `companyId`, `ppEnvironmentUrl`, etc.

When suggesting changes to these, ground them in the env's actual current config and the user's stated intent.
