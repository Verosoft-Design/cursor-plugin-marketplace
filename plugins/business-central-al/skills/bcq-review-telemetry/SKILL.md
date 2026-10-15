---
name: bcq-review-telemetry
description: Run only the BCQuality Telemetry review (al-telemetry-review) on AL code, covering Session.LogMessage and Feature Telemetry, verbosity, TelemetryScope, custom dimensions, and data classification of telemetry signals. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants telemetry feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Telemetry review

Runs the `al-entry` skill with a goal that names telemetry explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-telemetry-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-telemetry-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-telemetry-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/telemetry/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-telemetry-review"`. Every finding carries `domain: "Telemetry"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Telemetry calls or wrapper codeunits were added or changed.
- Feature usage or error logging is being instrumented.
- Telemetry may carry customer data.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
