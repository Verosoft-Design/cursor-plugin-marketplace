# TAG custom-layer seed articles

Distilled from `tag-source/*.mdc` (the 8 original TAG rules from `/Users/alexisturgeon/Source/tag-bc/.cursor/rules/`). These become BCQuality custom-layer knowledge articles in Phase 4, living at:

```
plugins/business-central-al/content/bcquality/custom/knowledge/<domain>/<slug>.md
```

Per the BCQuality DO contract, `/custom/` precedence overrides `/community/` and `/microsoft/`. The articles below intentionally CONTRADICT some `/microsoft/` guidance (BCApps' `<Object>.<Type>.al` filename rule, BCApps' procedure-parameter style) — that contradiction is expected and is resolved automatically by layer precedence at review time.

## Article inventory (8 articles to author in Phase 4)

| # | Slug | Domain | Overrides Microsoft layer? | Source rule |
|---|---|---|---|---|
| 1 | `tag-object-id-ranges.md` | style | New concern | `tag-naming.mdc` §"Object ID Ranges" |
| 2 | `tag-filename-pattern.md` | style | **YES** — overrides `file-name-object-type-pattern.md` | `tag-naming.mdc` §"Object Naming Pattern" |
| 3 | `tag-object-name-prefix.md` | style | New concern | `tag-naming.mdc` §"Internal Object Names" |
| 4 | `tag-project-folder-structure.md` | style | **YES** — overrides BCApps `src/<Module>/src/` convention | `tag-naming.mdc` §"Directory Structure" |
| 5 | `tag-procedure-parameter-prefix.md` | style | **YES** — adds `p`-prefix on parameters (BCApps does not) | `al-general.mdc` §"Procedure Structure" + `codeunits.mdc` |
| 6 | `tag-variable-naming-conventions.md` | style | New concern | `al-general.mdc` §"Naming Conventions" + `codeunits.mdc` §"Variable Organization" |
| 7 | `tag-api-page-conventions.md` | api | New concern | `api-pages.mdc` (entire file) |
| 8 | `tag-clean-version-preprocessor.md` | upgrade | New concern | `al-general.mdc` §"Preprocessor Directives" |

## Drafts (ready to drop into knowledge files in Phase 4)

### 1. `tag-object-id-ranges.md`

```yaml
---
bc-version: [all]
domain: style
keywords: [object-id, id-range, verosoft, tag]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

```markdown
# TAG object IDs must fall in the Verosoft-allocated ranges

## Description
Verosoft Design has two allocated object ID ranges for The Asset Guardian (TAG) app: `70015000..70016999` for primary objects (tables, codeunits, pages, reports, enums, queries, XMLports) and `23085634..23085783` for API pages and their related objects. Every new TAG object MUST land inside one of these ranges; objects outside the range collide with AppSource neighbors and trip AS0084 on AppSource Cop.

## Best Practice
For a new TAG table, codeunit, page (non-API), report, enum, query, or XMLport: pick the next free ID in `70015000..70016999`. For a new TAG API page (and its supporting page/codeunit if any): pick from `23085634..23085783`. Document the allocation in the project's running ID registry.

## Anti Pattern
Reusing IDs outside the two allocated ranges, or sampling from Microsoft's system range (e.g. anything <70000000). Such IDs collide with other AppSource apps and will be rejected by AppSourceCop on the next release build.
```

### 2. `tag-filename-pattern.md` (OVERRIDES Microsoft layer)

```yaml
---
bc-version: [all]
domain: style
keywords: [filename, file-naming, verosoft, tag]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

```markdown
# TAG AL files use the "[ObjectType] [ObjectID] - TAG [Name].al" pattern

## Description
TAG follows a numeric-ID-first filename convention: every `.al` file is named `[ObjectType] [ObjectID] - TAG [ObjectName].al` — for example `Table 70016325 - TAG Key Safe.al`, `Page 23085760 - TAG Key Safe List.al`, `Codeunit 70015921 - TAG Evaluate AutoPlan.al`. This overrides the BCQuality default (`<Object>.<Type>.al` as used in Microsoft BCApps). The leading object type and ID make the file's identity obvious in the file tree and in code-review diffs.

## Best Practice
Name new files exactly `[Type] [ID] - TAG [Name].al`. For API pages specifically, the entity name uses camelCase inside the object name but PascalCase in the file name: `Page 23085779 - TAG API Key Safes.al`. Existing TAG files already follow the convention — extending the codebase means matching what's there.

## Anti Pattern
Naming a new TAG file `KeySafe.Table.al` (BCApps style) or `T70016325.al` (legacy NAV style). Both diverge from the TAG convention and make it impossible to scan the file tree by ID range.
```

### 3. `tag-object-name-prefix.md`

```yaml
---
bc-version: [all]
domain: style
keywords: [object-name, prefix, tag, affix, appsourcecop]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

```markdown
# TAG objects must use the "TAG " prefix in their internal name

## Description
AppSourceCop rule AS0011 (mandatory affixes) requires every object name in an AppSource extension to carry the publisher's affix. For TAG, the affix is the word `TAG` followed by a space, used as a PREFIX on every object name: `table 70016325 "TAG Key Safe"`, `page 23085760 "TAG Key Safe List"`, `codeunit 70015921 "TAG Evaluate AutoPlan"`, `enum 70015900 "TAG Equipment Status"`. The `app.json` field `appSourceCopMandatoryAffixes` is set to `["TAG "]` (with trailing space) to enforce this at build time.

## Best Practice
Prefix every new object's internal name with `TAG ` (capital letters, single trailing space). The same applies to table extensions, page extensions, and enum extensions even though they extend Microsoft-owned objects — the extension object's name still carries the affix.

## Anti Pattern
Naming an object `"Key Safe"` (no prefix), `"TAG_KeySafe"` (no space), `"tag Key Safe"` (lowercase), or using a different affix like `"VSD Key Safe"`. All trip AS0011 and block the AppSource build.
```

### 4. `tag-project-folder-structure.md` (OVERRIDES Microsoft layer)

```yaml
---
bc-version: [all]
domain: style
keywords: [folder-structure, project-layout, tag, repository]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

```markdown
# TAG repositories use the per-object-type folder layout at the project root

## Description
TAG repositories use a flat, per-object-type folder layout at the project root, NOT the BCApps `src/<Module>/src/` convention. The canonical TAG layout: `API/` (API pages), `CodeUnit/` (codeunits), `controladdin/`, `Enums/`, `Page_Extension/`, `Pages/`, `permissionSets/`, `Profile/`, `Queries/`, `Reports/`, `Table_Extension/`, `tables/`, `TAGProject/` (project-management objects), `Translations/` (XLF), `XMLport/`. This overrides BCQuality's Microsoft layer expectation that AL apps follow the BCApps module-folder convention.

## Best Practice
When adding a new object to an existing TAG repository, drop it in the matching folder above (creating the folder if it does not exist for that object type). When scaffolding a brand-new TAG app, recreate the same folder layout from day one so subsequent contributors can navigate by intuition.

## Anti Pattern
Introducing a `src/<FeatureName>/` BCApps-style subtree inside a TAG repository, or scattering files across ad-hoc folder names like `Misc/` or `Other/`. Both break the convention that lets reviewers find any object by knowing only its type.
```

### 5. `tag-procedure-parameter-prefix.md` (OVERRIDES Microsoft layer)

```yaml
---
bc-version: [all]
domain: style
keywords: [procedure, parameter, naming, prefix, tag]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

```markdown
# TAG procedure parameters are prefixed with "p"

## Description
TAG codeunits prefix every procedure parameter with the lowercase letter `p` — e.g. `procedure ProcessEquipment(pEquipmentID: Code[20]; pProcessDate: Date)`. The prefix disambiguates parameters from local variables at every call site and at every use within the procedure body. This overrides the BCApps convention (which uses no prefix and disambiguates via type-name suffixes instead).

## Best Practice
Name every parameter `p` + `PascalCaseName` regardless of type: `pCode`, `pEquipmentRec`, `pIsActive`. The matching local variable, if any, drops the `p`: `EquipmentRec` (local) vs `pEquipmentRec` (parameter). Boolean parameters still read as a question (`pIsActive`, `pHasPermission`).

## Anti Pattern
Naming a parameter with no prefix in a TAG codeunit (BCApps style) — readers cannot tell from the usage site whether a name is a parameter or a local. Mixing prefixed and unprefixed parameters in the same codeunit is even worse: it signals "no convention" and degrades to noise.
```

### 6. `tag-variable-naming-conventions.md`

```yaml
---
bc-version: [all]
domain: style
keywords: [variable, naming, record-prefix, tag]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

```markdown
# TAG record variables use the standard short-prefix vocabulary

## Description
TAG has an established vocabulary of record-variable short names so that any contributor reading any codeunit can tell at a glance what type a variable is. The canonical mapping: `EquipmentRec` or `Equipment` for `Record "TAG Equipment"`; `WOHeader` for `Record "TAG Work Order Header"`; `WOLine` for `Record "TAG Work Order Line"`; `TechRec` for technician records; `TAGSetup` for `Record "TAG Setup"`; `DMPolicy` / `DateMeterHeader` for DateMeter records; `MaintHeader` / `TemplateRec` for maintenance templates. Variable declaration order in the var block: Records → Codeunits → Pages/Reports → simple types (Integer, Decimal, Boolean) → Text/Code.

## Best Practice
When you add a new variable for one of the listed record types, use the established short prefix. When you introduce a brand-new record type, pick a short PascalCase prefix and apply it consistently across the codebase from day one.

## Anti Pattern
Inventing a new prefix per file ("Equip", "Eq", "TagEquip", "EquipmentRecord", "myEquipment") for an already-named type, or putting Text/Code variables before Record variables in a var block. Both break the conventions that make TAG codeunits navigable.
```

### 7. `tag-api-page-conventions.md`

```yaml
---
bc-version: [all]
domain: style
keywords: [api-page, verosoft, tag, apipublisher, apigroup]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

```markdown
# TAG API pages use the verosoftdesign/tag/v1.0 OData triplet

## Description
Every TAG API page declares the same publisher/group/version triplet: `APIPublisher = 'verosoftdesign'`, `APIGroup = 'tag'`, `APIVersion = 'v1.0'`. Entity names are camelCase singular (`keySafe`, `workOrder`), entity-set names are PascalCase plural (`KeySafes`, `WorkOrders`), field names exposed via the page are camelCase (`serialNo`, `masterLock`). Every API page declares `ODataKeyFields = SystemId`, `DelayedInsert = true`, and the four standard system fields first in the repeater (`id` = `Rec.SystemId`, `systemCreatedAt`, `systemModifiedAt`, plus `lastModifiedDateTime` if applicable). The resulting OData URL is `/api/verosoftdesign/tag/v1.0/companies({companyId})/<EntitySetName>`.

## Best Practice
When adding a new TAG API page, copy the template from an existing one (e.g. `Page 23085760 - TAG API Key Safes.al`) and change only the entity name, object ID (must be in `23085634..23085783`), and field list. Keep the triplet, key fields, permission flags (`InsertAllowed/ModifyAllowed/DeleteAllowed`), and the four system fields exactly as shown.

## Anti Pattern
Bumping `APIVersion` to `v2.0` without coordinating across the entire TAG API surface (consumers break), changing the publisher or group string per page (the OData URL becomes inconsistent), or omitting the system fields from the repeater (consumers lose the standard BC entity identifier).
```

### 8. `tag-clean-version-preprocessor.md`

```yaml
---
bc-version: [all]
domain: upgrade
keywords: [preprocessor, clean24, no-series, version-compatibility, tag]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

```markdown
# Use CLEAN<N> preprocessor symbols to bridge old and new BC APIs in TAG

## Description
TAG supports multiple BC platform versions in a single source tree using the CLEAN preprocessor symbols `CLEAN18`, `CLEAN19`, `CLEAN20`, `CLEAN22`, `CLEAN23`, `CLEAN24`. The canonical use is in `OnInsert` triggers that need the modern `Codeunit "No. Series"` (BC24+) on new builds and the legacy `Codeunit NoSeriesManagement` on older builds. The build defines the symbol matching the target BC major version; code branches on `#if CLEAN24` … `#else` … `#endif` so the same source compiles cleanly against either API.

## Best Practice
Whenever TAG calls a renamed or replaced platform codeunit (No. Series being the canonical example), wrap the import + call in `#if CLEAN<N>` / `#else` / `#endif`. Declare the symbol name in `app.json` `preprocessorSymbols` or in AL-Go's per-buildMode conditional settings. Resolve obsolete branches and remove the `#if` once TAG drops support for the older version.

## Anti Pattern
Calling the modern API directly without an `#if` guard (older builds break), or leaving stale `#if CLEAN18` branches in the codebase after support for BC18 is dropped (rot — those branches are never compiled and silently diverge).
```

## Implementation order for Phase 4

1. Vendor BCQuality into `content/bcquality/microsoft/` and `community/` first.
2. Create the empty `content/bcquality/custom/knowledge/{style,api,upgrade}/` skeleton.
3. Drop the 8 articles above into the right domain folders (slug = filename without `.md`).
4. Run the vendored `validate-bcquality-frontmatter.py` on `custom/` to ensure they pass R01–R25.
5. Verify by running `/bcq-review-style` on a sample TAG-shaped diff — it should surface the TAG-layer findings and `suppressed[]` the corresponding Microsoft-layer files where contradictions exist.

## Source files (preserved in `tag-source/`)

| File | Articles derived |
|---|---|
| `tag-source/tag-naming.mdc` | 1, 2, 3, 4 |
| `tag-source/al-general.mdc` | 5, 6, 8 |
| `tag-source/codeunits.mdc` | 5, 6 |
| `tag-source/api-pages.mdc` | 7 |
| `tag-source/pages.mdc` | — (already covered by BCApps Microsoft layer for the non-TAG-specific bits) |
| `tag-source/tables.mdc` | — (already covered by BCApps Microsoft layer; TAG-specific bits like Field numbering ranges could become a 9th article if desired) |
| `tag-source/enums.mdc` | — (already covered by BCApps Microsoft layer) |
| `tag-source/reports.mdc` | — (largely template guidance, low value as remedial knowledge) |
