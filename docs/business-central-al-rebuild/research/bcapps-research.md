# BCApps Research — Microsoft `microsoft/BCApps` as a Reference Codebase for AL Plugin Authoring

> Generated: 2026-05-25 against `main` (BC 29.0). Repo: <https://github.com/microsoft/BCApps>
> Local clone used for citation line numbers: `git clone --depth 1 https://github.com/microsoft/BCApps` (commit fetched May 2026, release "Update 28.1 for Dynamics 365 Business Central 2026 Release Wave 1").

---

## 1. Executive summary

`microsoft/BCApps` is the public, MIT-licensed Microsoft repository that ships the **System Application**, **Business Foundation**, and the **Developer Tools** (Test Framework / Test Runner, Library Assert, Performance Toolkit, AI Test Toolkit, Red Team Scan). It is built end-to-end on **AL-Go for GitHub** and contains all the analyzer rulesets, AppSourceCop/CodeCop/UICop/PTECop configuration, build scripts, and CODEOWNERS that Microsoft uses internally. In short: it is the production-grade reference for "how Microsoft writes AL today."

For a Cursor plugin that wants to "crawl the best AL codebase in the world" this repo offers four distinct high-value extractions, in priority order:

1. **The rulesets in `src/rulesets/`** — the *official* AL analyzer rulesets that ship Microsoft's modules. They are the de-facto quality bar; bundling them (or the exception JSON) in the plugin lets users pin lint behaviour to Microsoft's own bar.
2. **`tools/Code Review/instructions/*.md`** — Microsoft already published six domain-specialised AI code review prompts (security, performance, style, accessibility, upgrade, privacy), each ~600–1000 lines, with concrete *bad* / *good* AL code blocks. These map almost 1:1 to Cursor skills or rules.
3. **`tools/al-docs-plugin/`** — Microsoft's own Anthropic-Skills-flavoured plugin for *documenting* AL codebases. Already in SKILL.md format with sub-skills (init/update/audit). The user's plugin can fork / inline this.
4. **System Application source patterns** — the canonical *facade Codeunit (`Access = Public`) → `Impl` Codeunit (`Access = Internal`)* pattern, `InherentEntitlements = X`, `InherentPermissions = X`, integration events declared on the facade, namespaced object names, XML-doc comments, label suffix conventions (`Err`, `Lbl`, `Tok`, `Msg`, `Qst`, `Txt`), and rigorous Given/When/Then test style.

Repository scale (commit fetched May 2026):
- ~**116 modules** in `src/System Application/App/` (each a self-contained AL app with its own `app.json`).
- **6** developer tool apps under `src/Tools/`.
- **7** AL-Go projects under `build/projects/` (Apps W1, Business Foundation Tests, Performance Toolkit Tests, System Application, System Application Modules, System Application Tests, Test Stability Tools).
- ~22 GitHub Actions workflows under `.github/workflows/`.

---

## 2. Repository layout

Top-level (from `README.md` and `git ls-tree`):

```
BCApps/
├── README.md
├── CONTRIBUTING.md
├── LOCAL_DEV_ENV.md
├── CODE_OF_CONDUCT.md
├── CODEOWNERS                 # 42 lines — useful as a map of which teams own which folders
├── SECURITY.md
├── SUPPORT.md
├── LICENSE                    # MIT
├── build.ps1
├── build/
│   ├── Packages.json
│   ├── projects/              # AL-Go projects — one per buildable unit
│   │   ├── Apps (W1)/.AL-Go/settings.json
│   │   ├── Business Foundation Tests/.AL-Go/settings.json
│   │   ├── Performance Toolkit Tests/.AL-Go/settings.json
│   │   ├── System Application/.AL-Go/settings.json          # builds the whole stack as a single bundle
│   │   ├── System Application Modules/.AL-Go/settings.json  # builds each module as its own app
│   │   ├── System Application Tests/.AL-Go/settings.json
│   │   └── Test Stability Tools/.AL-Go/settings.json
│   └── scripts/               # PowerShell module + DevEnv launcher (NewDevEnv.ps1)
├── src/
│   ├── Apps/                  # 1st-party apps shipped from BCApps (W1)
│   │   └── W1/                # E.g. EDocumentConnectors, PowerBIReports, Shopify, ...
│   ├── Business Foundation/
│   │   ├── App/               # Source (NoSeries, AuditCodes, Entitlements, Permissions, NoSeriesCopilot)
│   │   ├── Test/
│   │   └── Test Library/
│   ├── System Application/
│   │   ├── App/               # 116 modules each w/ app.json, src/, permissions/, README.md
│   │   ├── Partner Test/
│   │   ├── Test/
│   │   └── Test Library/
│   ├── Tools/
│   │   ├── AI Test Toolkit/
│   │   ├── Performance Toolkit/
│   │   ├── Red Team Scan/
│   │   └── Test Framework/    # Test Runner + Test Libraries (Any, Assert, Permissions Mock, Variable Storage, LibraryAgent)
│   ├── rulesets/              # ⭐ HIGH-PRIORITY: the analyzer rulesets
│   ├── BusinessFoundation.code-workspace
│   └── SystemApplication.code-workspace
├── tools/
│   ├── Code Review/           # ⭐ Microsoft's own AI code-review prompts (security/perf/style/...)
│   └── al-docs-plugin/        # ⭐ Microsoft's AL documentation skill (init/update/audit)
└── .github/
    ├── AL-Go-Settings.json    # Root AL-Go configuration
    ├── workflows/             # 22 workflows (CICD, PullRequestHandler, _BuildALGoProject, ...)
    ├── PULL_REQUEST_TEMPLATE.md
    ├── dependabot.yml
    └── labeler.yml
```

### Per-module structure (System Application)

Every module under `src/System Application/App/<Module>/` is itself an AL app. Sample tree:

```
src/System Application/App/Email/
├── app.json                   # full app manifest (id, version, dependencies, internalsVisibleTo, idRanges)
├── README.md                  # short module description
└── src/
│   ├── Account/               # Folder per feature area (Inbox, Outbox, Sent, ...)
│   ├── Connector/
│   ├── Email/
│   │   ├── Email.Codeunit.al           # Public facade (codeunit 8901)
│   │   ├── EmailImpl.Codeunit.al       # Internal impl (codeunit 8900)
│   │   ├── EmailDispatcher.Codeunit.al
│   │   ├── EmailRelatedRecord.Table.al
│   │   └── ...
│   ├── Message/
│   ├── RateLimit/
│   └── Scenario/
└── permissions/
    ├── EmailAdmin.PermissionSet.al
    ├── EmailEdit.PermissionSet.al
    ├── EmailObjects.PermissionSet.al
    └── EmailRead.PermissionSet.al
```

> **Convention takeaway**: every Microsoft module has `app.json` + `src/` + (optionally) `permissions/` + `README.md` at its root. Sub-feature folders under `src/` group cohesive AL objects (codeunits, tables, pages, enums, interfaces) using PascalCase folder names with spaces ("Rate Limit", "View Policy").

---

## 3. The rulesets — HIGH PRIORITY (recommended to bundle in the plugin)

Location: `src/rulesets/`. The `README.md` calls these out by name as **"the rulesets for building the applications"**.

| File | Lines | Purpose |
|------|-------|---------|
| `ruleset.json` | 83 | Master "shipped apps" ruleset. Composes the other 6 with `generalAction = Error`. |
| `Analyzer.ruleset.json` | 4 000 | Every analyzer rule set to `Error` (zero exceptions in the file). |
| `CodeCop.ruleset.json` | 4 004 | All CodeCop rules to `Error`, with **3** exceptions. |
| `AppSourceCop.ruleset.json` | 4 015 | All AppSourceCop rules to `Error`, with **14** exceptions. |
| `UICop.ruleset.json` | 4 003 | All UICop rules to `Error`, with **2** exceptions. |
| `PTECop.ruleset.json` | 4 010 | All PTECop rules to `Error`, with **9** exceptions. |
| `Compiler.ruleset.json` | 40 002 | Every compiler diagnostic to `Error`, with **2** exceptions. |
| `internal.module.ruleset.json` | 33 | Variant of `ruleset.json` for unshipped, internal modules (silences AppSource manifest rules). |
| `minorrelease.ruleset.json` | 25 | Variant of `ruleset.json` for minor releases — re-promotes a few rules to `Error` (`AS0077`, `AS0078`, `AS0102`). |

### 3.1 `ruleset.json` (verbatim)

The master ruleset that AL-Go points at via `rulesetFile`. Reproduced verbatim because it is small and the highest-value file to mirror:

```json
{
  "name": "Ruleset for shipped apps",
  "description": "This ruleset applies to shipped apps.",
  "generalAction": "Error",
  "includedRuleSets": [
    { "action": "Error", "path": "./Analyzer.ruleset.json" },
    { "action": "Error", "path": "./AppSourceCop.ruleset.json" },
    { "action": "Error", "path": "./CodeCop.ruleset.json" },
    { "action": "Error", "path": "./Compiler.ruleset.json" },
    { "action": "Error", "path": "./PTECop.ruleset.json" },
    { "action": "Error", "path": "./UICop.ruleset.json" }
  ],
  "rules": [
    { "id": "AS0023", "action": "Warning", "justification": "Needed to allow for BigInteger entry nos." },
    { "id": "AS0077", "action": "None",    "justification": "Adding a var modifier in events should be allowed in main, as it only will break the runtime behavior of extensions subscribing to it when used in hotfix scenarios." },
    { "id": "AS0138", "action": "None",    "justification": "TODO(#572306) - (see PTE0026) This will require a multi-release effort." },
    { "id": "AS0139", "action": "None",    "justification": "TODO(#595767) - This will be enabled after branching to BC 27." },
    { "id": "AS0146", "action": "Warning", "justification": "Needed to allow for BigInteger entry nos." },
    { "id": "AS0147", "action": "Warning", "justification": "Needed to allow for BigInteger entry nos." },
    { "id": "PTE0026","action": "None",    "justification": "TODO(#572306) - (see AS0138) This will require a multi-release effort." },
    { "id": "AL0284", "action": "Warning", "justification": "Needed to allow for BigInteger entry nos." },
    { "id": "AL0662", "action": "Warning", "justification": "Needed to allow for BigInteger entry nos." },
    { "id": "AL0920", "action": "None",    "justification": "TODO(#632280) - This will be enabled after a few violations are fixed." }
  ]
}
```

Source: <https://github.com/microsoft/BCApps/blob/main/src/rulesets/ruleset.json>

### 3.2 Default behaviour — "everything is an Error"

Each cop ruleset is *generated* with all of its rule IDs explicitly set to `"action": "Error"`. Microsoft does not soften the default — the only deviations are listed below. **The single most important takeaway** for a plugin is: the Microsoft AL quality bar is "every analyzer rule is an error unless explicitly silenced".

### 3.3 CodeCop exceptions (3 rules)

| Rule | Action | Justification |
|------|--------|---------------|
| `AA0072` | `None` | Naming rule: variables/parameters must be suffixed with the type or object name. **Turned off globally.** |
| `AA0234` | `None` | Missing tooltips on table fields. Too many existing violations to enforce; code action incoming. |
| `AA0248` | `None` | Missing `'this.'` qualification on members. Turned off globally — not enforced. |

### 3.4 AppSourceCop exceptions (14 rules)

| Rule | Action | Justification |
|------|--------|---------------|
| `AS0008` | `None` | Reserved Microsoft/System namespaces may be used (Microsoft owns them). |
| `AS0053` | `None` | Compilation target requirement (SaaS) skipped — BCApps targets OnPrem. |
| `AS0054` | `None` | Mandatory affix not required. |
| `AS0055` | `None` | Country list not required. |
| `AS0060` | `None` | Unsafe methods may be invoked. |
| `AS0081` | `None` | `internalsVisibleTo` is allowed (used heavily for tests). |
| `AS0084` | `None` | ID range constraints don't apply to 1st-party apps. |
| `AS0085` | `None` | The `application` property requirement skipped; explicit dependencies are used. |
| `AS0092` | `None` | Mandatory App Insights resource skipped. |
| `AS0100` | `None` | `application` property requirement skipped. |
| `AS0116` | `None` | Cannot be an error — validates table moves. |
| `AS0131` `AS0132` `AS0133` | `None` | Schema additive changes are explicitly allowed. |

### 3.5 UICop exceptions (2 rules)

| Rule | Action | Justification |
|------|--------|---------------|
| `AW0006` | `None` | Pages/reports should use `UsageCategory` + `ApplicationArea` to be searchable. Not enforced. |
| `AW0008` | `None` | Web client only supports Repeater on List/ListPart/Worksheet pages. Not enforced as error. |

### 3.6 PTECop exceptions (9 rules)

| Rule | Action | Justification |
|------|--------|---------------|
| `PTE0001` | `None` | Object ID must be in free range — BCApps uses system ranges. |
| `PTE0002` | `None` | PTE ID ranges don't apply to 1st-party apps. |
| `PTE0005` | `None` | SaaS compile target — N/A. |
| `PTE0006` | `None` | Encryption key functions allowed (used by Cryptography Management). |
| `PTE0010` | `None` | The 50-char EMRS name limit doesn't apply. |
| `PTE0012` | `None` | Test assertion functions in non-test contexts allowed. |
| `PTE0013` | `None` | Entitlements may be defined (the Entitlements module). |
| `PTE0021` | `None` | Reserved namespaces allowed for Microsoft. |
| `PTE0024` | `None` | Moved symbols allowed because PTECop runs across the whole codebase. |

### 3.7 Compiler exceptions (2 rules out of 40 000 entries)

| Rule | Action | Justification |
|------|--------|---------------|
| `AL0678` | `None` | Informational diagnostic on obsolete-symbol name conflicts. |
| `AL0797` | `None` | Tables are moved from BaseApp to BCApps. |

### 3.8 The "internal module" and "minor release" overlays

`internal.module.ruleset.json` — silences the four AppSource manifest checks (`AS0014`, `AS0015`, `AS0051`, `AS0052`) for modules that are *not* shipped individually (they are bundled into the System Application binary). This is the ruleset that `build/projects/System Application Modules/.AL-Go/settings.json` points at.

`minorrelease.ruleset.json` — re-promotes three rules to `Error` for minor releases, because adding/removing `var` on events/procedures or adding a return type is a *runtime* breaking change even though the compiler is permissive about them otherwise:
- `AS0077`, `AS0078`, `AS0102`.

### 3.9 Recommendations for the plugin

- **Bundle the seven ruleset JSON files** (or at least `ruleset.json` + exceptions of each) as a "Microsoft canonical rulesets" pack in the plugin.
- Offer a Cursor command `Use Microsoft analyzer rulesets` that drops the files into the user's project and updates the AL-Go / `.vscode/settings.json` to point at them.
- Surface the exception list as a knowledge base for the AI ("These rules are intentionally relaxed by Microsoft because…").

---

## 4. Contribution workflow & local dev (`CONTRIBUTING.md`, `LOCAL_DEV_ENV.md`)

### 4.1 PR workflow (verbatim summary from `CONTRIBUTING.md`)

1. **An approved GitHub issue must exist before a PR can be created.** PRs unlinked to an approved issue are rejected. Use `Fixes #123` in the PR description.
2. Approval requires either:
   - **(A)** A small bug fix / paper-cut from the contributor's day-to-day pain, or
   - **(B)** A new capability backed by a BCIdeas idea tagged "open for contribution" by a Microsoft PM (<http://aka.ms/bcideas>).
3. CLA-bot enforces the Microsoft Contributor License Agreement on the first PR.
4. PR must:
   - Pass all required status checks (built via AL-Go).
   - Resolve all conversations.
   - Receive approval from a CODEOWNER (either Microsoft or community).
5. Microsoft performs a **final validation** (release notes, scope check, "truly done/done?") before merging.
6. Merged PRs ship with the next release of the product.

### 4.2 Local dev environment (`LOCAL_DEV_ENV.md`)

Prerequisites:
- **Docker Desktop for Windows containers**.
- **BcContainerHelper** PowerShell module: `Install-Module BCContainerHelper -AllowPrerelease`.

The canonical bootstrap command — from `LOCAL_DEV_ENV.md`:

```powershell
# Create container + configure launch.json/settings.json (no apps published):
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev'

# Create container + compile + publish a single project:
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' `
    -ProjectPaths '.\src\System Application\App'

# Create container + compile + publish all System Application apps + tests:
.\build\scripts\DevEnv\NewDevEnv.ps1 -ContainerName 'BCApps-Dev' `
    -ProjectPaths '.\src\System Application\*'
```

That script writes the default VS Code settings from `build/scripts/DevEnv/DefaultSettings.json`:

```json
{
  "chat.useCustomizationsInParentRepositories": true,
  "al.codeAnalyzers": [
    "${CodeCop}",
    "${AppSourceCop}",
    "${PerTenantExtensionCop}",
    "${UICop}"
  ],
  "al.enableCodeActions": false,
  "al.enableCodeAnalysis": true,
  "al.incrementalBuild": true,
  "[al]": { "editor.semanticHighlighting.enabled": true },
  "editor.codeLens": false,
  "editor.formatOnSave": true
}
```

> Plugin opportunity: provide a command `Initialize BCApps-style settings.json` that writes the above plus a `"al.ruleSetPath"` entry pointing at the rulesets bundled in §3.

### 4.3 CODEOWNERS — high-level ownership map

`/CODEOWNERS` (42 lines) acts as a partial taxonomy of the repo. Highlights:

| Path | Owner team |
|------|-----------|
| `*` (default) | `@microsoft/dynamics-365-business-central` |
| `/src/rulesets/` | `@microsoft/d365-bc-app-rulesets` |
| `/src/System\ Application/App/AI` | `@microsoft/d365-bc-copilot-toolkit @microsoft/dynamics-smb-developertools` |
| `/src/System\ Application/App/Agent` | `@microsoft/dynamics-smb-developertools` |
| `/src/System\ Application/App/Extension\ Management` | `@microsoft/dynamics-smb-developertools` |
| `dotnet.al` | `@microsoft/d365-bc-app-security` |
| `*.Entitlement.al` | `@microsoft/d365-bc-app-permissions` |
| `app.json` | `@microsoft/d365-bc-engineering-systems @microsoft/d365-bc-app-required` |
| `.AL-Go/`, `*.ps1`, `/.github`, `/build`, `/CODEOWNERS` | `@microsoft/d365-bc-engineering-systems` |
| `/tools/Code\ Review` | `@microsoft/d365-bc-code-review-agent` |

> This file is itself a useful artifact for the plugin's "Where does X live?" answer.

---

## 5. System Application module structure conventions

A typical module looks like:

```
<ModuleName>/
├── app.json                      # required — see §8
├── README.md                     # 1–10 lines, plain English
├── permissions/                  # optional, but most non-trivial modules have it
│   ├── *Objects.PermissionSet.al   # All execute permissions
│   ├── *Read.PermissionSet.al      # tabledata = r
│   ├── *Edit.PermissionSet.al      # tabledata = rim
│   └── *Admin.PermissionSet.al     # tabledata = rimd
└── src/
    ├── <PublicCodeunit>.Codeunit.al   # Access = Public, single-instance, thin
    ├── <PublicCodeunit>Impl.Codeunit.al # Access = Internal, all real logic
    ├── *.Table.al
    ├── *.Page.al
    ├── *.Enum.al
    ├── *.Interface.al              # When extensibility is exposed via interfaces
    └── <feature subfolders>/
```

### 5.1 Naming conventions observed

- **File name**: `<ObjectName>.<ObjectType>.al` — for example `EmailImpl.Codeunit.al`, `Email.Codeunit.al`, `EmailAccount.Table.al`, `EmailAccounts.Page.al`, `EmailConnector.Enum.al`, `SymmetricAlgorithm.Interface.al`, `EmailAdmin.PermissionSet.al`. (See style review at `tools/Code Review/instructions/style.md:86-100`.)
- **Object name**: PascalCase, ≤30 chars; for the public facade this is usually the bare feature name (`"Email"`, `"Azure Key Vault"`, `"No. Series"`, `"Filter Tokens"`, `"Headlines"`, `RSA`), and the impl gets the same name + `" Impl."` (note the trailing dot is common — `"Azure Key Vault Impl."`, `"No. Series - Impl."`).
- **Namespace** declared at the top of every file, mapping to its feature area:
  - `namespace System.Email;`
  - `namespace System.Azure.KeyVault;`
  - `namespace System.Security.Encryption;`
  - `namespace System.Visualization;`
  - `namespace System.Text;`
  - `namespace Microsoft.Foundation.NoSeries;` (Business Foundation uses `Microsoft.*`)
- **`using` imports** at the top, after namespace declaration. See `EmailImpl.Codeunit.al:6-12`.
- **License header**: every `.al` file begins with the standard 4-line MIT block:
  ```
  // ------------------------------------------------------------------------------------------------
  // Copyright (c) Microsoft Corporation. All rights reserved.
  // Licensed under the MIT License. See License.txt in the project root for license information.
  // ------------------------------------------------------------------------------------------------
  ```

### 5.2 The facade + Impl pattern (canonical)

This is the single most important pattern in BCApps. Every public-facing feature is split into two codeunits:

| Aspect | Public facade | Internal `Impl` |
|--------|---------------|-----------------|
| Object name | `Email` (id 8901) | `"Email Impl"` (id 8900) |
| `Access` | `Public` | `Internal` |
| `SingleInstance` | usually `true` | usually `true` |
| `InherentEntitlements` | `X` | `X` |
| `InherentPermissions` | `X` | `X` |
| `Permissions = tabledata X = rimd` | Not declared (it just forwards) | Declared here |
| Procedures | Just `exit(Impl.X(...))` | Real logic |
| Integration events | Declared here as `internal procedure` with `[IntegrationEvent(...)]` | Subscribed/raised |
| Labels | None | All `Label` definitions live here |

Example pair:
- Facade: `src/System Application/App/Email/src/Email/Email.Codeunit.al:11-21` (787 lines, all thin wrappers + events).
- Impl: `src/System Application/App/Email/src/Email/EmailImpl.Codeunit.al:14-29` (1 116 lines).

Other canonical examples worth citing:
- `src/System Application/App/Azure Key Vault/src/AzureKeyVault.Codeunit.al:11-79` — only 79 lines, four procedures.
- `src/Business Foundation/App/NoSeries/src/Single/NoSeries.Codeunit.al:12-21` (codeunit 310) — Microsoft.Foundation example.
- `src/System Application/App/Filter Tokens/src/FilterTokens.Codeunit.al:11-19` — facade-and-events file with no impl-forwarding noise.

### 5.3 Permission set conventions

Every module that owns tables ships four permission sets at the module root in `permissions/`:

| File | `Assignable` | `Access` | Contents |
|------|--------------|----------|----------|
| `<Module>Objects.PermissionSet.al` | `false` | `Internal` | `table X = X, page X = X, codeunit X = X, query X = X` — execute permissions for all objects. |
| `<Module>Read.PermissionSet.al`    | `false` | `Internal` | `tabledata = r`, `IncludedPermissionSets = "<Module> - Objects", "<related> - View"`. |
| `<Module>Edit.PermissionSet.al`    | `false` | `Internal` | `tabledata = rim`, includes `*Read`. |
| `<Module>Admin.PermissionSet.al`   | `false` | `Internal` | `tabledata = rimd`, includes `*Edit`. |

Example: `src/System Application/App/Email/permissions/EmailObjects.PermissionSet.al:8-56` (the "Email - Objects" set, listing every object in the module with `= X`).

### 5.4 XML doc comments on every public procedure

Every public-facing procedure has the standard `<summary>`, `<param>`, `<returns>`, `<remarks>` XML tags. The facade in `src/System Application/App/Email/src/Email/Email.Codeunit.al:14-46` is a textbook example — every overload of `SaveAsDraft` carries its own block.

Integration events get the same treatment plus `<remarks>` describing the contract:
```
src/System Application/App/Email/src/Email/Email.Codeunit.al:733-742
[IntegrationEvent(false, false)]
internal procedure OnFindRelatedAttachments(...) begin end;
```

### 5.5 Labels and string constants

Every label has a suffix indicating its usage:

| Suffix | Used with | Example |
|--------|-----------|---------|
| `Err` | `Error(...)` | `MissingSecretErr: Label 'The secret %1 is either missing or empty.', Comment = '%1 = Secret Name.';` |
| `Msg` | `Message(...)` | `EmailMessageDoesNotExistMsg: Label '...';` |
| `Qst` | `Confirm(...)` / `StrMenu` | `PolicyNotEnabledQst: Label 'The retention policy is not enabled. Would you like to enable it now?';` |
| `Lbl` | Captions/tooltips | `EmailCategoryLbl: Label 'Email', Locked = true;` |
| `Tok` | Locked tokens (codes/URLs/GUIDs) | `EmailViewPolicyLbl: Label 'Email View Policy', Locked = true;` |
| `Txt` | Telemetry text | `TelemetryRetrieveEmailsUsedTxt: Label 'Retrieving emails is used', Locked = true;` |

Source (one chunk of dozens): `src/System Application/App/Email/src/Email/EmailImpl.Codeunit.al:31-55`.

Rules to enforce:
- `Comment = '%1 = ...'` is mandatory whenever a label contains placeholders (this is CodeCop / `AA0237` family).
- `Locked = true` is mandatory for any string that should not be translated (URLs, telemetry strings, technical keys).

---

## 6. Test patterns

### 6.1 Test app layout

```
src/System Application/Test/                  # Test app (app.json id 0d60b215-...)
├── app.json                                  # Depends on System Application + Library Assert + Any + Library Variable Storage + Permissions Mock
├── Email/
│   ├── app.json                              # Note: each test feature is its own sub-app (idRanges share 130000-139999)
│   └── src/
│       ├── EmailTest.Codeunit.al             # codeunit 134685 "Email Test" Subtype = Test
│       ├── EmailAccountsTest.Codeunit.al
│       └── Mocks/
└── ...
src/System Application/Test Library/          # Reusable test mocks ("connector mocks", scenario mocks)
└── Email/src/
    ├── ConnectorMock.Codeunit.al
    ├── EmailScenarioMock.Codeunit.al
    └── TestEmailConnector.Codeunit.al
```

`src/System Application/Test/app.json:14-50` lists the canonical test dependencies:
- `Library Assert` (id `dd0be2ea-...`)
- `Any` (id `e7320ebb-...`) — random value helper.
- `Library Variable Storage` (id `5095f467-...`) — variable bag for handlers.
- `Permissions Mock` (id `40860557-...`) — `PermissionsMock.Set('<role>')` to test permission checks.

### 6.2 Test codeunit conventions

Anatomy of a test codeunit (taken from `src/System Application/Test/Email/src/EmailTest.Codeunit.al:16-42`):

```al
codeunit 134685 "Email Test"
{
    Subtype = Test;
    Permissions = tabledata "Email Message" = rd,
                  tabledata "Email Outbox"  = rimd,
                  tabledata "Sent Email"    = rid;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit "Library Assert";
        Email: Codeunit Email;
        PermissionsMock: Codeunit "Permissions Mock";
        EmailMessageDoesNotExistMsg: Label '...', Locked = true;
```

Standard rules in evidence:
- `Subtype = Test` on every test codeunit.
- `EventSubscriberInstance = Manual` so that subscribers don't fire unless the test explicitly binds.
- `Permissions = tabledata ... = rd` declared at the codeunit, scoped tight.
- A single `Assert: Codeunit "Library Assert"` variable — the codeunit ID is **130002**, and `Library Assert/app.json` calls out: *"In test code Library Assert should be used to compare the values and throw errors. TESTFIELD and ERROR must not be used in test code."*

### 6.3 Test attributes

Real procedure header pattern (`EmailTest.Codeunit.al:43-46`):

```al
[Test]
[Scope('OnPrem')]
[TransactionModel(TransactionModel::AutoRollback)]
procedure NonExistingEmailMessageFailsTest()
```

`HandlerFunctions` is used heavily to seal dialogs/messages:

```al
[Test]
[HandlerFunctions('CloseEmailEditorHandler')]
procedure OpenMessageInEditorTest()
```

Supported handler attributes seen in `EmailTest.Codeunit.al`:

| Attribute | Purpose |
|-----------|---------|
| `[MessageHandler]` | swallows `Message(...)` calls |
| `[ConfirmHandler]` | answers `Confirm(...)` prompts |
| `[ModalPageHandler]` | drives a modally-run page |
| `[PageHandler]` | drives non-modal pages |
| `[StrMenuHandler]` | answers `StrMenu(...)` |
| `[SendNotificationHandler]` | swallows `Notification.Send()` |

Reference: `src/System Application/Test/Email/src/EmailTest.Codeunit.al:2052-2095`.

### 6.4 Given/When/Then narrative

Microsoft uses inline comments to make tests self-document. The shape (`EmailTest.Codeunit.al:50-66`):

```al
procedure NonExistingEmailMessageFailsTest()
begin
    // [Scenario] User cannot save as draft, enqueue, send or open a non-existing email message
    PermissionsMock.Set('Email Edit');

    // [Given] Create an Email Message and delete the underlying record
    CreateEmail(EmailMessage);
    Assert.IsTrue(Message.Get(EmailMessage.GetId()), 'The record should have been created');
    Message.Delete();
    Assert.IsFalse(EmailMessage.Get(EmailMessage.GetId()), 'The email should not exist');

    // [When] Saving a non-existing email message as draft
    ClearLastError();
    asserterror Email.SaveAsDraft(EmailMessage);

    // [Then] An error occurs
    Assert.ExpectedError(EmailMessageDoesNotExistMsg);
    ...
```

Tags to enforce in a plugin: `[Scenario]`, `[Given]`, `[When]`, `[Then]` as inline `//` comments.

### 6.5 Library Assert vs `Assert` codeunit

There are *two* assert codeunits in the BC platform:
- **Assert (codeunit 9)** — the legacy Microsoft assert in the Base Application.
- **Library Assert (codeunit 130002, BCApps)** — the modern one Microsoft ships in BCApps under `src/Tools/Test Framework/Test Libraries/Assert`. Its `app.json` brief reads:
  > *"In test code Library Assert should be used to compare the values and throw errors. TESTFIELD and ERROR must not be used in test code."*

Plugin guidance: **always inject `Library Assert` (id 130002) as `Assert: Codeunit "Library Assert"`**, never use plain `TestField`/`Error` in tests.

### 6.6 Test Runner & Performance Toolkit

- **Test Runner** lives at `src/Tools/Test Framework/Test Runner/src/`. Key files: `TestRunnerMgt.Codeunit.al`, `TestSuiteMgt.Codeunit.al`, `ALTestSuite.Table.al`, `TestProfileManagement.Codeunit.al`.
- **Performance Toolkit** lives at `src/Tools/Performance Toolkit/App/`. The public surface is `codeunit 149003 "BCPT Test Context"` (`src/Tools/Performance Toolkit/App/src/BCPTTestContext.Codeunit.al:11`) which exposes `StartScenario`, `EndScenario`, `UserWait`. The convention is:
  ```al
  BCPTTestContext.StartScenario('Post sales order');
  // ... do work ...
  BCPTTestContext.EndScenario('Post sales order');
  ```

---

## 7. AL-Go configuration in BCApps (multi-project handling)

BCApps is the largest known AL-Go for GitHub repository and demonstrates how to scale AL-Go to a multi-project monorepo.

### 7.1 Root `.github/AL-Go-Settings.json` (highlights)

```json
{
  "$schema": "...AL-Go/Actions/.Modules/settings.schema.json",
  "type": "PTE",
  "templateUrl": "https://github.com/microsoft/AL-Go-PTE@preview",
  "bcContainerHelperVersion": "preview",
  "runs-on": "windows-latest",
  "artifact": "bcinsider/Sandbox/29.0.50627.0//latest",
  "country": "base",
  "useProjectDependencies": true,
  "incrementalBuilds": {
    "onPush": false,
    "onPull_Request": true,
    "onSchedule": false,
    "retentionDays": 30,
    "mode": "modifiedApps"
  },
  "repoVersion": "29.0",
  "conditionalSettings": [
    { "buildModes": ["Clean"],
      "settings": { "preprocessorSymbols": ["CLEAN25","CLEAN26","CLEAN27","CLEAN28","CLEAN29"] } },
    { "branches": ["main","releases/*.x"],
      "settings": { "buildModes": ["Clean"] } }
  ],
  "enableCodeCop": true,
  "enableAppSourceCop": true,
  "enablePerTenantExtensionCop": true,
  "enableUICop": true,
  "enableCodeAnalyzersOnTestApps": true,
  "rulesetFile": "../../../src/rulesets/ruleset.json",
  "fullBuildPatterns": [
    "build/*",
    "src/rulesets/*",
    ".github/workflows/PullRequestHandler.yaml",
    ".github/workflows/_BuildALGoProject.yaml"
  ],
  "PullRequestTrigger": "pull_request",
  ...
}
```

Things to highlight to the plugin:
- `useProjectDependencies: true` is what lets AL-Go honor cross-project dependencies between `System Application Modules`, `Apps (W1)`, etc.
- `incrementalBuilds.mode = "modifiedApps"` on PRs is what makes the multi-project build practical at this scale.
- `rulesetFile: "../../../src/rulesets/ruleset.json"` — the *relative* path from each AL-Go project to the master ruleset. (Recommendation: replicate this idiom in any large AL repo.)
- `fullBuildPatterns` forces a full rebuild when shared infra changes (`build/*`, `src/rulesets/*`) or when the build workflows themselves are edited.
- `conditionalSettings` shows how to layer `CLEAN<n>` preprocessor symbols only on `main` and `releases/*.x` branches, while feature branches get the lenient build.

### 7.2 Per-project `.AL-Go/settings.json`

Each AL-Go project has its own settings file under `build/projects/<Project>/.AL-Go/`. Two notable examples:

`build/projects/System Application/.AL-Go/settings.json` — bundles every System Application module into a single appFolders list and excludes tests; this is the "system application as one big app" build:

```json
{
  "projectName": "System Application, Business Foundation and Tools",
  "appFolders": [
    "../../../src/System Application/App",
    "../../../src/Business Foundation/App",
    "../../../src/Tools/AI Test Toolkit",
    "../../../src/Tools/Performance Toolkit/App",
    "../../../src/Tools/Test Framework/Test Libraries/*",
    "../../../src/Tools/Test Framework/Test Runner",
    "../../../src/Tools/Red Team Scan"
  ],
  "testFolders": [
    "../../../src/System Application/Test Library",
    "../../../src/Business Foundation/Test Library"
  ],
  "doNotRunTests": true,
  "useCompilerFolder": true,
  "doNotPublishApps": true,
  "ConditionalSettings": [
    { "branches": ["releases/*.[0-5]"], "settings": { "buildModes": ["Strict"] } }
  ]
}
```

`build/projects/System Application Modules/.AL-Go/settings.json` — builds **each module separately** (note the `*` glob) and uses the *internal* ruleset which silences AppSource manifest checks:

```json
{
  "projectName": "System Application Modules",
  "appFolders": [
    "../../../src/System Application/App/*",
    "../../../src/Business Foundation/App/*"
  ],
  "testFolders": [
    "../../../src/System Application/Test/*",
    "../../../src/System Application/Test Library/*",
    ...
  ],
  "useCompilerFolder": true,
  "doNotPublishApps": true,
  "rulesetFile": "../../../src/rulesets/internal.module.ruleset.json"
}
```

> **Insight for the plugin**: Microsoft runs *both* builds in CI. The first proves the bundle compiles; the second proves every module is independently compilable. This is a robust pattern for any AL workspace that ships as both a bundle and individual modules.

### 7.3 Workflows

`.github/workflows/` includes (notable subset):

| Workflow | Purpose |
|----------|---------|
| `CICD.yaml` | Master CI / publish |
| `PullRequestHandler.yaml` | PR validation entry-point |
| `_BuildALGoProject.yaml` | Reusable build per project (called by the others) |
| `CopilotPRReview.yaml` + `CopilotPRReviewRunner.yaml` | AI-driven PR review using the prompts under `tools/Code Review/` |
| `WorkitemValidation.yaml` | Verifies the PR is linked to an approved issue |
| `IncrementVersionNumber.yaml`, `UpdateBCArtifactVersion.yaml`, `UpdatePackageVersions.yaml` | Release automation |
| `VerifyAppChanges.yaml` | Diff-time guards for app.json schema |
| `RerunUnstableFailures.yaml`, `SubmitStabilityJobs.yaml` | Test stability infrastructure |
| `DeployReferenceDocumentation.yaml`, `DocumentationMaintenance.yaml` | ALDoc reference site |
| `scorecard-analysis.yml` | OpenSSF Scorecard supply-chain security |

---

## 8. `app.json` + AppSourceCop conventions

### 8.1 Required fields seen across samples

Sample fields and idRanges across 5 modules:

| Module | id | idRanges | Notable fields |
|--------|----|----------|----------------|
| **System Application (bundle)** | `63ca2fa4-4f03-4f2b-a480-172fef340d3f` | `1-9999` | `target: "OnPrem"`, `platform: "29.0.0.0"`, `features: ["TranslationFile","GenerateCaptions"]`, `resourceFolders: ["Resources/Files"]`, `resourceExposurePolicy: { allowDebugging: true, allowDownloadingSource: true, includeSourceInSymbolFile: true, applyToDevExtension: true }`. |
| **Email** | `9c4a2cf2-be3a-4aa3-833b-99a5ffd11f25` | `1-10000` | 17 declared dependencies, 2 `internalsVisibleTo` entries (Email Test + Email Test Library). |
| **Filter Tokens** | `dcfc6d73-8259-4595-ad3e-c2574fe2a197` | `[{41,41},{58,58}]` | Two single-value idRanges — modules can pin to specific object IDs. |
| **Headlines** | `f3f75070-7762-41f5-9947-043a50dc9fc7` | `[{1439,1439},{1470,1470},{1472,1472}]` | Three single-value ranges. |
| **Performance Toolkit** | `75f1590f-55c5-4501-ae63-bada5534e852` | `149000-149010` | Dep on System Application + Test Runner; `idRanges` near the system range. |
| **Library Assert (Test Tool)** | `dd0be2ea-f733-4d65-bb34-a28f4624fb14` | `130002-130002` | Single-ID range; `target: "Cloud"` (not OnPrem). |

Universal fields in every Microsoft `app.json`:
- `id`, `name`, `publisher: "Microsoft"`, `brief`, `description`, `version`.
- `privacyStatement`, `EULA`, `help`, `url`, `contextSensitiveHelpUrl` (all `go.microsoft.com/fwlink` or `learn.microsoft.com` URLs).
- `dependencies` array — explicit per-module deps with the **same version pin** (`29.0.0.0`).
- `internalsVisibleTo` — used to let *Test* and *Test Library* apps see internals (the Email module exposes itself to `Email Test` and `Email Test Library`).
- `platform: "29.0.0.0"`, `target: "OnPrem"` (or `"Cloud"` for test libraries).
- `idRanges` — every module declares them explicitly, even if just a single ID (e.g., `[{41,41}]`).
- `features` — almost always `["TranslationFile","GenerateCaptions"]`.
- `resourceExposurePolicy` — public modules expose source & symbols to allow debugging.

### 8.2 `AppSourceCop.json`

Found at `src/Apps/W1/EDocumentConnectors/ForNAV/App/AppSourceCop.json`:

```json
{
  "mandatoryPrefix": "ForNAV",
  "name": "Peppol",
  "publisher": "Microsoft"
}
```

This is **only present on AppSource-shipped apps** — the System Application modules do not ship through AppSource and so they don't carry AppSourceCop.json. Plugin advice: only emit `AppSourceCop.json` when targeting AppSource; otherwise the analyzer config in `.AL-Go/` or in `.vscode/settings.json` is the right place.

### 8.3 `.vscode/settings.json` baseline

There's no `.vscode/settings.json` checked in at the repo root — Microsoft instead writes settings via `build/scripts/DevEnv/DefaultSettings.json` (see §4.2). The recommended `al.codeAnalyzers` for an AL workspace mirrors what's there:

```json
"al.codeAnalyzers": [
  "${CodeCop}",
  "${AppSourceCop}",
  "${PerTenantExtensionCop}",
  "${UICop}"
]
```

---

## 9. Top canonical AL patterns from BCApps (with file references)

These 15 patterns are each demonstrated by at least one citation in BCApps and are the patterns AI agents most often get wrong. Each can be cited from a plugin skill/rule.

### 9.1 Facade Codeunit + Internal Impl Codeunit

A public codeunit with `Access = Public`, `SingleInstance = true`, `InherentEntitlements = X`, `InherentPermissions = X` that only delegates to a sibling codeunit with `Access = Internal`.

- `src/System Application/App/Email/src/Email/Email.Codeunit.al:11-21` (facade, codeunit 8901)
- `src/System Application/App/Email/src/Email/EmailImpl.Codeunit.al:14-29` (impl, codeunit 8900, declares `Permissions = tabledata ... = rimd`)
- `src/Business Foundation/App/NoSeries/src/Single/NoSeries.Codeunit.al:12-21` (NoSeries facade)
- `src/System Application/App/Azure Key Vault/src/AzureKeyVault.Codeunit.al:11-79` (79-line facade)
- `src/System Application/App/Cryptography Management/src/RSA.Codeunit.al:11-99`

### 9.2 Integration events declared on the facade

Integration events live on the *public* codeunit as `internal procedure` decorated with `[IntegrationEvent(IncludeSender, GlobalVarAccess [, IsolatedEvent])]`. They never have a body other than `begin end;`. XML-doc summary on every event.

- `src/System Application/App/Email/src/Email/Email.Codeunit.al:733-742` (`[IntegrationEvent(false, false)] internal procedure OnFindRelatedAttachments(...)`)
- `src/System Application/App/Email/src/Email/Email.Codeunit.al:763-768` (`[IntegrationEvent(false, false, true)]` — note 3rd arg = isolated event)
- `src/System Application/App/Filter Tokens/src/FilterTokens.Codeunit.al:69-120` (4 events in a row, all documented)

### 9.3 `[NonDebuggable]` for secret-handling code

Any procedure that touches secrets/tokens (`SecretText`, certificates, keys) must be `[NonDebuggable]` to keep secrets out of debugger captures.

- `src/System Application/App/Azure Key Vault/src/AzureKeyVault.Codeunit.al:29-35` (the `[NonDebuggable]` overload of `GetAzureKeyVaultSecret`)
- `src/System Application/App/Azure Key Vault/src/AzureKeyVaultImpl.Codeunit.al:36-66` (whole impl is `[NonDebuggable]`-decorated)
- Variables holding secrets also carry the attribute: `[NonDebuggable] AzureKeyVaultSecretProvider: DotNet IAzureKeyVaultSecretProvider;` (`AzureKeyVaultImpl.Codeunit.al:25-26`).

### 9.4 `[TryFunction]` for fallible operations the caller wants to inspect

- `src/System Application/App/Azure Key Vault/src/AzureKeyVault.Codeunit.al:29-49` — `GetAzureKeyVaultSecret` is declared with `[TryFunction] [Scope('OnPrem')] [NonDebuggable]`. The remarks call this out explicitly: `/// <remarks>This is a try function.</remarks>`.

### 9.5 `[Obsolete(...)]` versioning

Microsoft uses `[Obsolete('Replaced by X.', '<version>')]` to mark deprecations *before* removal. Always include the replacement and the deprecation release.

- `src/System Application/App/Email/src/Email/Email.Codeunit.al:209-212`
  ```
  [Obsolete('Replaced by Reply without the ExternalId parameter. ExternalId is not used and is contained in the EmailMessage parameter.', '26.0')]
  procedure Reply(...): Boolean
  ```
- `src/System Application/App/Pdf/src/PDFDocument.Codeunit.al:61-62`
- `src/System Application/App/MCP/src/Configuration/Codeunits/MCPConfig.Codeunit.al:193-194`

### 9.6 `SetLoadFields()` *before* filtering, with `ReadIsolation`

The Microsoft pattern is:
```
EmailMessage.SetLoadFields(Id);
EmailMessage.ReadIsolation(IsolationLevel::ReadCommitted);
EmailMessage.SetFilter(Id, '>=%1', StartMessageId);
if not EmailMessage.FindSet() then ...
```
- `src/System Application/App/Email/src/Message/EmailMessageImpl.Codeunit.al:659-664`
- `src/System Application/App/Email/src/Message/EmailMessageImpl.Codeunit.al:700-705`

### 9.7 `IsEmpty()` for existence checks

Never `Count() > 0` or `FindFirst()` if you only want a Boolean.

- `src/System Application/App/Email/src/RateLimit/EmailRateLimitImpl.Codeunit.al:87-88` (`if EmailOutbox.IsEmpty() then exit(0);`)
- `src/System Application/App/Email/src/Message/EmailMessageImpl.Codeunit.al:140`, `:453`, `:683`, `:687`

### 9.8 `FindSet()` only with `repeat..until ... Next() = 0`

The pair `if Customer.FindSet() then repeat ... until Customer.Next() = 0;` is the only canonical iteration shape. Never `FindFirst()` + `Next()` (CodeCop **AA0181/AA0233**).

- `tools/Code Review/instructions/performance.md:74-122` documents this in detail with `Bad` / `Good` examples.

### 9.9 `Get(...)` for primary-key lookup, with `SetLoadFields()` first when only some fields are used

- `tools/Code Review/instructions/performance.md:111-218` (the `SetLoadFields()` + `Get()` pattern is *explicitly approved* as best practice; `Get()` after a guard is the anti-pattern).

### 9.10 `EventSubscriber` shape

```
[EventSubscriber(ObjectType::Table, Database::"Word Template", OnAfterInsertEvent, '', false, false)]
local procedure OnAfterInsertWordTemplate(var Rec: Record "Word Template")
```

- `src/System Application/App/Word Templates/src/WordTemplateImpl.Codeunit.al:1591-1604`
- `src/System Application/App/Web Service Management/src/WebServiceManagementImpl.Codeunit.al:588-590`
- `src/System Application/App/User Settings/src/UserSettingsUpgrade.Codeunit.al:27-29`

Subscribers are always `local procedure`. The signature matches the publisher exactly.

### 9.11 Telemetry via `Session.LogMessage` with a stable event ID

- `src/System Application/App/Email/src/Message/EmailMessageImpl.Codeunit.al:760`
  ```
  Session.LogMessage('0000CTZ', StrSubstNo(RecordNotFoundMsg, TableID),
      Verbosity::Normal, DataClassification::SystemMetadata,
      TelemetryScope::ExtensionPublisher, 'Category', EmailCategoryLbl);
  ```
- Every Microsoft event ID is a unique 8-character code (e.g., `0000CTZ`, `0000FL1`). The category and label are passed as a `'Category', <label>` pair.

### 9.12 `FeatureTelemetry` for product analytics

Higher-level telemetry uses `FeatureTelemetry.LogUptake / LogUsage / LogError` from the Telemetry module.

- `src/System Application/App/Word Templates/src/WordTemplateImpl.Codeunit.al:314-316`
  ```
  FeatureTelemetry.LogUptake('0000ECP', 'Word templates', Enum::"Feature Uptake Status"::"Set up", CustomDimensions);
  ...
  FeatureTelemetry.LogError('0000ECQ', 'Word templates', 'Loading template',
                            GetLastErrorText(true), GetLastErrorCallStack(), CustomDimensions);
  ```

### 9.13 Rich errors via `ErrorInfo`

For errors that need to carry data classification, verbosity, and recoverability, build an `ErrorInfo` record and pass it to `Error(...)`.

- `src/System Application/App/Secrets/src/AppKeyVaultSecretPrImpl.Codeunit.al:23-35`
  ```
  var InitializeErrorInfo: ErrorInfo;
  ...
  InitializeErrorInfo.DataClassification := DataClassification::SystemMetadata;
  InitializeErrorInfo.ErrorType := ErrorType::Client;
  InitializeErrorInfo.Verbosity := Verbosity::Error;
  InitializeErrorInfo.Message := CannotInitializeErr;
  Error(InitializeErrorInfo);
  ```

### 9.14 Notifications API

For non-blocking user signals, build a `Notification`, set `Id := CreateGuid()`, `Message(...)`, optionally add actions, then `Send()`.

- `src/System Application/App/Retention Policy/src/Retention Policy Setup/RetentionPolicySetupImpl.Codeunit.al:414-432`
  ```
  ReadPermissionNotification.Id := CreateGuid();
  ReadPermissionNotification.Message(StrSubstNo(ReadPermissionNotificationLbl, TableId, RetentionPolicySetup."Table Caption"));
  ReadPermissionNotification.Send();
  ```
- Companion: `[SendNotificationHandler]` for tests.

### 9.15 `pageextension` — add actions to existing pages cleanly

`pageextension` should use `addafter`, `addfirst`, `addbefore`, `modify` (never raw additions). Promoted actions should be added via `actionref` in `addfirst(Promoted)`.

- `src/System Application/App/AppSource Gallery/src/AppSourceExtensionManagement.PageExt.al:8-52` shows the canonical structure: `addafter("Refresh") { action(...) {} }` followed by `addfirst(Promoted) { actionref(...) {} }`.

### 9.16 Bonus — internal events (`[InternalEvent]`)

When an event is only meant to be subscribed by the *same* module, Microsoft uses `[InternalEvent(false)]` instead of `[IntegrationEvent]`. See `src/System Application/App/Retention Policy/src/Retention Policy Setup/RetentionPolicySetupImpl.Codeunit.al:440-449`.

### 9.17 Bonus — Interface for swappable implementations

When the same operation has multiple algorithms (e.g., crypto providers, retention deleters, HTTP handlers), Microsoft declares an `interface` and concrete codeunits implement it.

- `src/System Application/App/Cryptography Management/src/SymmetricAlgorithm.Interface.al:12-24` (verbatim XML-documented interface).
- Pairs with concrete impls (`AesCryptoServiceProviderImpl.Codeunit.al`, `DESCryptoServiceProviderImpl.Codeunit.al`, etc.).
- Other examples: `Telemetry Logger.Interface.al`, `Secret Provider v2.Interface.al`, `ISFTP Client.Interface.al`, `Reten. Pol. Filtering.Interface.al`, `Http Client Handler.Interface.al`.

---

## 10. Concrete plugin integration recommendations

Mapped onto Cursor plugin component types (skill / rule / command / settings).

### 10.1 Drop-in artifacts to bundle verbatim (HIGH PRIORITY)

| BCApps artifact | Plugin component | Notes |
|------------------|-------------------|-------|
| `src/rulesets/*.json` (all 9 files) | **Command**: `AL: Apply Microsoft canonical rulesets` | Drops the JSON files into `<workspace>/rulesets/` and rewrites the AL-Go / VS Code settings to point at them. |
| `tools/Code Review/instructions/style.md` | **Rule** `al-style` (always-on, glob `**/*.al`) | The 1000-line style doc is already in the exact tone of a Cursor rule. |
| `tools/Code Review/instructions/performance.md` | **Skill** `al-performance-review` | Skill better than rule because it should activate only when user asks for review or before merging. |
| `tools/Code Review/instructions/security.md` | **Skill** `al-security-review` | Skill — same rationale. |
| `tools/Code Review/instructions/accessibility.md` | **Skill** `al-accessibility-review` | Skill. |
| `tools/Code Review/instructions/upgrade.md` | **Skill** `al-upgrade-review` | Skill — activates near upgrade codeunits. |
| `tools/Code Review/instructions/privacy.md` | **Skill** `al-privacy-review` | Skill. |
| `tools/Code Review/skills/al-code-review/SKILL.md` | **Skill** `al-code-review` (composite) | Already in SKILL.md format. Wires the six domain skills together with a unified JSON output. |
| `tools/al-docs-plugin/skills/al-docs/SKILL.md` + sub-files | **Skill** `al-docs` (init/update/audit) | Already structured as a Cursor-style skill with three modes; can be inlined directly. |
| `build/scripts/DevEnv/DefaultSettings.json` | **Command**: `AL: Apply Microsoft VS Code defaults` | Writes the AL analyzer + formatter settings into the user's `.vscode/settings.json`. |
| `.github/AL-Go-Settings.json` | **Doc/Reference** | Useful as a template for users setting up large AL-Go monorepos. |

### 10.2 Skills to author from the patterns in §9

| Skill name | Trigger | What it does |
|------------|---------|--------------|
| `al-create-module` | User: "create new System-Application-style module" | Scaffolds `<Module>/app.json`, `permissions/{Objects,Read,Edit,Admin}.PermissionSet.al`, `src/<Module>.Codeunit.al` + `src/<Module>Impl.Codeunit.al` pair, `README.md`. |
| `al-add-facade` | User: "add facade for codeunit X" | Splits an existing codeunit into Public/Internal pair with XML-doc carry-over. |
| `al-add-integration-event` | User: "add an integration event" | Inserts the canonical `[IntegrationEvent(false, false)] internal procedure ...` pattern with XML doc skeleton. |
| `al-write-tests` | User: "add tests for codeunit X" | Generates `Subtype = Test`, `EventSubscriberInstance = Manual`, `Assert: Codeunit "Library Assert"`, Given/When/Then comment skeleton, `[Test] [Scope('OnPrem')] [TransactionModel(TransactionModel::AutoRollback)]` attributes. |
| `al-secret-safe` | After editing any code touching `SecretText`/`SecretProvider`/`AzureKeyVault` | Verifies `[NonDebuggable]` is set on procedures and variables. |
| `al-perf-quickfix` | On commit/save | Flags `Count() > 0` → `not IsEmpty()`, `FindFirst()` + `Next()` → `FindSet()`, missing `SetLoadFields()` on large tables. |

### 10.3 Always-on rules

| Rule | Scope | Source |
|------|-------|--------|
| File-header license block | `**/*.al` | Standard 4-line MIT comment header — Microsoft applies it to every `.al` file. |
| Namespace declaration first | `**/*.al` | Every `.al` opens with `namespace ...;` followed by `using` imports. |
| Label suffix convention | `**/*.al` | Enforce `Err`/`Msg`/`Qst`/`Lbl`/`Tok`/`Txt` (see §5.5, `tools/Code Review/instructions/style.md:131-183`). |
| XML doc on Public procedures | `**/*.al` where codeunit declares `Access = Public` | Every public proc gets `/// <summary>` etc. |
| `Locked = true` on telemetry / token labels | `**/*.al` | When label is referenced inside `Session.LogMessage(...)` or has `://` (URL), it must be `Locked = true`. |

### 10.4 Commands

| Command | Effect |
|---------|--------|
| `AL: Apply Microsoft canonical rulesets` | Bundles the rulesets from §3 and rewires the project to use them. |
| `AL: Apply Microsoft VS Code defaults` | See §10.1. |
| `AL: Generate module README` | Reads the module's `app.json` and produces a 5–10 line README in Microsoft's style. |
| `AL: Generate permission sets` | Scans the module's tables/pages/codeunits and emits Objects/Read/Edit/Admin permission sets (see §5.3). |

### 10.5 Skill outputs that should follow Microsoft's own JSON output schema

`tools/Code Review/skills/al-code-review/SKILL.md:167-200` defines a strict JSON-only output format for review findings (`filePath`, `lineNumber`, `severity`, `issue`, `recommendation`). The plugin's review skills should emit the same shape so users can pipe results across tools.

---

## 11. Open questions / things to verify before shipping

1. **License of the prompts in `tools/Code Review/instructions/`**. The repo is MIT, so the instruction `.md` files are MIT too, but the plugin should keep an attribution comment when inlining them verbatim. Recommend: include the BCApps commit SHA in a header comment of each bundled file.
2. **Rulesets evolve**. The 9 ruleset files change at every BC release. The plugin should either:
   - Pin to a specific BC version (e.g., "29.x"), or
   - Provide an "update from BCApps `main`" command that pulls the latest JSON.
3. **Per-module vs bundled System Application**. Some idRanges (e.g., `[{41,41}]` for Filter Tokens) work *only* because Microsoft owns the system ID range. The plugin's "create module" command should ask for the user's allocated AppSource/PTE range, *not* mimic Microsoft's range.
4. **`target: "OnPrem"` vs `"Cloud"`**. System Application modules ship as `OnPrem`; Test Library apps ship as `Cloud`. Worth surfacing as a question when scaffolding new apps.
5. **`Microsoft.*` vs `System.*` namespaces**. Business Foundation uses `Microsoft.Foundation.*`; System Application uses `System.*`. Both are reserved (AS0008/PTE0021 are silenced for BCApps but **enforced for non-Microsoft apps** — the plugin must warn users that they cannot use these namespaces).
6. **The `tools/al-docs-plugin/` skill references `microsoft_docs_search` / `microsoft_docs_fetch` MCP tools.** If the plugin inlines that skill, decide whether to bundle the same MCP server requirement or stub it out with a generic web-fetch fallback.
7. **Test idRanges**: every test app in BCApps uses the `130000–139999` block (`src/System Application/Test/app.json:64-68`). The plugin should hard-code that as "Microsoft test IDs" and warn users to pick their own band.
8. **CODEOWNERS as taxonomy**. The 42-line CODEOWNERS could be used to build an internal map "AI module → owning team", but its team names are Microsoft-internal — useful for citation only, not for emulation.
9. **`AS0085 / AS0100` (the `application` property)** are silenced for BCApps but ARE the modern AppSource standard. Plugin's AppSource targeting code should enable them.
10. **No `.editorconfig`** in the repo. Microsoft formats via VS Code's AL formatter only (`editor.formatOnSave: true`). If the plugin wants to enforce formatting across non-VSCode editors, it has to ship its own formatter config — there isn't one to mirror.

---

## Appendix A — Source URLs cited in this document

| Section | URL |
|---------|-----|
| Repo root | <https://github.com/microsoft/BCApps> |
| `CONTRIBUTING.md` | <https://github.com/microsoft/BCApps/blob/main/CONTRIBUTING.md> |
| `LOCAL_DEV_ENV.md` | <https://github.com/microsoft/BCApps/blob/main/LOCAL_DEV_ENV.md> |
| `CODEOWNERS` | <https://github.com/microsoft/BCApps/blob/main/CODEOWNERS> |
| `.github/AL-Go-Settings.json` | <https://github.com/microsoft/BCApps/blob/main/.github/AL-Go-Settings.json> |
| Rulesets folder | <https://github.com/microsoft/BCApps/tree/main/src/rulesets> |
| `src/rulesets/ruleset.json` | <https://github.com/microsoft/BCApps/blob/main/src/rulesets/ruleset.json> |
| `src/rulesets/internal.module.ruleset.json` | <https://github.com/microsoft/BCApps/blob/main/src/rulesets/internal.module.ruleset.json> |
| `src/rulesets/minorrelease.ruleset.json` | <https://github.com/microsoft/BCApps/blob/main/src/rulesets/minorrelease.ruleset.json> |
| Build projects folder | <https://github.com/microsoft/BCApps/tree/main/build/projects> |
| `build/projects/System Application/.AL-Go/settings.json` | <https://github.com/microsoft/BCApps/blob/main/build/projects/System%20Application/.AL-Go/settings.json> |
| `build/projects/System Application Modules/.AL-Go/settings.json` | <https://github.com/microsoft/BCApps/blob/main/build/projects/System%20Application%20Modules/.AL-Go/settings.json> |
| `build/scripts/DevEnv/DefaultSettings.json` | <https://github.com/microsoft/BCApps/blob/main/build/scripts/DevEnv/DefaultSettings.json> |
| `src/System Application/App/app.json` | <https://github.com/microsoft/BCApps/blob/main/src/System%20Application/App/app.json> |
| Email module | <https://github.com/microsoft/BCApps/tree/main/src/System%20Application/App/Email> |
| `Email.Codeunit.al` (facade) | <https://github.com/microsoft/BCApps/blob/main/src/System%20Application/App/Email/src/Email/Email.Codeunit.al> |
| `EmailImpl.Codeunit.al` | <https://github.com/microsoft/BCApps/blob/main/src/System%20Application/App/Email/src/Email/EmailImpl.Codeunit.al> |
| `AzureKeyVault.Codeunit.al` | <https://github.com/microsoft/BCApps/blob/main/src/System%20Application/App/Azure%20Key%20Vault/src/AzureKeyVault.Codeunit.al> |
| `Filter Tokens` module | <https://github.com/microsoft/BCApps/tree/main/src/System%20Application/App/Filter%20Tokens> |
| `Headlines` module | <https://github.com/microsoft/BCApps/tree/main/src/System%20Application/App/Headlines> |
| `Cryptography Management` module | <https://github.com/microsoft/BCApps/tree/main/src/System%20Application/App/Cryptography%20Management> |
| `Business Foundation/App/NoSeries` | <https://github.com/microsoft/BCApps/tree/main/src/Business%20Foundation/App/NoSeries> |
| Library Assert | <https://github.com/microsoft/BCApps/blob/main/src/Tools/Test%20Framework/Test%20Libraries/Assert/src/LibraryAssert.Codeunit.al> |
| Test Runner | <https://github.com/microsoft/BCApps/tree/main/src/Tools/Test%20Framework/Test%20Runner> |
| Performance Toolkit — BCPT Test Context | <https://github.com/microsoft/BCApps/blob/main/src/Tools/Performance%20Toolkit/App/src/BCPTTestContext.Codeunit.al> |
| `tools/Code Review` (AI prompts) | <https://github.com/microsoft/BCApps/tree/main/tools/Code%20Review> |
| `tools/Code Review/instructions/style.md` | <https://github.com/microsoft/BCApps/blob/main/tools/Code%20Review/instructions/style.md> |
| `tools/Code Review/instructions/performance.md` | <https://github.com/microsoft/BCApps/blob/main/tools/Code%20Review/instructions/performance.md> |
| `tools/al-docs-plugin/skills/al-docs/SKILL.md` | <https://github.com/microsoft/BCApps/blob/main/tools/al-docs-plugin/skills/al-docs/SKILL.md> |

---

## Appendix B — How to obtain the rulesets in CI

```powershell
# PowerShell — pulls the latest canonical rulesets into ./rulesets/
$base = 'https://raw.githubusercontent.com/microsoft/BCApps/main/src/rulesets'
$files = @(
  'ruleset.json',
  'Analyzer.ruleset.json',
  'AppSourceCop.ruleset.json',
  'CodeCop.ruleset.json',
  'Compiler.ruleset.json',
  'PTECop.ruleset.json',
  'UICop.ruleset.json',
  'internal.module.ruleset.json',
  'minorrelease.ruleset.json'
)
New-Item -ItemType Directory -Force -Path ./rulesets | Out-Null
foreach ($f in $files) {
  Invoke-WebRequest -Uri "$base/$f" -OutFile "./rulesets/$f"
}
```

For Cursor plugin distribution, prefer **vendor-and-pin to a specific BCApps commit SHA** so the plugin's behaviour is reproducible.
