---
name: al-next-major
description: Re-run the AL-Go build against the next major BC version artifact via the Test Next Major workflow. Use to surface upcoming-major-release compatibility breaks early, typically months ahead of the actual release.
disable-model-invocation: true
---

# Test against next major BC version

Dispatches the `Test Next Major` workflow (`NextMajor.yaml`; display name ` Test Next Major` has a leading space, so dispatch by file name). No inputs (v10.0).

## Purpose

`Test Next Major` rebuilds the repo against the **next major** BC release's artifact. Major releases ship roughly twice a year (Wave 1, Wave 2) and accumulate the largest set of breaking changes.

Use this workflow during the preview window before a major BC release goes GA — it gives the user months to address upcoming breaks.

## Preflight

1. Confirm cwd is an AL-Go repo.
2. Confirm `.github/Test Next Major.settings.json` exists. The template ships it with `"artifact": "////nextmajor"`, `"cacheImageName": ""` and `"versioningStrategy": 15`; users often add preprocessor symbols for the upcoming major (e.g. `CLEAN30` when the next major is BC 30; check the actual next major version first).

## Dispatch

```bash
gh workflow run NextMajor.yaml --ref main
```

## Watch the run

```bash
RUN_ID=$(gh run list --workflow NextMajor.yaml --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

## On failure

Common patterns:

- Obsolete symbols newly marked `ObsoleteState = Removed` — switch to the replacement API.
- `CLEAN<N>` preprocessor branches — when the next major drops support for an older version, the conditional code can simplify. Use the failures as guidance for what to clean up.
- Schema changes the BC team makes between majors — usually documented in the BC release plan.

## Pair with conditional settings

To stage major-version readiness, use `conditionalSettings` so non-Test-Next-Major builds keep working while you incrementally fix things:

```json
"conditionalSettings": [
  { "workflows": ["Test Next Major"],
    "settings": { "preprocessorSymbols": ["CLEAN30"] } }
]
```

## Scheduling

Similar to `Test Next Minor`. Monthly is typical for `Test Next Major`:

```json
"workflowSchedule": { "cron": "0 6 1 * *" }
```

Put it in `.github/Test Next Major.settings.json` or in a `conditionalSettings` entry with `"workflows": ["Test Next Major"]`, then run `/al-update-system-files` so the `schedule:` trigger is written into `NextMajor.yaml`. `includeBranches` is only honored for `Update AL-Go System Files`.

## Build version numbers

The template sets `versioningStrategy: 15` for this workflow (Build = max value, Revision = this workflow's run number), so its artifacts are non-official test builds. If a user overrides it with strategy 0, Build is this workflow's run number, not CI/CD's. Either way, never compare Test Next Major artifact versions with CI/CD versions or deploy them.
