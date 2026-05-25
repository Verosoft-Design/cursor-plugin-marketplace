---
name: al-release
description: Cut a GitHub release via the Create release workflow. Tags HEAD, builds release notes from commits, publishes the release with .app artifacts and source, and opens an Increment Version Number PR for the next dev cycle. Use when a build is ready to become an officially-named release.
---

# Create a release

Dispatches the `Create release` workflow.

## What it does

1. Resolves which build to release (per `buildVersion` input).
2. Tags HEAD with the given tag.
3. Builds Markdown release notes from commit history since the last release.
4. Publishes a GitHub Release (or Pre-release / Draft) with all built `.app` artifacts + source code zip attached.
5. Optionally opens an Increment Version Number PR for the next dev cycle.

Subsequent CI/CD runs use the prior release as the upgrade baseline for tests (catches breaking upgrades automatically).

## Preflight

1. Confirm cwd is an AL-Go repo.
2. **Required secret: `GhTokenWorkflow`** when `useGhTokenWorkflow=true` (almost always).
3. Confirm the user knows which build they're releasing. `buildVersion=latest` releases the latest successful CI/CD build, which may include unmerged-to-main feature work if the repo allows builds on non-main branches. For predictable releases, pin to a specific version.
4. Decide release type:
   - `Release` (default) — public stable release.
   - `Prerelease` — published but marked pre-release; subsequent CI uses the previous _stable_ release as upgrade baseline.
   - `Draft` — created but not published; visible only to maintainers.
5. Decide tag and name. Tag MUST be valid semver (e.g. `1.0.0`, `2.3.4-rc.1`). Name is display-only (e.g. `v1.0`, `Spring 2026`).
6. Decide post-release version bump. `+0.1` is the typical default (rolls minor for next dev cycle).

## Dispatch

```bash
gh workflow run "Create release" \
  --ref main \
  -f buildVersion=latest \
  -f name=v1.0 \
  -f tag=1.0.0 \
  -f releaseType=Release \
  -f createReleaseBranch=false \
  -f directCommit=false \
  -f useGhTokenWorkflow=true \
  -f updateVersionNumber=+0.1
```

For a draft release of a specific PR build:

```bash
gh workflow run "Create release" \
  --ref main \
  -f buildVersion=PR_42 \
  -f name="RC1 from PR 42" \
  -f tag=1.0.0-rc.1 \
  -f releaseType=Prerelease \
  -f useGhTokenWorkflow=true
```

## Watch the run

```bash
RUN_ID=$(gh run list --workflow "Create release" --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

## After success

- The release is visible at `gh release view <tag>`.
- `.app` files are attached as release assets and reachable via `gh release download <tag>`.
- The Increment Version Number PR is open (when `updateVersionNumber` is set). Walk the user through reviewing and merging it.

## Release branches

When `createReleaseBranch=true`, AL-Go creates a `releases/<tag>` branch from the tagged commit so the user can patch the release without disturbing main. Useful for AppSource apps where hotfix versions get back-ported.

## Onward steps

For AppSource apps, the natural next step is `/al-publish-appsource` to ship the new release to AppSource.

For PTE apps, the natural next step is `/al-publish-to-environment` with `appVersion=current` to roll out the release to managed customer environments.

For internal apps, the release is the final step.

## Failure modes

- Tag already exists — pick a new tag or delete the existing one (`gh release delete <tag>`).
- "No artifacts to release" — `buildVersion` does not resolve to any built artifact. Run a CI/CD build first or pick a valid version.
- Signing error — codesign secrets are missing or expired. `/al-init-keyvault` (new KV path) or update the legacy `CodeSignCertificateUrl`/`Password` secrets.
