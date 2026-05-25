---
name: al-add-test-app
description: Add a new AL test app to an existing AL-Go repository via the Create a new test app workflow. Use when the user wants to introduce automated tests to a BC app that does not yet have a test project.
disable-model-invocation: true
---

# Add a test app

Dispatches the `Create a new test app` workflow in the current AL-Go repository.

## Step 1 — Preflight

1. Confirm the cwd is inside an AL-Go repo (`.github/AL-Go-Settings.json` exists).
2. Gather inputs from the user:
   - `project` — relative path to the project folder (default `.` for single-project repos)
   - `name` — test app name (default `<MainApp>.Test`)
   - `publisher` — same publisher as the main app
   - `idrange` — defaults to `50000..99999`; in TAG-style projects use the user's allocated range
   - Whether to commit directly or open a PR (default PR)
3. If `directCommit=false` (PR mode), check that the org allows GitHub Actions to create/approve PRs (Settings → Actions → General → Allow GitHub Actions to create and approve pull requests). If unsure, mention it as a gotcha.

## Step 2 — Dispatch

```bash
gh workflow run "Create a new test app" \
  --ref main \
  -f project=<project> \
  -f name=<name> \
  -f publisher=<publisher> \
  -f idrange=<from>..<to> \
  -f sampleCode=true \
  -f directCommit=false \
  -f useGhTokenWorkflow=true
```

`useGhTokenWorkflow=true` requires the `GhTokenWorkflow` secret. Run `/al-secrets-setup` if it is missing.

## Step 3 — Watch the run

```bash
RUN_ID=$(gh run list --workflow "Create a new test app" --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

## Step 4 — Review and merge the PR

If a PR was opened, walk the user through reviewing it. The scaffolded test app folder typically contains:

- `app.json` with dependencies on `Test Framework`, `Library Assert` (codeunit 130002), `Any`, `Library Variable Storage`, and the main app under test.
- A starter test codeunit with `Subtype = Test`.

After merge, the next CI/CD build will compile and run the tests.

## Phase 3 follow-up

After Phase 3 ships, the agent should also offer to run `/al-apply-rulesets` so the new test app inherits the canonical Microsoft analyzer rulesets, and to enable `enableCodeAnalyzersOnTestApps: true` so analyzers run on test code too.
