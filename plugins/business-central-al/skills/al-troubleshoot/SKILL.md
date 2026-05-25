---
name: al-troubleshoot
description: Dispatch the AL-Go Troubleshooting workflow to dump repo settings and the names of available secrets. Use as the first diagnostic step when any AL-Go workflow misbehaves, when secrets seem missing, or when the user is unsure what's configured.
disable-model-invocation: true
---

# Troubleshoot AL-Go config

Dispatches the `Troubleshooting` workflow.

## Purpose

`Troubleshooting` is the diagnostic dump for AL-Go. It writes the merged settings (post-precedence) plus, optionally, the _names_ (NOT values) of configured secrets so the user can see what's wired.

This is the right first step before suggesting any settings or secrets change — confirm what's actually in place before changing anything.

## Inputs

- `displayNameOfSecrets` (boolean, default `false`) — when `true`, dumps secret names. Recommend `true` for most diagnostic runs.

## Dispatch

```bash
gh workflow run "Troubleshooting" \
  --ref main \
  -f displayNameOfSecrets=true
```

## Watch and read the output

```bash
RUN_ID=$(gh run list --workflow "Troubleshooting" --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status

# Read the full log
gh run view $RUN_ID --log
```

The log contains:

- Merged settings object (after all 9 precedence layers).
- BcContainerHelper / .NET / PowerShell versions on the runner.
- (If `displayNameOfSecrets=true`) a list of secret names available to the workflow.
- Project enumeration result + dependency graph.

## Interpreting common findings

| Diagnostic finding                                      | Meaning                                                                                                |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `templateUrl` resolves to an old AL-Go version          | Suggest `/al-update-system-files`                                                                      |
| `country: us` but the user targets DK / DE / …          | Wrong default; set `country` in `.AL-Go/settings.json`                                                 |
| `useProjectDependencies: false` on a multi-project repo | Cross-project deps not enforced; multi-stage builds disabled                                           |
| `appSourceCopMandatoryAffixes: []` on AppSource repo    | Will fail AS0011 on first build; set the affix                                                         |
| Secret name `<EnvName>_AuthContext` missing for an env  | `/al-publish-to-environment` for that env will fail                                                    |
| No `GhTokenWorkflow` listed                             | `/al-update-system-files`, `/al-release`, and `Create a new app` family will fail. `/al-secrets-setup` |

## Privacy

`displayNameOfSecrets=true` dumps NAMES only, never values. Safe to run and share the log.

## After the dump

Summarize the findings to the user in plain English (don't dump the whole log into chat). Point at the next commands to run.
