---
name: al-new-pte
description: Scaffold a new AL-Go for GitHub repository for a Per Tenant Extension (PTE), then create the first app inside it via the Create a new app workflow. Use when the user wants a brand-new BC PTE project ready for CI/CD.
disable-model-invocation: true
---

# Create a new PTE repository

Wraps two operations:

1. `gh repo create` from the `microsoft/AL-Go-PTE` template.
2. Dispatch the `Create a new app` workflow (`CreateApp.yaml`) against the new repo.

## Step 1 — Confirm intent and gather inputs

Before doing anything, confirm with the user:

- New repo owner + name (e.g. `verosoft/tag-new-feature-pte`)
- Visibility (`--public` or `--private`)
- App name (will become the `name` input to `Create a new app`)
- Publisher (e.g. `Verosoft Design INC.`)
- ID range (e.g. `70015000..70016999`) — the user MUST own this range; do NOT guess one
- Whether to seed the sample `HelloWorld.al` (`sampleCode=true`) — default yes

## Step 2 — Create the repo

```bash
gh repo create <owner>/<repo-name> \
  --template microsoft/AL-Go-PTE \
  --<public|private> \
  --description "<short description>"
```

Verify with `gh repo view <owner>/<repo-name>`.

Note: the template's `.github/AL-Go-Settings.json` sets `templateUrl` to `https://github.com/microsoft/AL-Go-PTE@main`, which tracks the latest AL-Go release (v10.0 at the time of writing). The user can pin to a release branch later (e.g. `https://github.com/microsoft/AL-Go-PTE@v10.0`) or opt into `@preview`.

## Step 3 — Dispatch Create a new app

All inputs below exist in v10.0 `CreateApp.yaml` (`name`, `publisher`, `idrange` are required; `project` defaults to `.`, `sampleCode` to `true`, `directCommit` and `useGhTokenWorkflow` to `false`). The display name has no leading space, but dispatching by file name is the safe habit.

```bash
gh workflow run CreateApp.yaml \
  --repo <owner>/<repo-name> \
  --ref main \
  -f project=. \
  -f name=<app name> \
  -f publisher=<publisher> \
  -f idrange=<from>..<to> \
  -f sampleCode=true \
  -f directCommit=true \
  -f useGhTokenWorkflow=false
```

If the repo's default branch is protected against direct commits, set `directCommit=false` (the workflow opens a PR) and `useGhTokenWorkflow=true` (requires `GhTokenWorkflow` secret — run `/al-secrets-setup` first if missing).

## Step 4 — Watch the run

```bash
RUN_ID=$(gh run list --repo <owner>/<repo-name> --workflow CreateApp.yaml --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --repo <owner>/<repo-name> --exit-status
```

## Step 5 — Local clone for development

After success:

```bash
gh repo clone <owner>/<repo-name>
cd <repo-name>
code .
```

Then walk the user through running `.AL-Go/localDevEnv.ps1` (Docker container) or `/al-create-online-dev-env` (online sandbox) to start coding.

## Failure modes

- `template parameter must be a public template` — the user is on a GitHub plan that does not support template repos. Suggest forking `microsoft/AL-Go-PTE` instead.
- `Resource not accessible by integration` on the workflow dispatch — token is missing workflow permissions. Re-authenticate `gh` with `gh auth refresh -s workflow`.
- `could not find any workflows named ...` / HTTP 404 right after `gh repo create` — GitHub has not indexed the template's workflows yet, or Actions is disabled on the new repo. Wait a few seconds, check `gh workflow list --repo <owner>/<repo-name>`, and enable Actions if needed.
- `idrange` parse error — the format is two integers separated by `..` (no spaces).
