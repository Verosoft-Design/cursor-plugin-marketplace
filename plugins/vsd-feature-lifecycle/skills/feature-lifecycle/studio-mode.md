# Studio mode: AL Builder

Use this workflow only after section 0 of `SKILL.md` selects Studio mode. It overrides sections 1–5 and the standard step files wherever they conflict. The requester who dispatched the work is the only approver. Keep the spec, scope and progress in the project thread and dispatch files. There is no Linear work, named Verosoft approver, G1–G6 gate, or PR. The platform handles submission and merging.

Follow **spec → build → prove → release notes → deliver a version**. Bugs and Features have one gate: **Approve spec and scope**. Size is the agent's decision, with no separate size approval. Major work stops at that card.

## 1. Context, size and spec

1. Read the project's instructions, `al-builder.json`, existing dispatch status and source. Call `bc_project_context({})` for the bound sandbox, app identity, reserved blocks, accepted version, TAG version and production install targets. Download current sandbox symbols through `bc_download_symbols({})`; use local AL symbol search to verify objects, events and signatures. These discovery calls do not claim the app for building.
2. Use [sizes.md](sizes.md) for the size definitions and escalation criteria only; this file supplies the workflow. A **Bug** restores agreed behavior; a **Feature** adds behavior within an existing process. Existing-data migrations, upgrade code that changes data, core-process redesign, or work longer than about two weeks are **Major**. Size can go up, never down. Settle what the source and symbols answer yourself; ask the requester only what cannot be settled that way.
3. For every size, including a Bug, write `docs/dispatches/<yyyy-mm-dd>-<slug>.md` with:
   - the request, size and reason;
   - what changes and its scope, including affected AL objects and verified extension points;
   - plain-language test scenarios with expected results;
   - what is out of scope;
   - an estimate, including the expected cost on platform credits and any assumptions or uncertainty. Do not invent a known price when pricing context is unavailable;
   - the target BC version and any sandbox/production major-version difference. Keep `app.json` targeting the lowest version among the sandbox and all production install targets.
4. Call `bc_request_spec_approval` once for the combined spec and scope:

   ```text
   bc_request_spec_approval({ title, specPath, summary, size, estimate })
   ```

   `size` is `bug`, `feature` or `major`. The spec must already exist at `specPath`. Handle the response:
   - `{ approved: true, dispatchId }`: retain the ID and proceed for Bug or Feature.
   - `{ revise, dispatchId }`: apply the requested revision to the same spec, then ask again through the same tool. This is a revision of the one gate, not an additional gate.
   - `{ awaitingUser: true, dispatchId }`: tell the requester the spec-and-scope card is ready, then stop the run. On resume, use the saved dispatch and approval state instead of making a duplicate request.
   - `{ stoppedMajor: true }`, or a **Major** size regardless of response: offer two paths, **split into independently deliverable Features** or **hand off to Verosoft or the requester's partner as a services job**, and stop. Do not claim, code or publish. Splitting cannot relabel the same data migration as a Feature.

An implementation request alone does not bypass this Studio gate. If work grows to Major later, update the spec and call `bc_request_spec_approval` with `size: 'major'`; stop with the same two paths.

## 2. Claim and build test-first

1. After approval, call `bc_claim_build({ dispatchId })` **before implementation**.
   - `{ queued: true, heldBy: { dispatchId, title, status } }`: tell the requester which dispatch holds the app and its status, then stop. Do not work around the queue or start coding.
   - `{ claimed: true, baseVersion, nextVersion }`: build from that last **accepted** base (the initial template when `baseVersion` is null), never an unaccepted or discarded version. Keep this dispatch ID on all later calls. The app stays held until the delivered version is accepted or discarded.
2. Refresh sandbox symbols with `bc_download_symbols({})` before building. Retain the project's app/test identities, affix and reserved ID blocks from `al-builder.json`; this dispatch extends the existing app. Use the `nextVersion` returned by `bc_claim_build` unchanged for the versions in `app/app.json` and `test/app.json`, the release-notes file name `docs/release-notes/<nextVersion>.md`, and the `version` passed to `bc_record_build`. The platform computes this number; never compute or change it yourself.
3. Use `business-central-al-tdd` and `al-write-test` under their **online-sandbox / AL Builder** rules. The run environment has `AL_BUILDER=1`. Use only Test Runner, Library Assert, Any and Library Variable Storage. The existing test app supplies its own fixtures, isolated in **AL Builder Tests**, never customer companies. Keep business logic in codeunits and tables. TestPage, TestRequestPage and page/request-page handlers do not run headlessly; put page wiring in the requester's sandbox checklist instead. Keep the generated `test/src/runner/` objects unchanged.
4. Write the smallest regression/scenario test **before** the implementation. Compile both apps locally with the AL MCP or compiler, with **CodeCop, PTECop (PerTenantExtensionCop) and UICop**, to `.output/app.app` and `.output/test.app`. Fix compilation errors and new warnings.
5. Publish and run the red test through the broker:

   ```text
   bc_publish({ which: 'both' })
   bc_run_tests_start({ codeunitFilter: '<test codeunit ID>' })
   bc_run_tests_status({ testRunId: '<returned ID>' })
   ```

   On `{ busy: true, retryAfterSeconds }`, wait that interval before starting again. Poll status every 15 seconds until `done` or `error`. Record the expected failing assertion, codeunit, method, error and call stack, and keep this red run's `testRunId`: the requester sees it as the "Before the change" report. A compilation error, missing handler, running test or infrastructure error is not red evidence.
6. Make the smallest fix, compile clean, publish both apps again, and repeat start/status until the regression passes. Retain actual red-then-green results; never claim execution from a prediction.

## 3. Prove the candidate

1. Run `bcq-review` **once** on the change. Judge every finding yourself: fix it or explain why it is declined. Write the findings and dispositions to `docs/dispatches/<slug>.review.md`; do not start review rounds.
2. Run the business-central-al plugin's check script locally:

   ```text
   python3 <business-central-al>/scripts/al-builder-check.py --project <project-dir> --json
   ```

   Require `ok: true` for both ID ranges and TAG surface. `<business-central-al>` is the installed plugin directory. Repair violations inside the reserved blocks; never expand them yourself.
3. Compile once more against Microsoft's symbols for **each production version and country** returned by `bc_project_context`, using local `al_downloadsymbols` with `globalSourcesOnly: true` into a separate temporary package cache for each target. Compile in temporary copies/output paths so these checks preserve the manifests and `.output/` delivery artifacts. Keep customer PTE/AppSource dependencies from the sandbox. These are local compatibility checks; never connect, publish or run tests in production. Any compatibility failure blocks delivery.
4. Write the version release notes described below and finalize the review report. Compile both deliverable apps clean against the bound sandbox/target symbols, publish through `bc_publish({ which: 'both' })`, then run the **full project test suite**:

   ```text
   bc_run_tests_start({})
   bc_run_tests_status({ testRunId: '<returned ID>' })
   ```

   Omit `codeunitFilter` entirely. Poll to `status: 'done'` and require zero failures with actual method results. Keep this full run's `testRunId` for recording. If any tracked file changes after the passing run, repeat the checks, compilation, publish and full suite for the final candidate tree before recording. A filtered, running or errored run cannot prove delivery.

## 4. Deliver the version

Write `docs/release-notes/<version>.md` with the behavior change, completed test evidence and any limitations. End it with a **Check in the sandbox** list of page changes for the requester to click through (field placement, visibility and actions). If there are no page changes, say so in that final list. Both the release notes and `docs/dispatches/<slug>.review.md` must be saved and covered by the final candidate's passing full run.

Call:

```text
bc_record_build({ dispatchId, version, testRunId, redTestRunId, reviewReportPath, releaseNotesPath })
```

Use the completed full run's ID, the red run's ID as `redTestRunId` (a finished run of this dispatch with at least one failure; `{ rejected: 'invalid_red_run' }` means pick the right one), and the saved paths. `{ rejected: reason }` blocks delivery: address the reason and repeat the affected checks; do not claim a version was recorded. On `{ recorded: true, versionId }`, report the recorded version and evidence, then let the platform's submission flow merge and deliver it. Do not open a PR, merge it yourself, or accept the version for the requester. The requester tries it in the sandbox, then accepts it or asks for changes through the platform.

## TAG and stopping conditions

- **TAG public surface (D23):** table/page extensions, subscriptions to TAG or base-app events, TAG API pages, and only the TAG procedures allowlisted by the TAG team for the installed version. Public visibility alone is not permission. When a required extension point is missing, call `bc_request_tag_extension_point({ summary, details, tagObjects })`, tell the requester, and stop that part of the work; do not bypass TAG internals or create an issue yourself.
- **Expired sign-in:** on `{ needsSignIn: true }` from any tool, tell the requester to sign in again and **stop immediately**. Do not retry, mark the dispatch failed, or sign in through the AL MCP.
- **Other tool errors:** report the code and the next action needed, without bypassing the broker's environment or authorization checks. Missing tools or an unavailable test environment block proof; never fabricate results.
- **Sandbox only:** all BC access goes through `bc_*` broker tools. The AL MCP supplies local compilation, diagnostics, symbol search and unauthenticated global-symbol downloads only. Never request, store or print a BC token, call BC directly, or use an alternative test runner.
- **Never:** production access, `forcesync`/`Recreate` (publish uses `SchemaUpdateMode=synchronize`), editing the generated runner, or allocating object/extension-field/enum-extension-value IDs outside `al-builder.json`'s blocks within 50000–99999. A change requiring destructive synchronization is Major and stops.
