---
name: al-update-system-files
description: Dispatch the Update AL-Go System Files workflow to refresh AL-Go scripts and workflows from the template repo. Use when the user wants to pick up new AL-Go features, fixes, or to silence the "newer system files available" warning in CI/CD output.
---

# Update AL-Go system files

Dispatches the `Update AL-Go System Files` workflow, which syncs AL-Go scripts and workflow YAMLs from the template repository.

## Preflight

1. Confirm cwd is an AL-Go repo.
2. **Required secret: `GhTokenWorkflow`.** This workflow modifies other workflow files, which requires elevated permissions that `GITHUB_TOKEN` doesn't have. Use `gh secret list` to verify. If missing, run `/al-secrets-setup` first — it walks through the GitHub App (recommended) or PAT setup.
3. Check the current `templateUrl` in `.github/AL-Go-Settings.json` to see what version is being tracked. Common values:
   - `https://github.com/microsoft/AL-Go-PTE@main` — track main (recommended for most)
   - `https://github.com/microsoft/AL-Go-PTE@preview` — track preview branch (for early adopters)
   - `https://github.com/microsoft/AL-Go-PTE@v9.0` — pin to a specific tag

## Inputs

- `templateUrl` (string, optional) — override the configured `templateUrl` for this run (e.g. to test against a fork).
- `downloadLatest` (boolean, default `true`).
- `directCommit` (boolean, default `false`) — `false` opens a PR (recommended so the user can review the diff).
- `includeBranches` (comma list, optional) — pattern of branches to also update (defaults to just the current branch).
- `useGhTokenWorkflow` (boolean) — `true` to use the `GhTokenWorkflow` secret.

## Dispatch

```bash
gh workflow run "Update AL-Go System Files" \
  --ref main \
  -f downloadLatest=true \
  -f directCommit=false \
  -f useGhTokenWorkflow=true
```

For a one-off run against a specific template version:

```bash
gh workflow run "Update AL-Go System Files" \
  --ref main \
  -f templateUrl=https://github.com/microsoft/AL-Go-PTE@v9.1 \
  -f downloadLatest=true \
  -f directCommit=false \
  -f useGhTokenWorkflow=true
```

## Watch the run

```bash
RUN_ID=$(gh run list --workflow "Update AL-Go System Files" --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

## Review the PR

The PR diff shows every changed AL-Go script and workflow YAML. Walk the user through it carefully:

- Workflow YAML changes are usually safe; AL-Go's contract is that the dispatch shape and inputs are preserved across minor/patch.
- Action ref bumps (e.g. `microsoft/AL-Go-Actions@v9.0` → `@v9.1`) signal the AL-Go version moving forward — this is the SHA AL-Go pin you should reference everywhere else.
- Custom workflows prefixed `my*` / `our*` / `<org>*` are preserved (not touched by the update).
- Files listed in `customALGoFiles.filesToExclude` are not synced.

If the user has custom scripts in `.AL-Go/` (script overrides like `NewBcContainer.ps1`), those are NEVER overwritten by this workflow.

## Failure modes

- `Resource not accessible by integration` — `GhTokenWorkflow` is missing or lacks Workflows scope. `/al-secrets-setup`.
- "No updates available" — the repo is already on the latest template version. Not an error.
- Merge conflict in the resulting PR — happens when the user has manually edited AL-Go system files. Resolve by hand or by moving the customizations into a custom template repo.

## Scheduling

A scheduled run keeps system files fresh without manual intervention:

```json
"conditionalSettings": [
  { "workflows": ["Update AL-Go System Files"],
    "settings": {
      "workflowSchedule": {
        "cron": "0 6 * * 1",
        "includeBranches": ["main"]
      }
    }
  }
]
```

When scheduled, AL-Go defaults to `directCommit=true` (otherwise the PR sits unmerged). Add `updateALGoSystemFilesEnvironment: "<env name>"` to gate the secret access through a GitHub Environment approval rule if direct-commit-from-schedule feels too aggressive.
