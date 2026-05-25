---
name: al-next-minor
description: Re-run the AL-Go build against the next minor BC version artifact via the Test Next Minor workflow. Use to surface upcoming-release compatibility breaks before BC publishes the new minor version.
---

# Test against next minor BC version

Dispatches the `Test Next Minor` workflow.

## Purpose

`Test Next Minor` rebuilds the repo against the **next minor** BC release's artifact (the upcoming patch). Uses overrides from `.github/Test Next Minor.settings.json` if present.

Run this on a schedule (weekly is typical) to catch breaking changes before they ship to customers.

## Preflight

1. Confirm cwd is an AL-Go repo.
2. Confirm `.github/Test Next Minor.settings.json` exists or matches the user's intent.

## Dispatch

```bash
gh workflow run "Test Next Minor" --ref main
```

## Watch the run

```bash
RUN_ID=$(gh run list --workflow "Test Next Minor" --limit 1 --json databaseId --jq '.[0].databaseId')
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
        "cron": "0 6 * * 1",
        "includeBranches": ["main"]
      }
    }
  }
]
```

`0 6 * * 1` = Mondays at 06:00 UTC. Adjust to taste.
