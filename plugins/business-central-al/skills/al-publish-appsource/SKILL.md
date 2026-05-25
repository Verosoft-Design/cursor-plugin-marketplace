---
name: al-publish-appsource
description: Submit a release to Microsoft AppSource via the Publish To AppSource workflow. Optionally promote the submission past Preview to public AppSource (Go Live). Use only on AL-Go-AppSource-typed repos where Partner Center has already been seeded with the product.
disable-model-invocation: true
---

# Publish to AppSource

Dispatches the `Publish To AppSource` workflow (AppSource-template repos only).

## CRITICAL: first AppSource upload is manual

The first time a product appears in Partner Center, marketing materials (icon, screenshots, descriptions, support contacts) MUST be uploaded by a human through the Partner Center UI. This workflow cannot do that. It handles every SUBSEQUENT version submission.

If the user has not yet created the product in Partner Center, surface that as a blocker and link them to the AppSource onboarding docs. Do not proceed with the workflow.

## CRITICAL: Go Live is irreversible from the agent

`GoLive=true` promotes the submission past Preview and makes it available to every BC customer immediately. The user CAN withdraw a release in Partner Center, but only with manual review. **Always require explicit user confirmation containing the word "production" or "go live" in this turn before invoking with `GoLive=true`.**

Default to `GoLive=false`. The release sits in Preview state until someone clicks Go Live in Partner Center (or runs this command again with `GoLive=true`).

## Preflight

1. Confirm cwd is an AL-Go repo of type `AppSource App` (check `.github/AL-Go-Settings.json` → `type`).
2. **Required secret: `AppSourceContext`** (JSON for Partner Center API, scope `https://api.partner.microsoft.com/.default`). Use `gh secret list` to verify. If missing, run `/al-secrets-setup`.
3. **Required setting: `deliverToAppSource.productId`** in `.AL-Go/settings.json` (the AppSource product GUID from Partner Center).
4. **Required setting: `appSourceCopMandatoryAffixes`** must be set and match what's used in the source. Otherwise AppSourceCop fails and the submission is rejected.
5. Check there is a built artifact for the version being submitted. `appVersion=current` requires a Release tag to exist (use `/al-release` first).

## Inputs

- `appVersion` — `current` / `prerelease` / `draft` / `latest` / explicit version. **For AppSource, prefer `current`** so the submission corresponds to a tagged GitHub Release.
- `projects` — `*` (all AppSource-targeting projects) or comma-separated.
- `GoLive` — `false` (default) or `true` (only with explicit user confirmation).

## Dispatch (preview only — safe default)

```bash
gh workflow run "Publish To AppSource" \
  --ref main \
  -f appVersion=current \
  -f projects=* \
  -f GoLive=false
```

## Dispatch (Go Live — ONLY after explicit user confirmation)

```bash
gh workflow run "Publish To AppSource" \
  --ref main \
  -f appVersion=current \
  -f projects=* \
  -f GoLive=true
```

## Watch the run

```bash
RUN_ID=$(gh run list --workflow "Publish To AppSource" --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

## What happens upstream

The workflow calls the AL-Go `Deliver` action with `deliveryTarget=AppSource`, `type=Release`. The Deliver action:

1. Authenticates to Partner Center via `AppSourceContext`.
2. Uploads each `.app` for the resolved version.
3. Uploads any declared dependency `.app`s (per `deliverToAppSource.includeDependencies` setting).
4. Submits the package for validation.
5. (If `GoLive=true`) flips the submission to public after Microsoft validation completes.

Microsoft validation typically takes 24–72 hours. The workflow's run completes as soon as the submission is accepted for validation — it does NOT wait for Microsoft validation to finish.

## Settings that affect this command

```json
"deliverToAppSource": {
  "productId": "<AppSource product GUID>",
  "continuousDelivery": false,
  "mainAppFolder": "MyApp",
  "includeDependencies": ["Some Publisher_*.app"]
},
"generateDependencyArtifact": true
```

- `continuousDelivery: true` — every successful CI/CD build is auto-submitted (always in Preview state until someone presses Go Live).
- `mainAppFolder` — when the repo has multiple apps but only one ships to AppSource.
- `includeDependencies` — patterns for dependency `.app`s that should be uploaded alongside the main app.

## After submission

Walk the user through:

1. Watching the Partner Center "Submissions" page for validation status.
2. Common validation failures: icon size wrong, screenshots missing, manifest mismatch with Partner Center listing.
3. When validation passes and `GoLive=false`, the submission sits in Preview. To make it public, EITHER re-run this command with `GoLive=true`, OR press Go Live manually in Partner Center.
