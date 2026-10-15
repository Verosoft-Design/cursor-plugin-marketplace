---
name: al-deploy-docs
description: Build and publish the aldoc reference documentation site to GitHub Pages via the Deploy Reference Documentation workflow. Use to generate and ship a static documentation site for the project's AL objects, procedures, and integration events.
disable-model-invocation: true
---

# Deploy reference documentation

Dispatches the `Deploy Reference Documentation` workflow (`DeployReferenceDocumentation.yaml`; display name ` Deploy Reference Documentation` has a leading space, so dispatch by file name).

## What it does

Runs Microsoft's `aldoc` tool to generate a static HTML reference site from the project's AL source (objects, public procedures, integration events, XML doc comments) and deploys it to GitHub Pages.

The site documents:

- Every public codeunit / table / page / report / query / enum / interface.
- Every public procedure with its XML doc summary, parameters, returns, remarks.
- Every integration event with subscription patterns.
- Inter-app dependencies (when multiple apps in the repo).

## Preflight

1. Confirm cwd is an AL-Go repo.
2. Confirm GitHub Pages is enabled for the repo (Settings → Pages → Source: GitHub Actions).
3. Confirm the `alDoc` settings in `.github/AL-Go-Settings.json` match the user's intent. Optional but useful:

```json
"alDoc": {
  "continuousDeployment": false,
  "deployToGitHubPages": true,
  "maxReleases": 3,
  "groupByProject": true,
  "includeProjects": [],
  "excludeProjects": [],
  "header": "<custom header HTML>",
  "footer": "<custom footer HTML>",
  "defaultIndexMD": "<path to MD>",
  "defaultReleaseMD": "<path to MD>"
}
```

## Dispatch

```bash
gh workflow run DeployReferenceDocumentation.yaml --ref main
```

No inputs (v10.0).

## Watch the run

```bash
RUN_ID=$(gh run list --workflow DeployReferenceDocumentation.yaml --event workflow_dispatch --limit 1 --json databaseId --jq '.[0].databaseId')
gh run watch $RUN_ID --exit-status
```

## After success

The site is published at `https://<owner>.github.io/<repo>/`. The workflow logs the exact URL.

## Continuous publishing

To auto-publish on every CI/CD run, set `alDoc.continuousDeployment: true`. The aldoc artifact then gets generated as part of CI/CD and deployed to Pages after a successful main build. Recommended for projects whose API surface changes frequently.

## Multiple releases

`alDoc.maxReleases` (default 3) controls how many historical versions of the docs are kept available. Useful for documenting BC-version-specific behavior.

## XML doc quality matters

aldoc only documents procedures that have XML doc comments. Phase 3's `al-xmldoc-public-procedures.mdc` rule and Phase 5's `al-docs` skill help maintain this documentation. Without XML docs, the resulting site is sparse and not useful — flag this to the user if their public surface is undocumented.

## Failure modes

- "GitHub Pages is not enabled" — enable it in repo settings (Source: GitHub Actions).
- "No releases found" — the workflow needs at least one published release to generate the `maxReleases` archive. Run `/al-release` first.
- aldoc tool errors — usually malformed XML doc comments in the source. The log points at the offending file.
- `InvalidTocInclude: Referenced TOC file ... does not exist` for apps with `_` in the name, or aldoc not using the package cache — fixed in v9.2; run `/al-update-system-files` if the repo is older.
- "Could not find AL tool" with a custom `vsixFile` — v9.2 also resolves aldoc/altool from the flat `compiler/extension/bin` layout; update AL-Go if the repo is older.
