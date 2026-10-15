---
name: bcq-review-events
description: Run only the BCQuality Events review (al-events-review) on AL code, covering IntegrationEvent and BusinessEvent design, IsHandled patterns, subscriber binding and parameters, database trigger events, and ChangeCompany behavior. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants events feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Events review

Runs the `al-entry` skill with a goal that names events explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-events-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-events-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-events-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/events/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-events-review"`. Every finding carries `domain: "Events"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Event publishers or subscribers were added or changed.
- OnBefore/OnAfter or IsHandled extension points were introduced.
- BindSubscription or manual subscribers are used.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
