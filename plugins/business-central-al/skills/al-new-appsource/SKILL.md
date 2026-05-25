---
name: al-new-appsource
description: Scaffold a new AL-Go for GitHub repository for an AppSource app, then create the first app inside it via the Create a new app workflow. Use when the user wants a brand-new BC AppSource project ready for CI/CD plus eventual AppSource delivery.
disable-model-invocation: true
---

# Create a new AppSource repository

Same shape as `/al-new-pte` but uses the `microsoft/AL-Go-AppSource` template, which presets `type=AppSource App` and pre-populates `appSourceCopMandatoryAffixes`.

## Step 1 — Confirm intent and gather inputs

Confirm with the user:

- New repo owner + name
- Visibility (`--public` or `--private`)
- App name and publisher
- ID range (the user MUST own this; AppSource apps need ranges in the partner-assigned space)
- **Mandatory affix** — the prefix every object name in the AppSource app must carry (e.g. `"TAG "`). This will be wired into `.AL-Go/settings.json` → `appSourceCopMandatoryAffixes`. The template seeds an empty list; the user MUST replace it with their own affix before the first build will pass AppSourceCop.
- Whether they have a Partner Center account ready (required eventually for `/al-publish-appsource`)
- Sample code (`sampleCode=true` default)

## Step 2 — Create the repo

```bash
gh repo create <owner>/<repo-name> \
  --template microsoft/AL-Go-AppSource \
  --<public|private> \
  --description "<short description>"
```

## Step 3 — Dispatch Create a new app

```bash
gh workflow run "Create a new app" \
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

The workflow runs `CreateApp` with `type=AppSource App` because the repo type is preset.

## Step 4 — Wire the mandatory affix

The newly-scaffolded `.AL-Go/settings.json` will contain:

```json
"appSourceCopMandatoryAffixes": ["<affix>"]
```

Walk the user through editing it to their actual affix (typically `"TAG "` for Verosoft, with a trailing space). Without this, every AppSourceCop run will fail on rule AS0011.

## Step 5 — Watch the run

```bash
RUN_ID=$(gh run list --repo <owner>/<repo-name> --workflow "Create a new app" --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --repo <owner>/<repo-name> --exit-status
```

## Onward steps

After the workflow merges:

1. Clone locally, develop.
2. When ready to deliver to AppSource for the first time, the user MUST manually upload marketing materials in Partner Center. This is not automatable. After the first manual submission, future versions can ship via `/al-publish-appsource`.
3. Wire the `AppSourceContext` secret (`/al-secrets-setup`).
4. Wire signing — either the legacy `CodeSignCertificateUrl`+`CodeSignCertificatePassword` secrets OR the new KV-based path via `keyVaultCodesignCertificateName` (`/al-init-keyvault`).
