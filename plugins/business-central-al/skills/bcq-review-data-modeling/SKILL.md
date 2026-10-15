---
name: bcq-review-data-modeling
description: Run only the BCQuality Data modeling review (al-data-modeling-review) on AL code, covering setup and master tables, keys, No. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants data modeling feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Data modeling review

Runs the `al-entry` skill with a goal that names data modeling explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-data-modeling-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-data-modeling-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-data-modeling-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/data-modeling/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-data-modeling-review"`. Every finding carries `domain: "Data Modeling"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Tables, table extensions, or keys were added or changed.
- Master data, setup tables, or No. Series handling changed.
- Document or posting structures changed.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
