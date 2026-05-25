---
name: al-scaffold-module
description: Scaffold a new AL feature module following BCApps conventions (facade Codeunit + Internal Impl, four-tier permission sets, namespace, license header, XML docs) OR the consuming repo's existing per-object-type folder convention (e.g. TAG-style BC/{API,CodeUnit,Enums,...}). Use when adding a brand-new feature area to an AL project.
---

# AL Module Scaffolder

This skill creates a coherent set of AL files for a new feature module. It detects the consuming repo's existing project layout and adapts accordingly.

## Detect the project layout first

Before scaffolding ANYTHING, inspect the workspace to determine which layout applies. The two canonical shapes:

### Layout A — BCApps module-folder convention

```
<repo>/src/<Module>/
├── app.json
├── README.md
├── permissions/
│   ├── <Module>Objects.PermissionSet.al
│   ├── <Module>Read.PermissionSet.al
│   ├── <Module>Edit.PermissionSet.al
│   └── <Module>Admin.PermissionSet.al
└── src/
    ├── <PublicFacade>.Codeunit.al
    ├── <PublicFacade>Impl.Codeunit.al
    └── <SubFeature>/
        └── ...
```

Detect by: presence of `src/<ModuleName>/src/` substructures in the existing repo, files named `<Object>.<Type>.al`, namespaces like `<Publisher>.<Domain>.<SubDomain>`.

### Layout B — Per-object-type root convention (TAG style)

```
<repo>/
├── app.json
├── API/                  # API pages
├── CodeUnit/             # codeunits
├── controladdin/
├── Enums/
├── Page_Extension/
├── Pages/
├── permissionSets/
├── Profile/
├── Queries/
├── Reports/
├── Table_Extension/
├── tables/
├── TAGProject/
├── Translations/
└── XMLport/
```

Detect by: presence of `BC/` or root-level folders named `tables/`, `Pages/`, `CodeUnit/`, `API/`, etc., and files named `[ObjectType] [ObjectID] - <Prefix> [Name].al`.

### Layout C — Flat or other

When neither pattern is unambiguous, ASK the user which layout to follow. Never invent a third layout in a repo that already has files.

## Detection routine

1. List the top-level folders inside the project root (where `app.json` lives).
2. If folders named `tables/`, `Pages/`, `CodeUnit/`, `API/` exist → Layout B.
3. Else if folders matching `src/<PascalCase>/src/` exist → Layout A.
4. Else if no `.al` files exist anywhere → ASK the user; default Layout A for new BCApps-style projects, Layout B for new TAG-style projects.
5. Else ASK the user explicitly which layout they want.

Sample 2–3 existing `.al` files to detect:

- File naming pattern (`<Object>.<Type>.al` vs `[Type] [ID] - <Prefix> [Name].al` vs other).
- Object name prefix (e.g. `"TAG "` for TAG; none for plain BCApps).
- Procedure parameter naming (`pName` for TAG; no prefix for BCApps).
- License header text.

## Gather inputs from the user

For both layouts, ask:

- **Module name** — short, ≤ 30 char compatible (e.g. `Notifications`, `KeySafe`).
- **Publisher** — read from `app.json` if available; confirm.
- **Object ID range** — confirm the user's allocated range (e.g. TAG's `70015000..70016999` for non-API, `23085634..23085783` for API). Never sample from Microsoft's reserved ranges.
- **Mandatory affix** — read from `.AL-Go/settings.json` → `appSourceCopMandatoryAffixes` if present. For TAG: `"TAG "` (with trailing space).
- **Initial scope** — does the module need: a facade codeunit? a table? a list page? a card page? permission sets? an API page? an enum? an interface?
- **Namespace path** — read from existing `.al` files. For BCApps style: `<Publisher>.<Domain>.<SubDomain>`. For TAG style: typically not used historically — confirm with user before adding.

## Layout A scaffold (BCApps style)

Generate this tree under `src/<ModuleName>/`:

### `app.json` (one per module — when the repo is multi-app)

When the repo bundles modules into ONE app (single `app.json` at the project root), skip this; just contribute files into the existing app's folders.

When each module ships as its own app (BCApps system app style):

```json
{
    "id": "<generate guid>",
    "name": "<ModuleName>",
    "publisher": "<Publisher>",
    "version": "1.0.0.0",
    "brief": "<one-line description>",
    "description": "<short description>",
    "platform": "<repo's platform version>",
    "application": "<repo's application version>",
    "target": "OnPrem",
    "idRanges": [{ "from": <from>, "to": <to> }],
    "features": ["TranslationFile", "GenerateCaptions"],
    "resourceExposurePolicy": {
        "allowDebugging": true,
        "allowDownloadingSource": true,
        "includeSourceInSymbolFile": true,
        "applyToDevExtension": true
    },
    "dependencies": []
}
```

### `README.md`

Five-to-ten lines in plain English describing what the module does.

### Public facade + Internal Impl pair

The single most important BCApps pattern. The public surface is thin — every procedure delegates to the impl. Real logic lives in the impl.

**`src/<ModuleName>.Codeunit.al`** (public facade):

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) <Publisher>. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace <Publisher>.<Domain>.<ModuleName>;

/// <summary>
/// <one-paragraph module description>.
/// </summary>
codeunit <facade id> "<ModuleName>"
{
    Access = Public;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        Impl: Codeunit "<ModuleName> Impl";

    /// <summary>
    /// <description of this procedure>.
    /// </summary>
    /// <param name="...">...</param>
    /// <returns>...</returns>
    procedure DoSomething(): Boolean
    begin
        exit(Impl.DoSomething());
    end;

    // Integration events declared here, with [IntegrationEvent(false, false)]
}
```

**`src/<ModuleName>Impl.Codeunit.al`** (internal impl):

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) <Publisher>. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace <Publisher>.<Domain>.<ModuleName>;

codeunit <impl id> "<ModuleName> Impl"
{
    Access = Internal;
    Permissions = tabledata "<Table 1>" = rimd;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure DoSomething(): Boolean
    begin
        // real logic here
        exit(true);
    end;

    var
        ErrorMsgErr: Label '<error text>';
}
```

Convention: impl codeunit id = facade id - 1, OR a consecutive pair in the same hundred.

### Permission sets (when the module owns tables)

`permissions/<ModuleName>Objects.PermissionSet.al`:

```al
namespace <Publisher>.<Domain>.<ModuleName>;

permissionset <id> "<ModuleName> - Objects"
{
    Access = Internal;
    Assignable = false;

    Permissions =
        table "<Table 1>" = X,
        codeunit "<ModuleName>" = X,
        codeunit "<ModuleName> Impl" = X,
        page "<Page 1>" = X;
}
```

Plus `<ModuleName>Read.PermissionSet.al` (tabledata = r, includes Objects), `<ModuleName>Edit.PermissionSet.al` (tabledata = rim, includes Read), `<ModuleName>Admin.PermissionSet.al` (tabledata = rimd, includes Edit).

## Layout B scaffold (TAG style)

Generate files at the project root, each in its corresponding type folder. Filename pattern: `[ObjectType] [ObjectID] - [Prefix] [Name].al`.

For a module called `KeySafe` with prefix `TAG ` and IDs starting at 70016000:

```
tables/Table 70016000 - TAG Key Safe.al
CodeUnit/Codeunit 70015921 - TAG Key Safe Mgmt.al
Pages/Page 70016000 - TAG Key Safe List.al
Pages/Page 70016001 - TAG Key Safe Card.al
permissionSets/[prefix] Key Safe.permissionset.al
```

For an API page in the API range:

```
API/Page 23085779 - TAG API Key Safes.al
```

### TAG-style codeunit template

```al
codeunit 70015921 "TAG Key Safe Mgmt"
{
    trigger OnRun()
    begin
        // Main entry point logic
    end;

    var
        TAGSetup: Record "TAG Setup";

    procedure ProcessKeySafe(pKeySafeCode: Code[20]): Boolean
    var
        KeySafeRec: Record "TAG Key Safe";
    begin
        if not KeySafeRec.Get(pKeySafeCode) then
            exit(false);
        // ... logic ...
        exit(true);
    end;
}
```

Notes for TAG style specifically:

- All parameters prefixed with lowercase `p`.
- Variables follow the TAG vocabulary (`EquipmentRec`, `WOHeader`, `WOLine`, `TechRec`, `TAGSetup`, etc.).
- License header uses Verosoft Design INC. instead of Microsoft Corporation.
- Namespace declarations are typically NOT used (legacy convention).
- The facade + Impl pattern is generally NOT used in TAG — codeunits are flat with internal logic inline.

When in doubt about TAG conventions, defer to the existing TAG codebase and to the BCQuality `custom/` layer articles when Phase 4 ships.

## Layout B API page (TAG style — uses `verosoftdesign` / `tag` / `v1.0` triplet)

```al
page 23085779 "TAG API Key Safes"
{
    PageType = API;
    APIVersion = 'v1.0';
    APIPublisher = 'verosoftdesign';
    APIGroup = 'tag';
    EntityCaption = 'TAG API Key Safe';
    EntitySetCaption = 'TAG API Key Safes';
    EntityName = 'keySafe';
    EntitySetName = 'keySafes';
    SourceTable = "TAG Key Safe";
    ODataKeyFields = SystemId;
    Extensible = true;
    InsertAllowed = true;
    ModifyAllowed = true;
    DeleteAllowed = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId) { Editable = false; }
                field(systemCreatedAt; Rec.SystemCreatedAt) { Editable = false; }
                field(systemModifiedAt; Rec.SystemModifiedAt) { Editable = false; }
                field(code; Rec.Code) { }
                field(description; Rec.Description) { }
            }
        }
    }
}
```

The four system fields (`id`, `systemCreatedAt`, `systemModifiedAt`, and `lastModifiedDateTime` where applicable) MUST appear first in every TAG API page.

## After scaffolding

1. Update `.AL-Go/settings.json` if the new files live in a new project folder (add to `appFolders`).
2. Run `/al-symbols` to refresh symbols if the new objects reference platform symbols not yet pulled.
3. Run `/al-compile` to confirm the scaffold compiles cleanly.
4. Run `/al-build` with `${CodeCop}` and `${AppSourceCop}` analyzers (or the user's `ruleset.json`) to validate against the quality bar.
5. When the user wants tests, follow up with `/al-add-test-app` (Phase 2) or `/scaffold-test-codeunit` directly.

## Safety rules

- **Never generate IDs outside the user's stated range.** If the user has not provided a range, ASK.
- **Never use a reserved Microsoft namespace** (`Microsoft.*`, `System.*`) unless the consuming repo IS microsoft/BCApps.
- **Never invent a new folder layout** in a repo that already has one — match the existing convention.
- **Never invent a new object name prefix** in a repo whose `appSourceCopMandatoryAffixes` declares one — use the declared affix.
- **Never skip the license header** — pull it from an existing file in the repo.
