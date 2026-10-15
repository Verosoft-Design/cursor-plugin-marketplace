---
name: bcq-review-reporting
description: Run only the BCQuality Reporting review (al-reporting-review) on AL code, covering data items and their triggers, CurrReport.Skip/Break/Quit, request pages, running and saving reports, and layouts. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants reporting feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Reporting review

Runs the `al-entry` skill with a goal that names reporting explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-reporting-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-reporting-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-reporting-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/reporting/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-reporting-review"`. Every finding carries `domain: "Reporting"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Reports or report extensions were added or changed.
- Code runs, prints, or saves reports.
- Document layouts or report selections changed.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
