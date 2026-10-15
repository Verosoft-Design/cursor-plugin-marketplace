---
name: bcq-review-privacy
description: Run only the BCQuality Privacy review (al-privacy-review) on AL code, covering DataClassification on tables and fields, personal data in telemetry and error text, and retention policies. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants privacy feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Privacy review

Runs the `al-entry` skill with a goal that names privacy explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-privacy-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-privacy-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-privacy-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/privacy/`.
- `<plugin>/content/bcapps-review-prompts/privacy.md` (frozen at BCApps `7040033d`: upstream deleted these prompts in favour of BCQuality, so treat them as supplementary and let BCQuality win on conflict).

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-privacy-review"`. Every finding carries `domain: "Privacy"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Tables or table extensions with new fields were added.
- Telemetry or error messages may carry customer data.
- Retention policies or personal-data handling changed.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
