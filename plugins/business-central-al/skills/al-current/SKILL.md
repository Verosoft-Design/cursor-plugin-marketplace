---
name: al-current
description: Re-run the AL-Go build against the current BC version artifact via the Test Current workflow. Use to verify the app still builds and passes tests against the currently shipped BC version, independent of the default artifact pinned in settings.
disable-model-invocation: true
---

# Test against current BC version

Dispatches the `Test Current` workflow.

## Purpose

`Test Current` rebuilds every project in the repo against the **currently shipped** BC version (latest stable). It uses overrides from `.github/Test Current.settings.json` if present, otherwise the repo's standard settings.

The three test-\* workflows together (`Test Current`, `Test Next Minor`, `Test Next Major`) let the user verify their app stays compatible as BC evolves.

## Preflight

1. Confirm cwd is an AL-Go repo.
2. Confirm `.github/Test Current.settings.json` exists or matches the user's intent. If absent, the workflow uses standard settings.

## Dispatch

```bash
gh workflow run "Test Current" --ref main
```

No inputs.

## Watch the run

```bash
RUN_ID=$(gh run list --workflow "Test Current" --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

## On failure

Surface the first ~50 lines of the failure log:

```bash
gh run view $RUN_ID --log-failed | head -50
```

Common failures:

- Compiler error on a newer compiler — the code uses a pattern that has been tightened or deprecated. Fix in source.
- Symbol-not-found — a referenced platform symbol moved or was renamed. Search BCApps / Microsoft Learn for the new API.
- Test failure — the BC platform changed behavior the test asserts. Either update the test or file a BC issue.

## Related

- `/al-next-minor` — same workflow shape, against next minor BC release.
- `/al-next-major` — same against next major BC release.

Running all three on a schedule gives the user early warning of upcoming compatibility breaks.
