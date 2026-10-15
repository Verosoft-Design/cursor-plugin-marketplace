---
name: bcq-review-web-services
description: Run only the BCQuality Web services / API review (al-web-services-review) on AL code, covering API pages and queries, OData naming and keys, bound actions, outbound HttpClient calls, and webhook handling. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants web services / API feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Web services / API review

Runs the `al-entry` skill with a goal that names web services / API explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-web-services-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-web-services-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-web-services-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/web-services/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-web-services-review"`. Every finding carries `domain: "Web Services"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- API pages, API queries, or bound actions were added or changed.
- Outbound HTTP integrations changed.
- Webhook subscriptions or handlers changed.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
