---
name: al-increment-version
description: Bump version numbers in one or more AL-Go projects via the Increment Version Number workflow. Use to roll the repo version after a release, to coordinate a major bump across projects, or to set an explicit version string.
disable-model-invocation: true
---

# Increment version number

Dispatches the `Increment Version Number` workflow (`IncrementVersionNumber.yaml`; display name ` Increment Version Number` has a leading space, so dispatch by file name).

## Versioning formats

The `versionNumber` input (string, default empty) accepts these formats. The workflow validates it against the project's `versioningStrategy` before changing anything:

| Format   | Meaning                                                    | Allowed with                    |
| -------- | ---------------------------------------------------------- | ------------------------------- |
| `+1`     | Bump major by 1, reset minor to 0.                         | any strategy                    |
| `+0.1`   | Bump minor by 1.                                           | any strategy                    |
| `+0.0.1` | Bump build by 1.                                           | versioningStrategy 3 only       |
| `1.2`    | Set Major.Minor absolutely.                                | any strategy                    |
| `1.2.3`  | Set Major.Minor.Build absolutely.                          | versioningStrategy 3 only       |

## Preflight

1. Confirm cwd is an AL-Go repo.
2. **`GhTokenWorkflow` secret** — needed when `useGhTokenWorkflow=true` (the workflow default is `false`; this skill passes `true` so the bump PR triggers CI and can push to protected branches).
3. Decide which projects: `*` (all, the default) or a comma-separated list of project name patterns.
4. Decide whether to update dependency versions in dependent apps. Default `skipUpdatingDependencies=false` (dependent apps' `app.json` dependency entries get the new version).

## Dispatch

```bash
gh workflow run IncrementVersionNumber.yaml \
  --ref main \
  -f projects=* \
  -f versionNumber=+0.1 \
  -f skipUpdatingDependencies=false \
  -f directCommit=false \
  -f useGhTokenWorkflow=true
```

For a specific project, a major bump, and direct commit:

```bash
gh workflow run IncrementVersionNumber.yaml \
  --ref main \
  -f projects=BingMaps \
  -f versionNumber=+1 \
  -f skipUpdatingDependencies=false \
  -f directCommit=true \
  -f useGhTokenWorkflow=true
```

## Watch the run

```bash
RUN_ID=$(gh run list --workflow IncrementVersionNumber.yaml --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId')
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

| Value         | Behavior                                                                                                                         |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| `0` (default) | Major.Minor from `app.json`; Build = run number of the current workflow (+ `runNumberOffset`); Revision = run attempt − 1      |
| `2`           | Build = UTC date `yyyyMMdd`, Revision = UTC time `hhmmss`                                                                       |
| `3`           | Major.Minor.Build from `app.json`; Revision = run number                                                                        |
| `15`          | Build = max value, Revision = run number (non-official builds only; the Test Current/Next workflows use it)                    |
| `+16` (added) | Use the `repoVersion` setting instead of Major.Minor from `app.json` (and Build too with 3+16 = 19)                            |

`runNumberOffset` applies to strategies 0, 3 and 15. The run number is that of the workflow doing the build, so builds from Test Next Major etc. do not share CI/CD's numbering.

`/al-increment-version` updates the source-of-truth Major.Minor (via `repoVersion`); the strategy determines how Build is composed downstream.
