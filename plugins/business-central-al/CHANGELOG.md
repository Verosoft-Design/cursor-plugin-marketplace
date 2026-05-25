# Changelog

All notable changes to the `business-central-al` Cursor plugin are documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Planned for upcoming phases (see `docs/business-central-al-rebuild/PLAN.md`):

The original 5-phase rebuild is complete. Future work:

- **Phase 6 (deferred):** hosted Business Central runtime MCP for chat over BC data — `/bc-query`, `/bc-post`. Requires Entra app registration + per-tenant _MCP Server Configuration_.

## [0.6.4] — 2026-05-25

### Fixed — first-call MCP server identifier mistake

Observed in the wild: the agent's first AL MCP tool call in a session fails with `MCP server does not exist: al`, then the agent self-recovers by reading the `mcps/` cache descriptors. Root cause: every doc and config uses the friendly name `al`, but Cursor namespaces plugin-provided MCP servers as `plugin-<plugin-name>-<server-name>`, so the actual identifier the agent must pass to a meta MCP-call tool is `plugin-business-central-al-al`. The agent had no way to know that without first reading `SERVER_METADATA.json`.

- `rules/al-mcp-usage.mdc` — added a new "Server identifier (READ FIRST)" section at the top of the body that maps friendly name `al` → identifier `plugin-business-central-al-al`, points at the `SERVER_METADATA.json` source of truth, and explicitly tells the agent never to pass `server="al"` to a meta MCP tool. Description also updated to mention this so the rule is more likely to be auto-loaded before the first AL MCP attempt.
- `rules/al-mcp-usage.mdc` — frontmatter now scopes the rule with `globs: ["**/*.al", "**/app.json"]` so it auto-attaches the moment the agent looks at any AL workspace, instead of relying purely on the description being matched in time.

Net effect: the agent should make the correct first MCP call without the recovery round-trip.

## [0.6.3] — 2026-05-25

### Fixed — eliminate per-session `al_addproject` round-trip

The plugin's default `mcp.json` runs `altool launchmcpserver --transport stdio` with no positional `<projects>` argument, so every new Cursor session starts the AL MCP with **zero loaded projects**. Any project-scoped tool (`al_build`, `al_compile`, `al_symbolsearch`, …) then returns empty until the agent calls `al_addproject` first. That's an extra round-trip every single session.

The fix: when run in an AL workspace, `/al-setup` now offers to write a workspace-level `.cursor/mcp.json` that re-declares the `al` server with `${workspaceFolder}` as a positional argument. Cursor's variable substitution resolves it to the workspace root containing the `.cursor/mcp.json`, so the AL MCP launches with the project already loaded. One-time per workspace, zero plugin-side changes.

- `skills/al-setup/SKILL.md` — added Step 4 "Workspace project-path injection (highly recommended)". Gated on three preconditions: workspace has `app.json`, no conflicting `al` server in existing `.cursor/mcp.json`, AL MCP probe is green. Handles the "merge into existing `.cursor/mcp.json`" edge case (rather than overwriting other servers).
- `rules/al-mcp-usage.mdc` — new section "Initial project load — call `al_addproject` if no projects are loaded" tells the agent: if there's no workspace-level pre-load and a project-scoped tool is about to be called, either call `al_addproject` first OR suggest `/al-setup` to bake the path in once.
- The plugin's default `mcp.json` is **unchanged** — keeping it generic means the plugin loads safely in non-AL workspaces, while AL workspaces opt in via the workspace-level override.

### What an injected workspace `.cursor/mcp.json` looks like

```json
{
  "mcpServers": {
    "al": {
      "command": "altool",
      "args": ["launchmcpserver", "--transport", "stdio", "${workspaceFolder}"]
    }
  }
}
```

Workspace config wins over plugin config when they share a server name, so the plugin's generic `al` server stays defined for other workspaces while this one gets the project-path injection.

## [0.6.2] — 2026-05-25

### Changed — migrated all `commands/` to slash-invokable skills

Cursor 2.4+ is actively migrating away from the `commands` plugin component type. The built-in `/migrate-to-skills` skill converts user-level and workspace-level commands to skills with `disable-model-invocation: true` (which makes a skill behave like a traditional slash command — no auto-activation, only fires when the user types `/name`). The Cursor `CursorPluginsAgentSkillsService` plugin loader only reports `ruleCount` and `skillCount`; commands never reach the slash picker in the current plugin pipeline.

This release applies the same migration to the plugin's vendored commands so every `/al-*` and `/bcq-*` entry surfaces in the slash picker.

- **38 command files converted to skills** with `disable-model-invocation: true`:
  - Inner loop: `al-build`, `al-compile`, `al-symbols`, `al-symbol-search`, `al-publish-sandbox`, `al-setup`
  - Scaffolding: `al-new-pte`, `al-new-appsource`, `al-add-test-app`, `al-add-bcpt-app`, `al-import-existing-app`, `al-create-online-dev-env`
  - CI/CD & release: `al-current`, `al-next-minor`, `al-next-major`, `al-troubleshoot`, `al-update-system-files`, `al-increment-version`, `al-release`, `al-publish-to-environment`, `al-publish-appsource`, `al-deploy-docs`, `al-go-live`
  - Secrets: `al-secrets-setup`, `al-init-keyvault`
  - Quality: `al-apply-rulesets`, `al-apply-vscode-defaults`
  - BCQuality review: `bcq-review`, `bcq-review-performance`, `bcq-review-security`, `bcq-review-privacy`, `bcq-review-upgrade`, `bcq-review-style`, `bcq-review-ui`, `bcq-update`
  - Original TDD set: `scaffold-test-codeunit`, `scaffold-handler-methods`, `tdd-checklist`
- **3 command files deleted** because a skill of the same name already exists and is the better surface for that workflow:
  - `commands/al-docs.md` → `skills/al-docs/SKILL.md` (BCApps al-docs adapter, agent-decided)
  - `commands/al-write-test.md` → `skills/al-write-test/SKILL.md` (BC-Bench ALTest adapter, agent-decided)
  - `commands/bcq-write-knowledge.md` → `skills/bcq-write-knowledge/SKILL.md` (BCQuality knowledge authoring, agent-decided)
- **`commands/` folder removed entirely.** `"commands": "commands"` field dropped from `.cursor-plugin/plugin.json`.

After this release the plugin ships **53 skills total**:

- 40 with `disable-model-invocation: true` — slash-invokable only, behave exactly like the old commands (user types `/al-build`, agent runs that exact workflow)
- 13 without that flag — agent-decided orchestration skills the agent picks based on conversation context: `al-build-and-publish`, `al-code-review`, `al-docs`, `al-entry`, `al-go-lifecycle`, `al-performance-review`, `al-privacy-review`, `al-scaffold-module`, `al-security-review`, `al-style-review`, `al-ui-review`, `al-upgrade-review`, `al-write-test`, `bcq-write-knowledge`, `business-central-al-tdd`

### Why the 0.6.1 manifest fix wasn't enough

0.6.1 added `"commands": "commands"` to the plugin manifest after observing that `cursor-public/vercel` and `cursor-public/superpowers` both declare component paths explicitly. That fix was necessary but not sufficient: Cursor `CursorPluginsAgentSkillsService` loads only skills and rules from plugins — commands are not registered with the slash-command picker at all in the current pipeline. Confirmed by reading Cursor's own session log:

```text
CursorPluginsAgentSkillsService load completed {durationMs:481, ruleCount:65, skillCount:56}
```

No `commandCount`. The migration to skills is the supported path.

## [0.6.1] — 2026-05-25

### Fixed — slash-command registration

- **`.cursor-plugin/plugin.json` now explicitly declares component paths.** Without `"commands": "commands"` (and `"skills": "skills"`, `"rules": "rules"`) in the manifest, Cursor silently dropped the entire `commands/` folder during plugin load. Skills and the MCP server registered correctly via auto-discovery, but every `/al-*` and `/bcq-*` slash command was missing from the slash picker. Confirmed by comparing with `cursor-public/vercel` and `cursor-public/superpowers`, both of which declare component paths explicitly. Adding the three explicit paths restores all 40 commands.

### Fixed (Phase 1 follow-up)

- `mcp.json` previously included a `$schema` reference to a non-existent URL (`https://raw.githubusercontent.com/modelcontextprotocol/spec/main/schema/2025-03-26/schema.json`). Cursor's `mcp.json` format does not require or support a `$schema` field; the reference produced a 404 in any editor that resolves `$schema` URLs. Removed.

### Added (Phase 1 follow-up — AL MCP setup automation)

- `scripts/check-altool.sh` — probes for the AL MCP binary (`altool` from the VS Code AL Language extension, or `al` from the `Microsoft.Dynamics.BusinessCentral.Development.Tools` NuGet package) on PATH and writes a one-line status to stdout (`altool:<version>` / `al:<version>` / `missing`). Used by both the session-start hook and `/al-setup`.
- `commands/al-setup.md` — diagnose-and-install command for AL MCP prerequisites. Detects which (if any) binary is present, walks the user through the VS Code AL extension or NuGet install path with **explicit user confirmation before any install runs**, and fixes the `altool`/`al` mismatch (via shim or `mcp.json` edit) when only the NuGet variant is available.
- `scripts/session-start-context.sh` (updated) — now probes for the AL MCP binary at session start and surfaces the result in the session context, with a hint pointing at `/al-setup` whenever something is missing or misconfigured. Three states reported: `altool` ready, `al`-but-needs-fix, or missing-run-`/al-setup`.
- `skills/al-build-and-publish/SKILL.md` (updated) — the "when the AL MCP is unavailable" section now defers to `/al-setup` instead of walking the user through manual install.
- `README.md` (updated) — Prerequisites section recommends `/al-setup` as the easiest install path; commands table includes a new Setup section with `/al-setup`.

## [0.6.0] — 2026-05-25

### Added — BC-Bench wins (Phase 5, the final phase of the 5-phase rebuild)

- **Vendored `microsoft/BC-Bench` ALTest.agent.md** at pinned SHA `ef4f4668`. The 267-line MIT-licensed domain-agent prompt that BC-Bench measured at **+10.7 pt mean and ~2x pass^5** on AL test-generation tasks (Opus 4.6 / Copilot, 5 runs, 101 tasks). Stored at `content/altest-prompt/ALTest.agent.md`.
- **Vendored `microsoft/BCApps/tools/al-docs-plugin/skills/al-docs/`** at the same BCApps SHA as Phase 3. 1150 lines total across `SKILL.md`, `al-docs-init.md`, `al-docs-update.md`, `al-docs-audit.md`, `references/al-scoring.md`. Stored at `content/al-docs-references/`.
- **`scripts/vendor-bcbench.sh`** — idempotent vendor for BC-Bench. Supports `--latest` and `--ref <sha>`.
- **`scripts/vendor-bcapps.sh` extended** to also fetch the al-docs content under `content/al-docs-references/` as part of the BCApps refresh. PINNED.json's `bcapps.categories` now lists `al_docs` alongside `rulesets`, `defaults`, and `review_prompts`.
- **`scripts/detect-al-repo.sh`** — POSIX sh script that walks up from PWD looking for `app.json` and `.AL-Go/settings.json`. When found, emits a JSON `additional_context` with BC project metadata (name, publisher, app version, runtime, platform, target, AL-Go type/country/templateUrl). Best-effort: emits empty `{}` when no AL workspace is detected.
- **`scripts/session-start-context.sh` expanded** to include the BC-Bench measured model recommendation (Claude Opus 4.7 / Sonnet 4.6 default; `gpt-5.3-codex` for speed; avoid `gpt-4.1` for AL — 16.6% measured accuracy). Existing AL MCP probe and TDD guidance preserved.
- **`hooks/hooks.json` extended** with a `userPromptSubmit` hook running `detect-al-repo.sh`. Result: every prompt the user submits while in an AL workspace gets enriched with the project's metadata, so the agent doesn't have to re-parse `app.json` itself.
- **`skills/al-write-test/SKILL.md`** — Cursor adapter for the ALTest prompt. Auto-invokes when the user asks to write, scaffold, or generate AL tests. Reads `content/altest-prompt/ALTest.agent.md` in full and applies the `al-testing` rule alongside.
- **`skills/al-docs/SKILL.md`** — Cursor adapter for the BCApps al-docs skill. Routes init / update / audit modes to the corresponding reference file in `content/al-docs-references/`. Defaults to `init` for fresh projects, `audit` for projects with existing docs. Writes to `AGENTS.md` (Cursor convention) or `CLAUDE.md` (Claude Code convention) per the user's preference.
- **`commands/al-write-test.md`** + **`commands/al-docs.md`** — explicit slash-command entrypoints for the two new skills.

### Plugin totals after the 5-phase rebuild

- **41 slash commands**: 3 TDD baseline + 5 AL MCP + 19 AL-Go lifecycle + 2 BCApps quality baseline + 9 BCQuality review + 2 BC-Bench wins + 1 user-added `/al-setup`
- **15 skills**: business-central-al-tdd, al-build-and-publish, al-go-lifecycle, al-scaffold-module + 9 BCQuality (al-entry, al-code-review super, 6 leaves, bcq-write-knowledge) + al-write-test + al-docs
- **12 rules**: 6 always-on + 1 pattern-matched (al-workflow) + 5 agent-requestable
- **2 hooks**: sessionStart (BC-Bench model recommendation + AL MCP status) + userPromptSubmit (BC project metadata enrichment)
- **1 MCP config**
- **8 scripts**: session-start-context.sh, check-altool.sh, detect-al-repo.sh, vendor-bcapps.sh, vendor-bcquality.sh, vendor-bcbench.sh, validate-bcquality-frontmatter.py (vendored), render-findings.py + .sh wrapper
- **427 vendored upstream content files**: 21 BCApps + 410 BCQuality + 1 BC-Bench, all SHA-pinned in `content/PINNED.json`
- **3 upstream Microsoft repos** integrated end-to-end: BCApps, BCQuality, BC-Bench. All MIT-licensed, all refreshable via `/bcq-update` or per-source vendor scripts.

### What this plugin now does end-to-end

1. **Scaffold** a new PTE or AppSource repo (`/al-new-pte`, `/al-new-appsource`) using AL-Go templates.
2. **Apply Microsoft's quality bar** (`/al-apply-rulesets`, `/al-apply-vscode-defaults`).
3. **Scaffold modules** (`al-scaffold-module` skill) in BCApps or TAG layout.
4. **Inner-loop** (`/al-symbols`, `/al-compile`, `/al-build`, `/al-publish-sandbox`) via the AL MCP.
5. **Write tests** (`/al-write-test` ALTest agent, `/scaffold-test-codeunit`, `/scaffold-handler-methods`) following BCApps Library Assert conventions.
6. **Document** (`/al-docs init|update|audit`) with the BCApps hierarchical-doc skill.
7. **Review** (`/bcq-review` super-skill + 6 leaves) using Microsoft's structured BCQuality knowledge base + TAG custom-layer overrides + agent self-review.
8. **CI/CD** (`/al-add-test-app`, `/al-publish-to-environment`, `/al-current`, `/al-next-minor`, `/al-next-major`, `/al-troubleshoot`, `/al-update-system-files`) via AL-Go workflows.
9. **Release & ship** (`/al-increment-version`, `/al-release`, `/al-publish-appsource`, `/al-deploy-docs`, `/al-go-live`) with production-gates and AppSource Go Live confirmation.
10. **Maintain** (`/al-secrets-setup`, `/al-init-keyvault`, `/bcq-update`) the plugin and the project's secrets / vendored content over time.

## [0.5.0] — 2026-05-25

### Added — BCQuality integration (Phase 4)

- **Vendored upstream content** at pinned SHA `4d59fb73` from `microsoft/BCQuality`:
  - 4 meta-skills at `content/bcquality/` root (`entry.md`, `read.md`, `do.md`, `write.md`) — the authoritative contracts.
  - 141 microsoft knowledge articles + 211 AL samples under `content/bcquality/microsoft/knowledge/` across 7 domains (performance, privacy, security, style, testing, ui, upgrade).
  - 7 microsoft skills under `content/bcquality/microsoft/skills/review/` (`al-code-review` super-skill + 6 leaves).
  - 13 community knowledge articles + 23 AL samples under `content/bcquality/community/knowledge/`.
  - `content/bcquality/custom/` skeleton (writeable; never overwritten by vendor scripts).
  - `content/PINNED.json` extended with the `bcquality` entry alongside `bcapps`.
- **Vendored upstream validator** at `scripts/validate-bcquality-frontmatter.py` (586 lines, implements rules R01–R25). Verified clean against the full tree including the custom layer.
- **`scripts/vendor-bcquality.sh`** — idempotent vendor script using GitHub tarball + tar. Wipes and replaces upstream-managed `microsoft/` and `community/` dirs; preserves `custom/` always. Runs the validator after every refresh. Supports `--latest` and `--ref <sha>`.
- **`scripts/render-findings.py`** + **`scripts/render-findings.sh`** wrapper — pretty-prints the BCQuality DO findings-report JSON into a human-readable terminal table with severity glyphs, sub-skill attribution, knowledge-file references with SHA pins, and suppressed-by-precedence reporting.
- **8 TAG-specific custom-layer knowledge articles** (the user's pre-seeded content per Decision Q6):
  - `style/` — `tag-object-id-ranges`, `tag-filename-pattern` (overrides BCApps default), `tag-object-name-prefix`, `tag-project-folder-structure` (overrides BCApps), `tag-procedure-parameter-prefix` (overrides BCApps), `tag-variable-naming-conventions`.
  - `api/` — `tag-api-page-conventions`.
  - `upgrade/` — `tag-clean-version-preprocessor`.
  - All 8 pass the upstream R01–R25 validator.
- **4 agent-requestable contract rules** (`rules/bcquality-{read,do,entry,write}-contract.mdc`) — thin pointers to the vendored meta-skill files. The agent loads the full upstream contract on demand.
- **8 Cursor skills** (thin adapters over the vendored upstream BCQuality skills):
  - `al-entry` — task router. Reads `content/bcquality/entry.md` and emits a dispatch record.
  - `al-code-review` — super-skill orchestrator. Composes the 6 leaves + runs the agent self-review pass with knowledge-validation.
  - `al-performance-review`, `al-security-review`, `al-privacy-review`, `al-upgrade-review`, `al-style-review`, `al-ui-review` — 6 leaves. Each reads its upstream skill file plus the matching BCApps review prompt.
  - `bcq-write-knowledge` — guided custom-layer authoring with admission test + validator.
- **9 commands**:
  - `/bcq-review` — comprehensive review via al-entry → al-code-review.
  - `/bcq-review-performance`, `/bcq-review-security`, `/bcq-review-privacy`, `/bcq-review-upgrade`, `/bcq-review-style`, `/bcq-review-ui` — targeted single-leaf reviews via `narrower-sub-skill-selected` routing.
  - `/bcq-write-knowledge` — author a custom-layer article.
  - `/bcq-update` — refresh all vendored upstream content (delegates to per-source vendor scripts).

### Plugin totals after Phase 4

- **39 slash commands** (incl. user-added `/al-setup`)
- **13 skills**: business-central-al-tdd, al-build-and-publish, al-go-lifecycle, al-scaffold-module + 9 BCQuality skills (al-entry, al-code-review super, 6 leaves, bcq-write-knowledge)
- **12 rules**: 6 always-on (al-overview, al-naming-and-files, al-labels-and-locked, al-license-header, al-xmldoc-public-procedures, al-testing-now-always-on) + 1 pattern-matched (al-workflow) + 5 agent-requestable (al-mcp-usage + 4 bcquality contracts)
- **1 hook** + **1 MCP config**
- **7 scripts**: session-start-context.sh, check-altool.sh, vendor-bcapps.sh, vendor-bcquality.sh, validate-bcquality-frontmatter.py, render-findings.py, render-findings.sh
- **426 vendored upstream content files**: 16 BCApps + 410 BCQuality, all SHA-pinned in `content/PINNED.json`

## [0.4.0] — 2026-05-25

### Added — BCApps quality baseline (Phase 3)

- **Vendored upstream content** at pinned SHA `dc1242e3` from `microsoft/BCApps`:
  - 9 analyzer rulesets in `content/bcapps-rulesets/` (master `ruleset.json` plus per-cop sets and the `internal.module` + `minorrelease` overlays).
  - BCApps `DefaultSettings.json` in `content/bcapps-defaults/`.
  - 6 MIT AI code-review prompts in `content/bcapps-review-prompts/` (security, performance, style, accessibility, upgrade, privacy — these also feed Phase 4).
  - `content/PINNED.json` records the SHA, fetched-at date, and per-category file lists.
- **`scripts/vendor-bcapps.sh`** — idempotent vendor script. Supports `--latest` to bump and `--ref <sha>` to pin. Re-runs update `PINNED.json` automatically. Validates every fetched JSON parses.
- **5 always-on rules** auto-applied to `**/*.al`:
  - `al-overview` — terse plugin-capability summary so the agent knows what tools and commands are on hand.
  - `al-naming-and-files` — PascalCase identifiers, the `<Object>.<Type>.al` filename pattern with detection for repo-specific overrides (e.g. TAG's `[Type] [ID] - TAG [Name].al`), namespace and `using` order, ≤30-char object names, lowercase reserved keywords, record-variable naming, parameter-naming with repo-convention detection, var-block declaration order.
  - `al-labels-and-locked` — `Err`/`Msg`/`Qst`/`Lbl`/`Tok`/`Txt` suffixes (CodeCop AA0074), mandatory `Comment` for placeholders, `Locked = true` for URLs/tokens/telemetry, and "never wrap `Error`/`Message`/`Confirm` with `StrSubstNo` or string concatenation".
  - `al-license-header` — the standard 4-line license block at the top of every `.al` file, with publisher-line configurability for partners and a documented opt-out path.
  - `al-xmldoc-public-procedures` — XML doc on every `Access = Public` codeunit procedure, integration event, internal event, and interface method.
- **2 commands**:
  - `/al-apply-rulesets` — drops the 9 vendored rulesets into the workspace and wires `.AL-Go/settings.json` + `.vscode/settings.json` to consume them. Includes guidance on the `custom.ruleset.json` overlay pattern for per-repo exceptions.
  - `/al-apply-vscode-defaults` — merges Microsoft's BCApps `DefaultSettings.json` into the workspace's `.vscode/settings.json` preserving existing keys.
- **1 new skill**: `al-scaffold-module` — project-layout-aware module scaffolder. Detects BCApps `src/<Module>/src/` vs TAG-style `BC/{API,CodeUnit,Enums,...}` layouts (or asks when ambiguous), then generates a coherent set of AL files following the detected convention. Includes the BCApps facade-Codeunit + Internal Impl pattern, four-tier permission sets, and TAG-style numeric-ID-first filenames + `verosoftdesign`/`tag`/`v1.0` API triplet.

### Changed

- **`rules/al-testing.mdc`** — expanded to mandate `Library Assert` (codeunit **130002**, the BCApps test-libraries codeunit, NOT the legacy NAV codeunit 9), `EventSubscriberInstance = Manual` on every test codeunit, `[TransactionModel(...)]` matching the production code's `Commit` behavior, Given/When/Then narrative comments, and the standard test-app dependency set (`Library Assert`, `Any`, `Library Variable Storage`, `Permissions Mock`). Glob now also matches `**/test/**`, `**/Test/**`, `**/Tests/**`. `alwaysApply: true`.
- **`commands/scaffold-test-codeunit.md`** — full rewrite to the BCApps shape. Now includes `EventSubscriberInstance = Manual`, the Library Assert injection, `[Test] [Scope('OnPrem')] [TransactionModel(...)]` attribute trio, Given/When/Then scaffolding, an `Initialize()` one-shot pattern, a negative-test template, and a handler-procedure template that asserts on UI text. Object ID example moved into TAG's allocated range (`70015100`) instead of Microsoft's reserved `50100`.
- **`skills/business-central-al-tdd/SKILL.md`** — aligned with `al-testing.mdc`. Now references Library Assert explicitly, the TransactionModel decision table, the standard test-app dependencies, and the `/al-add-test-app` + `/scaffold-test-codeunit` chain for setting up tests from scratch.

### Plugin totals after Phase 3

- 29 slash commands
- 4 skills
- 7 rules (5 always-on, 2 agent-requestable)
- 1 hook
- 1 MCP config
- 16 vendored upstream content files (~1.5 MB, MIT-licensed, SHA-pinned)

## [0.3.0] — 2026-05-25

### Added — AL-Go lifecycle commands (Phase 2)

- **`skills/al-go-lifecycle/SKILL.md`** + **`workflows.md`** — orchestration skill plus a full inventory of every AL-Go workflow (CI/CD, PR Build, Create release, Publish To Environment, Publish To AppSource, Update AL-Go System Files, Test Current / Next Minor / Next Major, Troubleshooting, Power Platform sync, reusable build sub-workflows) with triggers, inputs, secret needs, and gotchas.
- **Scaffolding commands** (5): `/al-new-pte`, `/al-new-appsource`, `/al-add-test-app`, `/al-add-bcpt-app`, `/al-import-existing-app`.
- **Dev-environment command** (1): `/al-create-online-dev-env`.
- **CI/CD-driven commands** (4): `/al-publish-to-environment`, `/al-current`, `/al-next-minor`, `/al-next-major`.
- **Maintenance commands** (2): `/al-troubleshoot`, `/al-update-system-files`.
- **Release & ship commands** (4): `/al-increment-version`, `/al-release`, `/al-publish-appsource` (with `GoLive` gate), `/al-deploy-docs`.
- **Secrets wizards** (2): `/al-secrets-setup` (interactive minting via BcContainerHelper helpers), `/al-init-keyvault` (Azure KV wiring with federated-credential + KV codesign paths).
- **Compound command** (1): `/al-go-live` — full sandbox-publish → release → AppSource flow with confirmation gates at every destructive step.

### Notes

- Every command honors AL-Go's deprecation calendar (does NOT use `unusedALGoSystemFiles`, `alwaysBuildAllProjects`, `<workflow>Schedule` dynamic, or `cleanModePreprocessorSymbols`).
- AL-Go version is discovered from `.github/AL-Go-Settings.json` → `templateUrl` at run time. Nothing pins `@v9.0`.
- Production deployments and AppSource Go Live require explicit user confirmation containing the matching keyword in the current turn.

## [0.2.0] — 2026-05-25

### Added — AL MCP wiring + inner-loop commands (Phase 1)

- **`mcp.json`** — registers the official Microsoft AL MCP server (`altool launchmcpserver --transport stdio`). The agent can now build, compile, publish, download symbols, search symbols, and read diagnostics natively.
- **`rules/al-mcp-usage.mdc`** — agent-requestable reference for the 9 AL MCP tools, the `al_symbolsearch` parameter-wrapping quirk, the analyzer placeholders (`${CodeCop}`, `${AppSourceCop}`, `${PerTenantExtensionCop}`, `${UICop}`), and the three canonical workflows.
- **`commands/al-symbols.md`** — wraps `al_downloadsymbols`, with `globalSourcesOnly: true` for offline/CI use.
- **`commands/al-symbol-search.md`** — wraps `al_symbolsearch`, handles the required `parameters` wrapper.
- **`commands/al-compile.md`** — wraps `al_compile` for fast validation without producing a `.app`.
- **`commands/al-build.md`** — wraps `al_build` to produce a `.app` with optional analyzers.
- **`commands/al-publish-sandbox.md`** — wraps `al_auth_login` + `al_publish` for cloud and on-prem deployments.
- **`skills/al-build-and-publish/SKILL.md`** — orchestrates the AL MCP tools into the validate-only, build-and-deploy, and AppSourceCop-gate workflows.

### Changed

- Plugin description rewritten to reflect the full-lifecycle pitch.
- Plugin keywords expanded to include `mcp`, `altool`, `al-mcp`, `lifecycle`.

### Notes

- Requires `altool` on PATH. Install the [VS Code AL Language extension](https://marketplace.visualstudio.com/items?itemName=ms-dynamics-smb.al) or the [`Microsoft.Dynamics.BusinessCentral.Development.Tools`](https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-tool-package) NuGet package.
- Existing TDD content (the `business-central-al-tdd` skill, the `al-workflow` and `al-testing` rules, the three scaffolding commands, and the session-start hook) is preserved unchanged. Phase 3 will update `al-testing` to mandate `Library Assert` (codeunit 130002) and Given/When/Then comments.

## [0.1.0] — 2026-03-26

### Added — Initial release

- `skills/business-central-al-tdd/` — TDD-first guidance for Business Central AL.
- `rules/al-workflow.mdc`, `rules/al-testing.mdc` — lightweight contextual rules for AL repositories.
- `commands/tdd-checklist.md`, `commands/scaffold-test-codeunit.md`, `commands/scaffold-handler-methods.md` — template-style helpers.
- `hooks/hooks.json` + `scripts/session-start-context.sh` — session-start reminder for AL work.

[Unreleased]: https://github.com/verosoft/cursor-plugin-marketplace/compare/business-central-al-v0.6.0...HEAD
[0.6.0]: https://github.com/verosoft/cursor-plugin-marketplace/compare/business-central-al-v0.5.0...business-central-al-v0.6.0
[0.5.0]: https://github.com/verosoft/cursor-plugin-marketplace/compare/business-central-al-v0.4.0...business-central-al-v0.5.0
[0.4.0]: https://github.com/verosoft/cursor-plugin-marketplace/compare/business-central-al-v0.3.0...business-central-al-v0.4.0
[0.3.0]: https://github.com/verosoft/cursor-plugin-marketplace/compare/business-central-al-v0.2.0...business-central-al-v0.3.0
[0.2.0]: https://github.com/verosoft/cursor-plugin-marketplace/compare/business-central-al-v0.1.0...business-central-al-v0.2.0
[0.1.0]: https://github.com/verosoft/cursor-plugin-marketplace/releases/tag/business-central-al-v0.1.0
