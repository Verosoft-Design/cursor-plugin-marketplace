---
name: al-go-live
description: Compound lifecycle command that takes a feature from local build to AppSource release. Walks through al-build → al-publish-sandbox → smoke tests → al-release → al-publish-appsource. Use when the user wants the full end-to-end "ship it" flow with explicit confirmation gates at each destructive step.
disable-model-invocation: true
---

# Go Live — full lifecycle from build to AppSource

Compound flow that takes a worked-on AL extension through every step from local build to live AppSource. Every destructive operation has an explicit confirmation gate.

## Stages

1. **Local build** (AL MCP) — `al_build`
2. **Sandbox publish** (AL MCP) — `al_publish` to a sandbox env
3. **Sandbox smoke test** — user-driven manual or scripted check
4. **CI build verification** — confirm the latest commit passes CI/CD
5. **Cut a release** (AL-Go) — `Create release`
6. **Submit to AppSource** (AL-Go) — `Publish To AppSource` (Preview)
7. **(Optional) Promote to live** — `Publish To AppSource` with `GoLive=true`

## Preflight (run once at start)

1. Confirm cwd is an AL-Go repo of type `AppSource App`.
2. Confirm all required secrets exist (`gh secret list`):
   - `GhTokenWorkflow` (for releases)
   - `AppSourceContext` (for AppSource)
   - Codesign secrets OR `keyVaultCodesignCertificateName`
3. Confirm `.AL-Go/settings.json` has:
   - `deliverToAppSource.productId`
   - `appSourceCopMandatoryAffixes` non-empty
4. Confirm the user has Partner Center access (first AppSource upload is manual; this command assumes the product already exists in Partner Center).
5. Ask the user for:
   - Target sandbox environment name + tenant (for stage 2)
   - Release tag (semver, e.g. `1.2.0`) and display name (e.g. `v1.2`)
   - Next-cycle version bump (e.g. `+0.1`)
   - Whether to Go Live at the end (default `false`)

## Stage 1 — Local build

Call `/al-build` (or the AL MCP `al_build` directly) with full code analysis enabled:

```json
{
  "scope": "current",
  "enableCodeAnalysis": true,
  "codeAnalyzers": ["${CodeCop}", "${AppSourceCop}", "${UICop}"]
}
```

If errors, stop here and surface them. Do not proceed.

## Stage 2 — Sandbox publish

Call `/al-publish-sandbox` with the target sandbox env. If the user has not authenticated this session, call `al_auth_login` first.

## Stage 3 — Sandbox smoke test

Pause and ask the user to manually verify the deployed extension in the sandbox. Do not proceed without explicit "smoke tests passed" confirmation.

For repos that have automated UI / API tests against the sandbox, the user can invoke them now. The agent should not assume the test surface — ask.

## Stage 4 — CI build verification

Check that the latest commit on the user's branch has a green CI/CD run:

```bash
gh run list --workflow "CI/CD" --branch <branch> --limit 1 --json conclusion,databaseId,headSha
```

If the latest run is `failure`, surface the failure and stop. If `success`, capture the run's `databaseId` for later reference.

If no CI/CD run exists for the latest commit, push the branch and wait for CI/CD to complete before proceeding.

## Stage 5 — Cut a release

Confirm with the user: "About to cut release `<tag>` from build `<buildVersion>`. This will create a GitHub release with attached `.app` artifacts and open an Increment Version Number PR for `<bump>`. Proceed?"

On confirmation, call `/al-release`:

```bash
gh workflow run "Create release" \
  --ref main \
  -f buildVersion=latest \
  -f name=<display name> \
  -f tag=<tag> \
  -f releaseType=Release \
  -f directCommit=false \
  -f useGhTokenWorkflow=true \
  -f updateVersionNumber=<bump>
```

Watch the run. If it fails, stop.

## Stage 6 — Submit to AppSource (Preview)

Confirm with the user: "About to submit release `<tag>` to AppSource in Preview state. This is reviewable by you in Partner Center before going live. Proceed?"

On confirmation:

```bash
gh workflow run "Publish To AppSource" \
  --ref main \
  -f appVersion=current \
  -f projects=* \
  -f GoLive=false
```

Watch the run. The workflow returns when the submission is accepted for validation (not when validation finishes). Microsoft validation typically takes 24–72 hours.

## Stage 7 — Promote to live (OPTIONAL, requires explicit confirmation)

If and only if the user explicitly requested Go Live at preflight AND the Stage 6 submission has passed Microsoft validation (visible in Partner Center), confirm once more with the user — "About to promote release `<tag>` to public AppSource. This makes it available to every BC customer immediately. Proceed?" — then:

```bash
gh workflow run "Publish To AppSource" \
  --ref main \
  -f appVersion=current \
  -f projects=* \
  -f GoLive=true
```

If validation has not completed yet, stop here and tell the user to come back when it has, then re-run this stage only.

## After Stage 7

- Confirm the listing is live at `https://appsource.microsoft.com/en-us/product/dynamics-365-business-central/<publisher>.<offerId>`.
- Merge the Increment Version Number PR from Stage 5.
- The dev cycle for the next version begins on the bumped version on main.

## Failure handling at every stage

Any stage failure stops the flow. Do NOT attempt the next stage. Surface what failed and what the user should do — usually one of:

- Fix in source and restart from Stage 1.
- Re-run the failed stage's underlying command directly (e.g. re-dispatch the workflow).
- Run `/al-troubleshoot` if the cause is unclear.
