---
name: al-release
description: Cut a GitHub release via the Create release workflow. Tags HEAD, builds release notes from commits, publishes the release with .app artifacts and source, and opens an Increment Version Number PR for the next dev cycle. Use when a build is ready to become an officially-named release.
disable-model-invocation: true
---

# Create a release

Dispatches the `Create release` workflow (`CreateRelease.yaml`; display name ` Create release` has a leading space, so dispatch by file name). Only one run can execute at a time (`concurrency: group: ${{ github.workflow }}`).

## What it does

1. Validates `updateVersionNumber` against `versioningStrategy`.
2. Resolves which CI/CD build to release (per `buildVersion`) and tags that build's commit.
3. Builds Markdown release notes since the last release.
4. Publishes a GitHub Release (or Pre-release / Draft) with the built `.app` artifacts (Apps, TestApps, Dependencies) attached, and delivers to NuGet / Storage if those contexts exist.
5. Optionally creates a release branch and bumps the version number on the dispatched branch (PR or direct commit).
6. **v10.0:** in a separate, parallel `CheckForUpdates` job, reports whether newer AL-Go system files are available. It only reports; apply updates with `/al-update-system-files`. A failure there does not block the release.

Subsequent CI/CD runs use the prior release as the upgrade baseline for tests (catches breaking upgrades automatically).

## Preflight

1. Confirm cwd is an AL-Go repo.
2. **Required secret: `GhTokenWorkflow`** when `useGhTokenWorkflow=true` (almost always).
3. Confirm the user knows which build they're releasing. `buildVersion=latest` releases the latest successful CI/CD build **of the branch passed in `--ref`**; any other value must be the build version of an existing CI/CD artifact on that branch (e.g. `1.0.42.0`). Pull request builds (`PR_<id>`) are not accepted by this workflow. If the branch has moved since that build and `useGhTokenWorkflow=false`, the workflow fails (GitHub only lets `GITHUB_TOKEN` create a release on the branch head); with `useGhTokenWorkflow=true` it can release an older build. For predictable releases, pin to a specific version.
4. Decide release type:
   - `Release` (default) — public stable release.
   - `Prerelease` — published but marked pre-release; subsequent CI uses the previous _stable_ release as upgrade baseline.
   - `Draft` — created but not published; visible only to maintainers.
5. Decide tag and name (both required). Tag MUST be valid semver (e.g. `1.0.0`, `2.3.4-rc.1`). Name is display-only (e.g. `v1.0`, `Spring 2026`).
6. Decide post-release version bump (`updateVersionNumber`, default empty = no bump). `+0.1` is the typical choice; `+1` for a major; `Major.Minor` absolute. `+0.0.1` and `Major.Minor.Build` are only valid with versioningStrategy 3. `skipUpdatingDependencies` (default `false`) skips updating dependency versions in other apps.
7. Decide whether to create a release branch (`createReleaseBranch`, default `false`) and its prefix (`releaseBranchPrefix`, default `release/`).

## Dispatch

```bash
gh workflow run CreateRelease.yaml \
  --ref main \
  -f buildVersion=latest \
  -f name=v1.0 \
  -f tag=1.0.0 \
  -f releaseType=Release \
  -f createReleaseBranch=false \
  -f updateVersionNumber=+0.1 \
  -f skipUpdatingDependencies=false \
  -f directCommit=false \
  -f useGhTokenWorkflow=true
```

For a prerelease of a specific CI/CD build, with a release branch:

```bash
gh workflow run CreateRelease.yaml \
  --ref main \
  -f buildVersion=1.0.42.0 \
  -f name="1.0 RC1" \
  -f tag=1.0.0-rc.1 \
  -f releaseType=Prerelease \
  -f createReleaseBranch=true \
  -f releaseBranchPrefix=release/ \
  -f useGhTokenWorkflow=true
```

All input names above are the v10.0 `CreateRelease.yaml` inputs: `buildVersion`, `name`, `tag`, `releaseType` (`Release` / `Prerelease` / `Draft`), `createReleaseBranch`, `releaseBranchPrefix`, `updateVersionNumber`, `skipUpdatingDependencies`, `directCommit`, `useGhTokenWorkflow`. To release a PR build into an environment instead, use `/al-publish-to-environment` with `appVersion=PR_<id>`.

## Watch the run

```bash
RUN_ID=$(gh run list --workflow CreateRelease.yaml --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

## After success

- The release is visible at `gh release view <tag>`.
- `.app` files are attached as release assets and reachable via `gh release download <tag>`.
- The Increment Version Number PR is open (when `updateVersionNumber` is set). Walk the user through reviewing and merging it.

## Release branches

When `createReleaseBranch=true`, AL-Go creates `<releaseBranchPrefix><version>` from the released commit, where the version comes from the tag: tag `1.0.0` gives `release/1.0`, tag `1.0.1` gives `release/1.0.1` (default prefix `release/`). The user can then patch the release without disturbing main. Useful for AppSource apps where hotfix versions get back-ported. `release/*` branches are already in the default CI/CD push branches.

## Onward steps

For AppSource apps, the natural next step is `/al-publish-appsource` to ship the new release to AppSource.

For PTE apps, the natural next step is `/al-publish-to-environment` with `appVersion=current` to roll out the release to managed customer environments.

For internal apps, the release is the final step.

## Failure modes

- Tag already exists — pick a new tag or delete the existing one (`gh release delete <tag>`).
- "No artifacts found for this project" — `buildVersion` does not resolve to a CI/CD artifact on the dispatched branch (wrong version, wrong `--ref`, a `PR_<id>` value, or the artifact has expired under the repo's artifact retention). Run a CI/CD build first or pick a valid version.
- "The <branch> branch has changed since the last successful build" / "attempting to create a release from a build that isn't the most recent one" — run with `useGhTokenWorkflow=true` (needs `GhTokenWorkflow`) or run CI/CD again first.
- Signing error — codesign secrets are missing or expired. `/al-init-keyvault` (new KV path) or update the legacy `CodeSignCertificateUrl`/`Password` secrets.
