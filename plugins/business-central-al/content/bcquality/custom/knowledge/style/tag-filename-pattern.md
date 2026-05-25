---
bc-version: [all]
domain: style
keywords: [filename, file-naming, verosoft, tag]
technologies: [al]
countries: [w1]
application-area: [all]
---

# TAG AL files use the [ObjectType] [ObjectID] - TAG [Name].al pattern

## Description

TAG follows a numeric-ID-first filename convention: every `.al` file is named `[ObjectType] [ObjectID] - TAG [ObjectName].al`. Examples are `Table 70016325 - TAG Key Safe.al`, `Page 23085760 - TAG Key Safe List.al`, and `Codeunit 70015921 - TAG Evaluate AutoPlan.al`. This overrides the BCQuality default (`<Object>.<Type>.al` as used in Microsoft BCApps under `file-name-object-type-pattern.md`). The leading object type and ID make the file's identity obvious in the file tree and in code-review diffs.

## Best Practice

Name new files exactly `[Type] [ID] - TAG [Name].al`. For API pages, the entity name uses camelCase inside the object's internal name but PascalCase in the file name, for example `Page 23085779 - TAG API Key Safes.al`. Existing TAG files already follow the convention. Extending the codebase means matching what is there.

## Anti Pattern

Naming a new TAG file `KeySafe.Table.al` (BCApps style) or `T70016325.al` (legacy NAV style). Both diverge from the TAG convention and make it impossible to scan the file tree by ID range.
