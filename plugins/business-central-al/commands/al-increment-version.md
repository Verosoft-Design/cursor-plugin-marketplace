---
name: al-increment-version
description: Bump version numbers in one or more AL-Go projects via the Increment Version Number workflow. Use to roll the repo version after a release, to coordinate a major bump across projects, or to set an explicit version string.
---

# Increment version number

Dispatches the `Increment Version Number` workflow.

## Versioning formats

The `versionNumber` input accepts three formats:

| Format   | Meaning                                                    |
| -------- | ---------------------------------------------------------- |
| `+1`     | Bump major by 1, reset minor and build to 0.               |
| `+0.1`   | Bump minor by 1, reset build to 0.                         |
| `+0.0.1` | Bump build by 1.                                           |
| `1.2.3`  | Set the version to exactly `1.2.3`.                        |
| `1.2`    | Set major.minor; build determined by `versioningStrategy`. |

## Preflight

1. Confirm cwd is an AL-Go repo.
2. **Required secret: `GhTokenWorkflow`** (this workflow opens a PR or commits directly to bump versions).
3. Decide which projects: `*` (all) or a comma-separated list of project paths.
4. Decide whether to update dependency versions in dependent apps. Default `skipUpdatingDependencies=false` (dependent apps' `app.json` dependency entries get the new version).

## Dispatch

```bash
gh workflow run "Increment Version Number" \
  --ref main \
  -f projects=* \
  -f versionNumber=+0.1 \
  -f skipUpdatingDependencies=false \
  -f directCommit=false \
  -f useGhTokenWorkflow=true
```

For a specific project, a major bump, and direct commit:

```bash
gh workflow run "Increment Version Number" \
  --ref main \
  -f projects=BingMaps \
  -f versionNumber=+1 \
  -f skipUpdatingDependencies=false \
  -f directCommit=true \
  -f useGhTokenWorkflow=true
```

## Watch the run

```bash
RUN_ID=$(gh run list --workflow "Increment Version Number" --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

## What changes

The PR (or commit) modifies:

- `app.json` `version` in each affected app folder.
- `repoVersion` in `.AL-Go/settings.json` for each affected project (when bumping major or minor).
- Dependent apps' `app.json` `dependencies[].version` entries (when `skipUpdatingDependencies=false`).

## Relationship with `Create release`

`/al-release` runs `Create release` which (when `updateVersionNumber` is set) automatically opens an Increment Version Number PR for the NEXT release. So `/al-increment-version` is rarely needed manually after a release — the release workflow chains it. Reach for it directly for:

- A major bump that the release workflow didn't trigger.
- Setting an explicit non-incremental version.
- Bumping a single project independently of the rest.

## Versioning strategy

The `versioningStrategy` setting in `.AL-Go/settings.json` controls how the version is composed at build time:

| Value         | Behavior                                                                 |
| ------------- | ------------------------------------------------------------------------ |
| `0` (default) | `Major.Minor.Build.<github.run_number>`                                  |
| `2`           | Date/time-based                                                          |
| `3`           | `app.json` version + `<github.run_number>`                               |
| `15`          | Max version across repo + `<github.run_number>`                          |
| `+16` (added) | Use `repoVersion` for Major.Minor (e.g. `15+16=31` for date+repoVersion) |

`/al-increment-version` updates the source-of-truth Major.Minor (via `repoVersion`); the strategy determines how Build is composed downstream.
