---
name: bcq-review-ui
description: Run only the BCQuality UI / accessibility review (al-ui-review) on AL code, covering captions, tooltips, UI text, notifications, page-type conventions, and accessibility. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants UI / accessibility feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: UI / accessibility review

Runs the `al-entry` skill with a goal that names UI / accessibility explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-ui-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-ui-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-ui-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/ui/`.
- `<plugin>/content/bcapps-review-prompts/accessibility.md` (frozen at BCApps `7040033d`: upstream deleted these prompts in favour of BCQuality, so treat them as supplementary and let BCQuality win on conflict).

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-ui-review"`. Every finding carries `domain: "Accessibility"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- A page, page extension, or page customization was added or changed.
- Control add-in JavaScript, CSS, or HTML changed.
- Auditing accessibility before AppSource validation.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
