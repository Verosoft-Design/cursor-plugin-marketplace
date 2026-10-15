---
name: bcq-review-interfaces
description: Run only the BCQuality Interfaces review (al-interfaces-review) on AL code, covering implements, DefaultImplementation, UnknownValueImplementation, and replacing case-over-enum strategy selection. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants interfaces feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Interfaces review

Runs the `al-entry` skill with a goal that names interfaces explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-interfaces-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-interfaces-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-interfaces-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/interfaces/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-interfaces-review"`. Every finding carries `domain: "Interfaces"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- An interface or an enum with implementations was added or changed.
- Code selects behavior with case over an enum.
- Interface methods or implementations changed in a published app.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
