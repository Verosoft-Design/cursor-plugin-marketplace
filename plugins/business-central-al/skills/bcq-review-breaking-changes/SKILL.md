---
name: bcq-review-breaking-changes
description: Run only the BCQuality Breaking changes review (al-breaking-changes-review) on AL code, covering public procedure and event signatures, access modifiers, published fields, and the Obsolete lifecycle (ObsoleteState, ObsoleteTag, CLEAN preprocessor symbols). The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants breaking changes feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Breaking changes review

Runs the `al-entry` skill with a goal that names breaking changes explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-breaking-changes-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-breaking-changes-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-breaking-changes-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/breaking-changes/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-breaking-changes-review"`. Every finding carries `domain: "Breaking Changes"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- The app is a dependency of other apps (library, AppSource).
- Public procedures, events, fields, or enums changed.
- Obsoleting or removing members.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
