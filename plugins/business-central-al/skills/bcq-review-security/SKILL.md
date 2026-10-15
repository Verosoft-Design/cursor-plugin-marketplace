---
name: bcq-review-security
description: Run only the BCQuality Security review (al-security-review) on AL code, covering SecretText and credential handling, NonDebuggable, IsolatedStorage, permission sets and inherent or indirect permissions, IntegrationEvent bypass parameters, HTTP and URI validation, and RecordRef access. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants security feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Security review

Runs the `al-entry` skill with a goal that names security explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-security-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-security-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-security-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/security/`.
- `<plugin>/content/bcapps-review-prompts/security.md` (BCApps' MIT review prompt for security; frozen at BCApps `7040033d`: upstream deleted these prompts in favour of BCQuality, so treat them as supplementary and let BCQuality win on conflict).

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-security-review"`. Every finding carries `domain: "Security"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Code handles credentials, tokens, or secrets.
- Permission sets, inherent permissions, or access checks changed.
- Outbound HTTP calls or event publishers that guard access were added.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
