---
name: al-add-bcpt-app
description: Add a new AL performance test app (Business Central Performance Toolkit) to an existing AL-Go repository via the Create a new performance test app workflow. Use when the user wants BCPT-based performance regression testing in CI.
disable-model-invocation: true
---

# Add a performance test (BCPT) app

Dispatches the `Create a new performance test app` workflow (`CreatePerformanceTestApp.yaml`) in the current AL-Go repository.

## What is a BCPT app

A BCPT app is a special test app that depends on the `Performance Toolkit` (codeunit 149003 `BCPT Test Context`). BCPT tests call `BCPTTestContext.StartScenario('name')` / `EndScenario('name')` around the code being measured. CI compares the measurements against a checked-in `bcptBaseLine.json` and fails the build when thresholds are exceeded.

## Step 1 — Preflight

1. Confirm cwd is an AL-Go repo.
2. Gather inputs:
   - `project` (relative path; default `.`)
   - `name` (required; the workflow's placeholder default is `<YourAppName>.PerformanceTest`, so pass a real name such as `<MainApp>.PerformanceTest`)
   - `publisher`
   - `idrange` (required; workflow default `50000..99999`; use the user's allocated range, e.g. `70015000..70016999`)
   - `sampleCode` (boolean, default `true`)
   - `sampleSuite` (boolean, default `true`) — adds a sample BCPT scenario
3. Decide direct commit vs PR (default PR) and whether to use `GhTokenWorkflow` (`useGhTokenWorkflow`, default `false` in the workflow; this skill passes `true` so the PR triggers CI).

## Step 2 — Dispatch

```bash
gh workflow run CreatePerformanceTestApp.yaml \
  --ref main \
  -f project=<project> \
  -f name=<name> \
  -f publisher=<publisher> \
  -f idrange=<from>..<to> \
  -f sampleCode=true \
  -f sampleSuite=true \
  -f directCommit=false \
  -f useGhTokenWorkflow=true
```

These are exactly the v10.0 inputs of `CreatePerformanceTestApp.yaml`. Creating a BCPT app on Linux runners works since v9.1 (earlier versions failed on a case-sensitive path).

## Step 3 — Watch + merge

```bash
RUN_ID=$(gh run list --workflow CreatePerformanceTestApp.yaml --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

## Step 4 — Wire baseline + thresholds

After the PR merges, the user should:

1. Run the test once locally (or in CI) to produce an initial `bcptBaseLine.json`.
2. Commit `bcptBaseLine.json` at the project root so CI has something to compare against.
3. Optionally set `bcptThresholds` in `.AL-Go/settings.json` to tighten the default warning/error gates. Defaults are:
   - `DurationWarning: 10` (% over baseline)
   - `DurationError: 25`
   - `NumberOfSqlStmtsWarning: 5`
   - `NumberOfSqlStmtsError: 10`

## CI behavior

BCPT runs as part of CI/CD. Failures show up as build-status failures with a per-scenario diff against baseline.
