---
name: bcq-review-testing
description: Run only the BCQuality Testing review (al-testing-review) on AL code, covering test codeunits and runners, TestIsolation and TransactionModel, TestPermissions, UI handlers and HandlerFunctions, asserterror and expected errors, and fixtures. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants testing feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Testing review

Runs the `al-entry` skill with a goal that names testing explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-testing-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-testing-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-testing-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/testing/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-testing-review"`. Every finding carries `domain: "Testing"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Test codeunits or test libraries changed.
- Tests are flaky or fail on permissions, handlers, or isolation.
- Reviewing test quality before merging a feature.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
