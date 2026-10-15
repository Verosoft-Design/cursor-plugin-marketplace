---
name: al-next-minor
description: Re-run the AL-Go build against the next minor BC version artifact via the Test Next Minor workflow. Use to surface upcoming-release compatibility breaks before BC publishes the new minor version.
disable-model-invocation: true
---

# Test against next minor BC version

Dispatches the `Test Next Minor` workflow (`NextMinor.yaml`; display name ` Test Next Minor` has a leading space, so dispatch by file name). No inputs (v10.0).

## Purpose

`Test Next Minor` rebuilds the repo against the **next minor** BC release's artifact (the upcoming patch). The artifact comes from `.github/Test Next Minor.settings.json`, which the template ships with `"artifact": "////nextminor"`, `"cacheImageName": ""` and `"versioningStrategy": 15`.

Run this on a schedule (weekly is typical) to catch breaking changes before they ship to customers.

## Preflight

1. Confirm cwd is an AL-Go repo.
2. Confirm `.github/Test Next Minor.settings.json` exists and its `artifact` is `////nextminor` (or what the user intends). Without it the run just rebuilds against the normal artifact.

## Dispatch

```bash
gh workflow run NextMinor.yaml --ref main
```

## Watch the run

```bash
RUN_ID=$(gh run list --workflow NextMinor.yaml --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

## On failure

`Test Next Minor` failures are the most actionable of the three — the upcoming version is close enough that fixing now avoids a customer-visible regression. Investigate the same way as `/al-current` failures.

## Scheduling

To run automatically, add to `.github/AL-Go-Settings.json` or `.AL-Go/settings.json`:

```json
"conditionalSettings": [
  {
    "workflows": ["Test Next Minor"],
    "settings": {
      "workflowSchedule": {
        "cron": "0 6 * * 1"
      }
    }
  }
]
```

`0 6 * * 1` = Mondays at 06:00 UTC. Adjust to taste. Alternatively put `"workflowSchedule": { "cron": "0 6 * * 1" }` directly in `.github/Test Next Minor.settings.json`.

- The schedule only takes effect after the next `/al-update-system-files` run (AL-Go writes the `schedule:` trigger into `NextMinor.yaml`).
- Do not add `includeBranches` here: only `Update AL-Go System Files` supports running on multiple branches.
- Since v9.1, `conditionalSettings` also accepts a `triggers` condition (e.g. `"triggers": ["schedule"]`) if some settings should apply only to scheduled runs.
