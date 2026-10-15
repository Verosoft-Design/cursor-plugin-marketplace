---
name: bcq-review-appsource
description: Run only the BCQuality AppSource review (al-appsource-review) on AL code, covering app.json metadata, permission sets, profiles, setup and usage entry points, UsageCategory, GuiAllowed for dialogs, and help metadata. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants appSource feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: AppSource review

Runs the `al-entry` skill with a goal that names appSource explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-appsource-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-appsource-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-appsource-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/appsource/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-appsource-review"`. Every finding carries `domain: "AppSource"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Preparing an AppSource submission or validation run.
- app.json, permission sets, or profiles changed.
- Reviewing a whole app folder for marketplace readiness.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
