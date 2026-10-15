---
name: bcq-review-upgrade
description: Run only the BCQuality Upgrade review (al-upgrade-review) on AL code, covering upgrade codeunits, upgrade tags, data migration and transfer patterns, and what upgrade code must not do (for example ChangeCompany). The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants upgrade feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Upgrade review

Runs the `al-entry` skill with a goal that names upgrade explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-upgrade-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-upgrade-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-upgrade-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/upgrade/`.
- `<plugin>/content/bcapps-review-prompts/upgrade.md` (frozen at BCApps `7040033d`: upstream deleted these prompts in favour of BCQuality, so treat them as supplementary and let BCQuality win on conflict).

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-upgrade-review"`. Every finding carries `domain: "Upgrade"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Upgrade or install codeunits changed.
- Schema changes need a data migration.
- Preparing a version bump that obsoletes fields or tables.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
