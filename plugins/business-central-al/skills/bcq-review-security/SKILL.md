---
name: bcq-review-security
description: Run only the AL security review (skip the other 5 leaves and the super-skill self-review). Use when the user specifically wants security feedback — typically before merging an integration/auth change, when investigating credential handling, or to audit permission sets and IntegrationEvent signatures.
disable-model-invocation: true
---

# Targeted: security review

Dispatches `al-entry` with a goal explicitly naming "security". Entry's `narrower-sub-skill-selected` precedence drops `al-code-review` and selects `al-security-review`.

## Inputs

PR diff, file path, or object list.

## Output

A single JSON document per the DO contract from `al-security-review` only.

The leaf reads:

- `<plugin>/content/bcquality/microsoft/skills/review/al-security-review.md` (authoritative spec).
- Knowledge files under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/security/`.
- `<plugin>/content/bcapps-review-prompts/security.md` (BCApps' MIT review prompt for security).

## When to prefer this

- Reviewing credential / OAuth2 / IsolatedStorage / `SecretText` changes.
- Auditing permission sets or `InherentPermissions`.
- Verifying `IntegrationEvent` signatures don't expose security guards as `var Boolean` parameters.
- Reviewing web service / API page exposure.

When in doubt, use `/bcq-review` (the super-skill) — security issues frequently entangle with privacy and upgrade concerns.
