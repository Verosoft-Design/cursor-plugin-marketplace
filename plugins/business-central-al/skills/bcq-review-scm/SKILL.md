---
name: bcq-review-scm
description: Run only the BCQuality Supply Chain Management review (al-scm-review) on AL code, covering inventory costing, item application, reservations, order and item tracking, warehouse handling, transfers, and planning. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants Supply Chain Management feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Supply Chain Management review

Runs the `al-entry` skill with a goal that names Supply Chain Management explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-scm-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-scm-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-scm-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/scm/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-scm-review"`. Every finding carries `domain: "Supply Chain Management"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Code posts or adjusts item, warehouse, or transfer entries.
- Reservations, item tracking, or planning logic changed.
- Extending inventory costing or application.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
