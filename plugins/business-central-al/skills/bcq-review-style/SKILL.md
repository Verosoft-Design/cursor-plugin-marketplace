---
name: bcq-review-style
description: Run only the AL style review (skip the other 5 leaves and the super-skill self-review). Use when the user specifically wants style feedback — typically before a code-review request asks "is this idiomatic?", when auditing label conventions, or when applying repo-specific style overrides from the custom layer.
disable-model-invocation: true
---

# Targeted: style review

Dispatches `al-entry` with a goal explicitly naming "style". Entry's `narrower-sub-skill-selected` precedence selects `al-style-review`.

## Inputs

PR diff, file path, or object list.

## Output

A single JSON document per the DO contract from `al-style-review` only.

The leaf reads:

- `<plugin>/content/bcquality/microsoft/skills/review/al-style-review.md` (authoritative spec).
- Knowledge files under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/style/`.
- `<plugin>/content/bcapps-review-prompts/style.md` (the largest of the 6 review prompts).

## Custom-layer overrides for this repo

TAG-specific style articles in the custom layer that override BCApps defaults:

- `tag-object-id-ranges.md` (publisher-allocated ID ranges)
- `tag-filename-pattern.md` (overrides BCApps `<Object>.<Type>.al` with TAG's `[Type] [ID] - TAG [Name].al`)
- `tag-object-name-prefix.md` (the `"TAG "` mandatory affix)
- `tag-project-folder-structure.md` (overrides BCApps `src/<Module>/src/` with TAG's per-object-type root folders)
- `tag-procedure-parameter-prefix.md` (overrides BCApps no-prefix with TAG's `p`-prefix on parameters)
- `tag-variable-naming-conventions.md` (TAG's `EquipmentRec`/`WOHeader`/etc. vocabulary)

When the leaf runs, suppressed BCApps articles appear in the output's `suppressed[]` so reviewers can see what was overridden.

## Use together with a formal analyzer

This skill adds BCQuality's _remedial_ explanations of why each rule exists. For mechanical CodeCop / AppSourceCop / UICop / PTECop violations, run `/al-compile` with `enableCodeAnalysis: true` and the BCApps rulesets via `/al-apply-rulesets`. The two are complementary.
