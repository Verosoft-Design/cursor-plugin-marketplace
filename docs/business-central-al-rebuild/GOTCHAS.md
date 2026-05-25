# Gotchas — small print that's easy to forget

Cross-cutting things from the research dossiers worth re-reading before each phase.

## AL MCP (Phase 1)

- **`al_symbolsearch` requires a `parameters: {...}` wrapper.** Every other tool takes args at the top level. This is the single most common bug for new AL MCP integrations. See `research/algo-mcp-research.md` §7.2 (`al_symbolsearch parameters`).
- **`altool` install paths.** Either the VS Code AL extension (`~/.vscode/extensions/ms-dynamics-smb.al-*/bin/<os>/altool[.exe]`) OR `Microsoft.Dynamics.BusinessCentral.Development.Tools` NuGet (provides the `al` alias). For Cursor-only users without VS Code, document the NuGet path explicitly in the README.
- **`al_publish` schema-update modes.** `Synchronize` (default) / `ForceSync` / `Recreate`. `Recreate` drops data — never make it default in compound commands.
- **Code analyzer placeholder strings.** Pass `"${CodeCop}"`, `"${AppSourceCop}"`, `"${PerTenantExtensionCop}"`, `"${UICop}"` (with the dollar-brace literally) in `al_build.codeAnalyzers`.
- **Diagnostic codes are stable** (e.g. `AL0118`, `AS0023`, `AA0074`). `area` filter accepts `"AL"`, `"AppSourceCop"`, `"CodeCop"`, `"PerTenantExtensionCop"`. Use these in commands so power users can filter.
- **`al_auth_login` is MCP-only.** VS Code uses the IDE's auth. In CI, pair `globalSourcesOnly: true` on `al_downloadsymbols` to skip auth altogether.

## AL-Go (Phase 2)

- **AL-Go version pin is in `templateUrl` (e.g. `…AL-Go-PTE@v9.0`).** Do NOT hardcode `@v9.0` anywhere in plugin commands — read from `.github/AL-Go-Settings.json` and let `Update AL-Go System Files` move it forward.
- **Build job is Windows + Docker only.** `runs-on` setting controls housekeeping (can be `ubuntu-latest`); `githubRunner` controls the build job (must be Windows).
- **Internal CI/CD workflow name has a leading space** — ` CI/CD`. Reference it in `gh workflow run "CI/CD"` carefully.
- **`(PROD)` / `(FAT)` suffix on GitHub Environment names tells AL-Go NOT to CD there.** Required for production manual-deploy flow.
- **Secrets are JSON-shaped.** `AuthContext`, `AppSourceContext`, `StorageContext`, `NuGetContext`, `GitHubPackagesContext`, `AdminCenterApiCredentials`, `Azure_Credentials`. Use BcContainerHelper's `New-BcAuthContext` + `New-ALGo*Context` helpers to mint them. Document this in `commands/al-secrets-setup.md`.
- **`GhTokenWorkflow` for "Update AL-Go System Files".** GitHub App (recommended) shape: `{"GitHubAppClientId":"…","PrivateKey":"…"}`. PAT shape: a single string. Permissions: R/W Contents + PRs + Workflows; R Actions.
- **First AppSource upload is manual.** Marketing materials + initial product registration in Partner Center cannot be automated. `commands/al-publish-appsource.md` MUST surface this in the prompt.
- **Continuous Delivery to AppSource sits in Preview** until someone clicks Go Live (or runs with `GoLive: true`). Plugin should surface this state.

### Deprecation calendar (avoid baking these in)

| Setting | Removed after | Use instead |
|---|---|---|
| `unusedALGoSystemFiles` | **2026-10-01** | `customALGoFiles.filesToExclude` |
| `alwaysBuildAllProjects` | **2025-10-01** (PAST DUE) | `incrementalBuilds.onPull_Request: false` (or `fullBuildPatterns`) |
| `<workflow>Schedule` dynamic setting | **2025-10-01** (PAST DUE) | `workflowSchedule` per-workflow setting / conditional settings |
| `cleanModePreprocessorSymbols` | **2025-04-01** (PAST DUE) | `preprocessorSymbols` + conditional settings on `buildModes` |

## BCApps (Phase 3)

- **Rulesets evolve per BC release.** Pin to a SHA, surface that SHA in `PINNED.json` and ideally in the status line.
- **Most ID ranges in BCApps are 1st-party-only.** `[{41,41}]` Filter Tokens, `1-9999` System App, `130000-139999` test apps. `al-scaffold-module` MUST ask the user for their own allocated range (never mimic Microsoft's).
- **`Microsoft.*` / `System.*` namespaces are reserved** (AS0008/PTE0021 — silenced for BCApps but enforced everywhere else). `al-scaffold-module` must warn.
- **`AS0085 / AS0100` (the `application` property)** are silenced in BCApps but ARE the modern AppSource standard. Plugin's AppSource scaffolding must enable them.
- **Test app target = `Cloud`, not `OnPrem`** (System App modules ship as `OnPrem` — opposite for tests).
- **License header line 2 is `Microsoft Corporation`.** Per Decision Q5, make this configurable so Verosoft / TAG can swap publishers.
- **BCApps has two complementary builds.** "System Application" bundles everything; "System Application Modules" builds each module separately using `internal.module.ruleset.json` (which silences AppSource manifest rules `AS0014`/`AS0015`/`AS0051`/`AS0052`). Mirror this pattern in `al-scaffold-module` when a multi-module repo is scaffolded.
- **`tools/Code Review/instructions/*.md`** are MIT and ~600–1000 lines each with `bad` / `good` AL code blocks. They complement BCQuality (which forbids fenced code in knowledge files). Plan to vendor both.

## BCQuality (Phase 4)

- **The repo is in active preview.** README warns of breaking changes. No release tags. Pin to a SHA.
- **CodeOwners is one person** (`@jeschulz`) — schema evolves slowly. Frontmatter v1 is locked.
- **Knowledge file rules** (enforced by validator R01–R25):
  - 6 required frontmatter fields: `bc-version`, `domain`, `keywords`, `technologies`, `countries`, `application-area`
  - **No fenced code blocks** in body — samples live in sibling `<slug>.{good,bad}.al` files
  - File ≤ 100 lines
  - Path shape `<layer>/knowledge/<domain>/<slug>.md`
- **Layer precedence:** `/custom/` > `/community/` > `/microsoft/`. Conflicts resolved automatically; suppressed files MUST appear in `suppressed[]` of output.
- **Super-skill (al-code-review) MUST NOT filter sub-skills by task content.** Per DO contract. Each leaf decides its own applicability.
- **`al-ui-review` is the only leaf with `technologies: [al, javascript]`** (control add-ins).
- **`al-privacy-review` MUST exclude test code** (test data is synthetic).
- **Agent findings encoding** (from super-skill self-review):
  - `from-sub-skill: "agent"` (canonical marker)
  - `references: []` (required)
  - `id: "agent:<slug>"` (the `agent:` prefix is mandatory)
  - `confidence ≤ medium`
  - `message` self-contained (no knowledge-file footer to fall back on)
- **Citation-based finding `id` MUST equal `references[0].path`.** This is how consumers deduplicate.
- **Reference `sha` is optional but SHOULD be included** when the plugin pins to a SHA. Always set it — this is the whole point of pinning.
- **`outcome: no-knowledge` vs `not-applicable` vs empty `completed`** are three distinct states. DO contract: "Orchestrators MUST NOT conflate."
- **Validator is the operational spec.** `validate_frontmatter.py` (568 lines, R01–R25) is the source of truth when prose docs are ambiguous.
- **The 6 leaf review skills.** Source paths:
  - `al-performance-review` → `*/knowledge/performance/`
  - `al-security-review` → `*/knowledge/security/`
  - `al-privacy-review` → `*/knowledge/privacy/`
  - `al-upgrade-review` → `*/knowledge/upgrade/`
  - `al-style-review` → `*/knowledge/style/`
  - `al-ui-review` → `*/knowledge/ui/`
- **Worklist signal tokens are documented per skill** (e.g. performance: `SetRange`, `SetLoadFields`, `FindSet`, `LockTable`, …). See `research/bcquality-research.md` §5 for the full lists.

## BC-Bench (Phase 5)

- **Default models** (measured on 5 full runs, all 101 tasks):
  - bug-fix winner: `claude-opus-4-7` (67.9 %)
  - bug-fix Copilot winner: `claude-sonnet-4-6` (67.3 %)
  - bug-fix + AL MCP winner: `claude-opus-4-6` + `altool` (71.3 %)
  - test-gen winner: `claude-opus-4-7` (54.3 %)
  - test-gen + ALTest agent: `claude-opus-4-6` + `ALTest` (62.4 %, +10.7 pt)
  - speed pick: `gpt-5-3-codex` (~107 s/task, 55.8 %)
  - DO NOT use: `gpt-4-1` (16.6 % — effectively broken on AL)
- **`ALTest.agent.md` is MIT-licensed** and ships in BC-Bench at `src/bcbench/agent/shared/instructions/microsoftInternal-NAV/agents/ALTest.agent.md`. ~260 lines. The biggest measured tooling win (+10.7 pt, pass^5 nearly doubles).
- **`bcq-eval` style A/B testing of the plugin is possible** by forking BC-Bench and adding a `cursor` agent module (~80 lines mirroring `claude/agent.py`). Out of scope for this rebuild but worth surfacing in README as a future direction.
- **Tasks are W1-only by design.** Localization (US/DE/DK/APAC) is explicitly out of BC-Bench scope.

## Cursor plugin authoring

- **Plugin directory:** `plugins/business-central-al/` inside the marketplace repo.
- **Component discovery paths (defaults):**
  - rules → `rules/*.mdc`
  - skills → `skills/<name>/SKILL.md`
  - commands → `commands/<name>.md`
  - hooks → `hooks/hooks.json`
  - MCP config → `mcp.json` (or `mcpServers` in plugin.json)
- **Skill `description` field MAX 1024 chars total in frontmatter.** Third-person voice. "Use when..." opener. NEVER summarize the skill's workflow in the description (causes Claude to skip reading the body).
- **Rule `globs` are comma-separated** (not array): e.g. `globs: app.json, **/*.al,`
- **Skills must be in `skills/<skill-name>/` directory** (the directory matters, not just SKILL.md placement).
- **`disable-model-invocation: true`** by default for skills the agent should only load when explicitly named. Omit only for ambient triggering. For our review skills: omit (they should auto-trigger when the agent recognizes an AL review task).
- **Hooks `command` paths are relative to the plugin root**, NOT the repo root.

## TAG-specific (custom layer)

- **TAG ID ranges:** Primary `70015000-70016999`, API `23085634-23085783`. Hard-coded in TAG_CUSTOM_LAYER.md articles.
- **TAG filename pattern is UNIQUE:** `[ObjectType] [ObjectID] - TAG [ObjectName].al` (NOT BCApps' `<Object>.<Type>.al`). The `al-naming-and-files.mdc` rule should be BCApps default, but TAG's custom-layer article for naming OVERRIDES it.
- **TAG project structure is `BC/{API,CodeUnit,Enums,…}` at the repo root**, not BCApps' `src/<Module>/src/`. `al-scaffold-module` needs an `--existing-layout` flag or auto-detection.
- **TAG publisher:** `verosoftdesign`, API group: `tag`, version: `v1.0`, entity names: camelCase.
- **TAG procedure parameters are `p`-prefixed** (e.g. `pParameter`, `pEquipmentID`). BCApps doesn't do this — TAG's custom-layer style article overrides BCApps's procedure naming.
- **TAG variable prefix table** (see TAG_CUSTOM_LAYER.md): `EquipmentRec`, `WOHeader`, `WOLine`, `TechRec`, `TAGSetup`, `DMPolicy`, `MaintHeader`, etc.
- **TAG uses preprocessor symbols** (`CLEAN24`, etc.) — the AL-general TAG style still needs that branching, but it's a code pattern not a custom-layer concern.
