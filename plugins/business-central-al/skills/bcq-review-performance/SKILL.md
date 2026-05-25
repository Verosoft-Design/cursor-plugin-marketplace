---
name: bcq-review-performance
description: Run only the AL performance review (skip the other 5 leaves and the super-skill self-review). Use when the user specifically wants performance feedback — typically before merging a hot-path change, when investigating slow code, or to audit data-access patterns in a specific file or PR.
disable-model-invocation: true
---

# Targeted: performance review

Dispatches `al-entry` with a goal explicitly naming "performance". Entry's `narrower-sub-skill-selected` precedence drops `al-code-review` (the super-skill) and selects `al-performance-review` (the leaf) instead.

## Inputs

PR diff, file path, or object list. Pass whatever the user supplies.

## Output

A single JSON document per the DO contract from `al-performance-review` only. No sibling sub-skills are invoked.

The leaf reads:

- `<plugin>/content/bcquality/microsoft/skills/review/al-performance-review.md` (authoritative spec).
- Knowledge files under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/performance/`.
- `<plugin>/content/bcapps-review-prompts/performance.md` (BCApps' MIT-licensed performance review prompt for complementary guidance).

Render via `scripts/render-findings.sh` for human-readable display.

## When to prefer this over `/bcq-review`

- The user explicitly says "performance".
- The diff is large enough that running all 6 leaves would be slow, and the user has a specific concern.
- After a `/bcq-review` flagged performance findings and the user wants to iterate on the fix.

When the user does NOT name a specific concern, use `/bcq-review` (the super-skill) instead — agent self-review across all 6 domains catches things narrow-scope reviews miss.
