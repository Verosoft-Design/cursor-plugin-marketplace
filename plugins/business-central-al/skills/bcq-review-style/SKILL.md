---
name: bcq-review-style
description: Run only the BCQuality Style review (al-style-review) on AL code, covering naming, labels and localization, captions and tooltips, API page naming, object and file organization, and code conventions. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants style feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Style review

Runs the `al-entry` skill with a goal that names style explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-style-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-style-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-style-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/style/`.
- `<plugin>/content/bcapps-review-prompts/style.md` (the largest of the 6 review prompts; frozen at BCApps `7040033d`: upstream deleted these prompts in favour of BCQuality, so treat them as supplementary and let BCQuality win on conflict).

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-style-review"`. Every finding carries `domain: "Style"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Naming, labels, or file organization is the concern.
- Checking a change against house conventions (the custom layer's TAG style rules apply here).
- Iterating on style findings from a full /bcq-review.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
