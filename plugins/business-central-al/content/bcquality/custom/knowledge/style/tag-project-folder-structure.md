---
bc-version: [all]
domain: style
keywords: [folder-structure, project-layout, repository, tag]
technologies: [al]
countries: [w1]
application-area: [all]
---

# TAG repositories use the per-object-type folder layout at the project root

## Description

TAG repositories use a flat, per-object-type folder layout at the project root, NOT the BCApps `src/<Module>/src/` convention. The canonical TAG layout is `API/` (API pages), `CodeUnit/` (codeunits), `controladdin/`, `Enums/`, `Page_Extension/`, `Pages/`, `permissionSets/`, `Profile/`, `Queries/`, `Reports/`, `Table_Extension/`, `tables/`, `TAGProject/` (project-management objects), `Translations/` (XLF), and `XMLport/`. This overrides BCQuality's Microsoft-layer expectation that AL apps follow the BCApps module-folder convention.

## Best Practice

When adding a new object to an existing TAG repository, drop it in the matching folder above and create the folder if it does not exist for that object type. When scaffolding a brand-new TAG app, recreate the same folder layout from day one so subsequent contributors can navigate by intuition.

## Anti Pattern

Introducing a `src/<FeatureName>/` BCApps-style subtree inside a TAG repository, or scattering files across ad-hoc folder names like `Misc/` or `Other/`. Both break the convention that lets reviewers find any object by knowing only its type.
