---
name: al-upgrade-review
description: Review AL schema, upgrade codeunit, and migration changes using BCQuality's curated upgrade knowledge plus BCApps' MIT-licensed upgrade review prompt. Detects enum-ordinal shifts (blocker), missing obsoletion staging, hand-rolled DataVersion checks instead of Upgrade Tags, InitValue on existing tables without backfill, external HTTP in upgrade codeunits, and other BC-specific upgrade footguns. Returns not-applicable when the diff touches no upgrade/schema/enum surface.
---

# AL Upgrade Review (leaf)

This skill is the Cursor adapter for BCQuality's `al-upgrade-review` leaf skill.

## Authoritative spec

Read `<plugin>/content/bcquality/microsoft/skills/review/al-upgrade-review.md` in full. It declares the canonical Source → Relevance → Worklist → Action pattern for the upgrade domain.

Also read `<plugin>/content/bcapps-review-prompts/upgrade.md` — the MIT-licensed BCApps AI review prompt for upgrade scenarios (~22 KB). Both feed the worklist.

## Apply contract rules

Load `bcquality-do-contract`, `bcquality-read-contract`, and `al-mcp-usage`.

## Source

Read every knowledge file under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/upgrade/*.md`. Today:

- 18+ files under `microsoft/knowledge/upgrade/`. Canonical examples: `enum-values-additive-at-end.md`, `use-upgrade-tags-not-version-checks.md`, `obsoletion-requires-reason-and-tag.md`, `initvalue-does-not-update-existing-rows.md`, `datatransfer-skips-triggers-and-subscribers.md`, `breaking-changes-only-on-tables-without-data.md`.
- Custom-layer: `tag-clean-version-preprocessor.md` (TAG-specific CLEAN preprocessor pattern).

## Relevance

Filter by frontmatter per the READ contract.

**Important narrowing**: the upgrade skill returns `outcome: "not-applicable"` when the diff touches NO upgrade, install, schema, or enum surface. Decide this in the Worklist step before evaluating any files.

## Worklist signal tokens (from upstream skill, verbatim)

`Subtype = Upgrade`, `Upgrade Tag`, `HasUpgradeTag`, `SetUpgradeTag`, `OnValidateUpgrade`, `DataTransfer`, `CopyFields`, `InitValue`, `ObsoleteState`, `ObsoleteReason`, `ObsoleteTag`, `DataVersion`, `ExecutionContext`, `PrimaryKey`, `key(`, `field(`, `value(`, `enum`, `enumextension`, `HybridSL`, `HybridGP`, `HybridBC`, `HybridBaseDeployment`.

Weight toward codeunits with `Subtype = Upgrade` or `Install`, tables and tableextensions adding/changing fields, enums and enumextensions, `Hybrid*`/`Migration`/`Upgrade` namespaces, and the upgrade trigger family (`OnUpgradePerCompany`, `OnUpgradePerDatabase`, `OnValidateUpgradePerCompany`, `OnValidateUpgradePerDatabase`, `OnInstallAppPerCompany`, `OnGetPerCompanyUpgradeTags`, `OnGetPerDatabaseUpgradeTags`).

Resolve layer precedence; suppressed files go into `suppressed[]`.

## Action

`blocker` is broader here than in other leaves — it covers irreversible data corruption (enum-ordinal shift, unguarded reads that abort the upgrade) and changes that would ship to customers without a migration path (new `InitValue` on an existing table without upgrade code).

`major` for changes that compile and ship but break customer data integrity at runtime.

`minor` for style issues inside upgrade code that aren't dangerous (e.g. duplicated tag logic).

## Output

Single JSON document conforming to the DO output contract. When the diff has no upgrade-relevant changes, return `outcome: "not-applicable"` with `outcome-reason` naming what was checked.
