---
name: al-next-major
description: Re-run the AL-Go build against the next major BC version artifact via the Test Next Major workflow. Use to surface upcoming-major-release compatibility breaks early, typically months ahead of the actual release.
disable-model-invocation: true
---

# Test against next major BC version

Dispatches the `Test Next Major` workflow.

## Purpose

`Test Next Major` rebuilds the repo against the **next major** BC release's artifact. Major releases ship roughly twice a year (Wave 1, Wave 2) and accumulate the largest set of breaking changes.

Use this workflow during the preview window before a major BC release goes GA — it gives the user months to address upcoming breaks.

## Preflight

1. Confirm cwd is an AL-Go repo.
2. Confirm `.github/Test Next Major.settings.json` exists. This file typically declares preprocessor symbols for the upcoming major (e.g. `CLEAN26` when targeting BC 26).

## Dispatch

```bash
gh workflow run "Test Next Major" --ref main
```

## Watch the run

```bash
RUN_ID=$(gh run list --workflow "Test Next Major" --limit 1 --json databaseId --jq '.[0].databaseId')
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
    "settings": { "preprocessorSymbols": ["CLEAN26"] } }
]
```

## Scheduling

Similar to `Test Next Minor`. Monthly is typical for `Test Next Major`:

```json
"workflowSchedule": { "cron": "0 6 1 * *", "includeBranches": ["main"] }
```
