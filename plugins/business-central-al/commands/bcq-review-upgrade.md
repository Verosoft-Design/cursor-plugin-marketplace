---
name: bcq-review-upgrade
description: Run only the AL upgrade review (skip the other 5 leaves and the super-skill self-review). Use when the user specifically wants upgrade feedback — typically when adding or changing enums, modifying upgrade codeunits, adding InitValue on existing fields, or reviewing migration code.
---

# Targeted: upgrade review

Dispatches `al-entry` with a goal explicitly naming "upgrade". Entry's `narrower-sub-skill-selected` precedence selects `al-upgrade-review`.

## Inputs

PR diff, file path, or object list. The upgrade leaf returns `outcome: "not-applicable"` immediately when the diff touches no upgrade, install, schema, or enum surface — so this command is cheap to run against arbitrary diffs.

## Output

A single JSON document per the DO contract from `al-upgrade-review` only.

The leaf reads:

- `<plugin>/content/bcquality/microsoft/skills/review/al-upgrade-review.md` (authoritative spec).
- Knowledge files under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/upgrade/`.
- `<plugin>/content/bcapps-review-prompts/upgrade.md`.

## When to prefer this

- Adding a new value to an enum (must be at the end — `blocker` if inserted/renumbered).
- Adding `[Obsolete(...)]` markers.
- Writing upgrade codeunits — must use Upgrade Tags, not `DataVersion` checks.
- Modifying table fields' `InitValue`, `DataClassification`, primary keys, etc.
- Reviewing `Hybrid*` migration code.

## Severity in this leaf is broader

Unlike the other leaves, `al-upgrade-review` reaches `blocker` more readily — irreversible data corruption (enum-ordinal shift, unguarded reads that abort the upgrade) and changes that would ship to customers without a migration path (new `InitValue` on an existing table without upgrade code) are all `blocker`. The cost of getting upgrade wrong is data loss, so the severity scale reflects that.

## Custom-layer additions

TAG-specific upgrade pattern: `tag-clean-version-preprocessor.md` codifies the CLEAN preprocessor branching for No.Series / NoSeriesManagement compatibility. Cited automatically when a relevant diff is reviewed.
