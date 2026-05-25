---
name: al-write-test
description: Explicitly invoke the al-write-test skill to generate an AL test using the ALTest domain-agent prompt from BC-Bench. Use as a direct entrypoint when the user wants test generation now without scrolling through ambient skill triggers.
---

# Write an AL test (ALTest)

Invokes the `al-write-test` skill, which wraps BC-Bench's `ALTest.agent.md` prompt — the largest measured tooling lever in the BC-Bench leaderboard for AL test generation (+10.7 pt mean, ~2x pass^5 on Opus 4.6 / Copilot).

## What to feed it

The user can supply any of:

- A target codeunit + procedure name (the unit under test).
- A bug scenario (description + repro steps).
- A failing diff that needs regression coverage.
- A list of behaviors to cover.

The skill reads the ALTest prompt in full and applies its rules (preserve existing tests, mandatory `Initialize()`, GIVEN/WHEN/THEN, Library Assert, handler procedures that only set values, etc.).

## Workflow summary

1. Read `<plugin>/content/altest-prompt/ALTest.agent.md`.
2. Apply the `al-testing` rule for project-wide conventions.
3. Identify the target test codeunit (prefer extending existing codeunits per ALTest's preservation rule).
4. Scaffold the test.
5. Run `/al-compile` to verify it builds.
6. Be honest about whether execution was verified — `pass^5 ≈ 40%` means ~60% of generated tests need iteration.

## Prerequisites

- A test app exists in the workspace. If not, run `/al-add-test-app` first (Phase 2 command).
- Library Assert (codeunit 130002) is referenced in the test app's `app.json` dependencies. The `al-testing` rule documents the full standard dependency set.

## Related

- `business-central-al-tdd` — the higher-level TDD workflow skill.
- `/scaffold-test-codeunit` — a lighter-weight template generator when ALTest's full domain-agent prompt is overkill.
- `/scaffold-handler-methods` — handler-procedure templates.
- `/al-add-test-app` — scaffold a new test app folder via AL-Go.
- `/al-compile` and `/al-build` — verify the generated test.
