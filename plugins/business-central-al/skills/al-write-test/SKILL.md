---
name: al-write-test
description: Generate a Business Central AL test using the ALTest domain-agent prompt from microsoft/BC-Bench, the only custom agent BC-Bench has measured on test generation (62.4% vs 51.7% mean, pass^5 39.6% vs 22.8%, Claude Opus 4.6 on GitHub Copilot CLI, April-May 2026). Use when the user asks to write, scaffold, or generate AL tests, especially for a specific bug, scenario, or codeunit procedure. For setting up a brand-new test app folder, use /al-add-test-app first.
---

# AL Write Test — ALTest domain agent

This skill wraps the BC-Bench `ALTest.agent.md` prompt for AL test generation. BC-Bench (Microsoft's SWE-Bench port for AL) still lists it as the largest tooling delta on its test-generation leaderboard, as of BC-Bench `7c98b750` (2026-10-13):

| Configuration (GitHub Copilot CLI, 101 tasks, 5 runs) | Mean (95% CI) | pass^5 | Measured |
|---|---|---|---|
| claude-opus-4-6 + ALTest | **62.4%** (61.2-63.6) | **39.6%** | 2026-04-21..23, v0.5.1 |
| claude-opus-4-6, default | 51.7% (47.5-58.8) | 22.8% | 2026-05-06..11, v0.5.3 |
| claude-opus-4-8, default (newest model run) | 60.8% (57.6-64.0) | 31.7% | 2026-06-17, v0.5.5 |

That is +10.7 pt mean and pass^5 up 22.8 → 39.6 on the same model. Read the caveats before quoting it:

- The two Opus 4.6 arms ran on different benchmark versions (0.5.1 vs 0.5.3), three weeks apart.
- ALTest has not been re-measured since April 2026: not on Opus 4.8 or later, and never with Claude Code. BC-Bench has no Claude Code test-generation runs at all. A newer model alone (Opus 4.8, 60.8%) gets close: its confidence interval overlaps the ALTest arm's, though its pass^5 (31.7%) is lower. The prompt's value on current models is unmeasured, so treat the +10.7 pt as an Opus 4.6 result.
- The measured prompt was BC-Bench commit `aa12acbe` (branch `private/milicadjukic/ALTestAgent`). The vendored copy is the merged version from `e484c2bc` (2026-05-05), which differs by one line: "must compile and publish" became "must compile". It has not changed since, through `7c98b750`.

## Authoritative spec

Read `<plugin>/content/altest-prompt/ALTest.agent.md` in full. It is the BC-Bench-shipped, MIT-licensed, 267-line prompt that this skill defers to. The prompt encodes:

- **Role / context** — AL test automation engineer for Business Central.
- **Critical preservation rule** — never delete or simplify existing test code (it was human-approved).
- **Test structure rules** — `[Test]`, `[FEATURE] [AI test]`, `[SCENARIO <WorkItemID>]` header, mandatory `Initialize()`, GIVEN/WHEN/THEN comments with blank lines, full variable names.
- **Build-robustness rules** — prefer adding `[Test]` to an existing codeunit, ≤30-char object names, reserved object ID ranges, preflight checklist.
- **Library catalog** — `Library Assert`, `Library Sales`, `Library Inventory`, `Library - Variable Storage` (only if the test project already references it; end with `AssertEmpty()`), etc. with prescribed usage rules.
- **Forbidden patterns** — no `if/else` in test body, no DotNet, no `Commit()` in helpers, no `TestField` for assertions.
- **Required patterns** — pair `asserterror` with `Assert.ExpectedError()` + `Assert.ExpectedErrorCode()`; handler procedures only set values, never verify.
- **Common-fixes cookbook** — 7 before/after snippets covering `TestField` → `Assert.AreEqual`, `Commit` removal, handler verification anti-patterns, etc.

The prompt is the authoritative behavior. This skill body is just an adapter that tells Cursor when to load it.

## When to invoke

- The user asks to write a test for a specific behavior, bug, or codeunit procedure.
- The user has a failing scenario and wants a regression test.
- The user is doing test-first development on a new feature.
- A prior `/bcq-review` flagged "missing test coverage" and the user wants to address it.

When the user needs to set up a NEW test app folder (no test scaffold exists in the repo yet), invoke `/al-add-test-app` FIRST to dispatch the AL-Go `Create a new test app` workflow. Then this skill scaffolds individual tests inside it.

## Workflow

1. **Read `<plugin>/content/altest-prompt/ALTest.agent.md`** in full. Apply every rule and pattern it documents.
2. **Apply the `al-testing` rule** for the Cursor-side BCApps conventions (Library Assert codeunit 130002, `EventSubscriberInstance = Manual`, `[TransactionModel(...)]` matching `Commit` behavior, Given/When/Then structure). The two are complementary: ALTest is the prompt-engineered domain agent; the `al-testing` rule is the plugin reference doc for the project's overall conventions. Where they disagree, follow ALTest, because it is the measured prompt. In particular, handlers only capture or set values (e.g. `LibraryVariableStorage.Enqueue(Message)`) and the assertions go in the test body.
3. **Identify the target test codeunit.** Per the ALTest preservation rule: prefer ADDING a new `[Test]` to an existing codeunit over creating a new file. Sample existing test codeunits in the repo before scaffolding new files.
4. **Locate the production code under test.** Sample the codeunit / table / page that the new test exercises. Identify which library codeunits will be needed.
5. **Apply the relevant common-fix patterns from ALTest** if the test exercises code that historically had issues (e.g. `TestField` calls in assertion positions, missing handler verification).
6. **Write the test** following the ALTest structure exactly.
7. **Run `/al-compile`** with errors-only to confirm the test compiles. Fix any errors. Recommend `/al-build` next.
8. **Run it** with `/al-run-tests` (narrowed to the new test procedure) when a BC server is configured. A new test for a bug should fail before the fix and pass after. Be explicit when execution cannot be verified in the current session.

## Quality cap

ALTest is a high-yield domain-agent prompt, but BC-Bench's pass^5 on test generation with the prompt is still only 39.6%. That is the best pass^5 on the test-generation leaderboard as of `7c98b750`, and it means ~60% of tasks fail in at least one of five runs. Practical implications:

- **Surface confidence honestly.** Tests generated without runtime verification should be marked as "scaffolded, not verified" and the user should run them in a real environment before merging.
- **Encourage human review.** The generated test is a starting point; the user knows the business scenario better than the model.
- **Don't oversell.** Avoid framing generated tests as "ready to merge". The realistic framing is "ready to review and refine".

## Related

- `business-central-al-tdd` — the higher-level TDD workflow skill.
- the `al-testing` rule — the always-on AL testing conventions rule.
- `/scaffold-test-codeunit` — a template generator for fresh test codeunits when ALTest is overkill.
- `/scaffold-handler-methods` — handler procedure templates.
- `/al-add-test-app` — Phase 2 command that creates a fresh test app folder via AL-Go.
- `/al-compile` — to validate the generated test compiles before the user reviews it.
