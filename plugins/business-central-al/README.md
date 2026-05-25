# business-central-al

A Cursor plugin for the full lifecycle of Microsoft Dynamics 365 Business Central AL extension development — from scaffolding through coding, testing, debugging, publishing, and shipping to AppSource.

Currently at **v0.6.0** — all 5 phases of the original rebuild shipped. Phase 6 (BC runtime MCP) remains deferred per the original plan. Roadmap below.

## What's in the box (v0.6.0)

### Inner dev loop — via the AL MCP

The plugin wires the official Microsoft AL MCP server (`altool launchmcpserver`) so the Cursor agent can:

- Compile, build, publish AL apps natively.
- Download and search symbols.
- Read filtered diagnostics with stable diagnostic codes.

Five inner-loop skills wrap the AL MCP tools (each with `disable-model-invocation: true` so they only fire when you type the slash), plus an orchestration skill (`al-build-and-publish`) that chains them into the canonical validate / build-and-deploy / AppSourceCop workflows.

### Full AL-Go lifecycle — via `gh workflow run`

Nineteen slash-invokable skills wrap [AL-Go for GitHub](https://github.com/microsoft/AL-Go) workflows:

- **Scaffold** a new PTE or AppSource repo, add test apps, import existing `.app` artifacts.
- **CI/CD** — promote builds to specific environments, re-test against current / next minor / next major BC versions.
- **Release** — increment versions, cut GitHub releases, ship to AppSource (with explicit Go Live gates), deploy aldoc reference docs.
- **Maintenance** — refresh AL-Go system files, diagnose configuration issues, wire secrets and Azure Key Vault.
- **Compound** — `/al-go-live` walks the full sandbox-publish → release → AppSource flow with confirmation gates at every destructive step.

### BCApps quality baseline (new in 0.4.0)

The plugin now bundles Microsoft's own AL quality bar from `microsoft/BCApps`, pinned to a specific commit SHA in `content/PINNED.json`:

- **9 analyzer rulesets** in `content/bcapps-rulesets/` — drop them into the workspace via `/al-apply-rulesets` to hold the project to the same bar Microsoft holds itself to.
- **BCApps VS Code defaults** in `content/bcapps-defaults/` — apply via `/al-apply-vscode-defaults`.
- **6 MIT AI code-review prompts** in `content/bcapps-review-prompts/` (security, performance, style, accessibility, upgrade, privacy) — Phase 4's BCQuality review skills will consume them.
- **5 always-on rules** auto-applied to `*.al` files: `al-overview`, `al-naming-and-files`, `al-labels-and-locked`, `al-license-header`, `al-xmldoc-public-procedures`.
- **`al-scaffold-module` skill** — project-layout-aware. Detects BCApps `src/<Module>/src/` vs TAG-style `BC/{API,CodeUnit,Enums,...}` layouts, then generates a coherent set of AL files (facade Codeunit + Internal Impl pair, four-tier permission sets, license header, namespace) following the detected convention.
- **`scripts/vendor-bcapps.sh`** — idempotent vendor script. Refresh with `--latest` to bump to current main, or `--ref <sha>` to pin to a specific commit. Re-runs update `PINNED.json` automatically.

### TDD baseline (updated in 0.4.0)

The `business-central-al-tdd` skill, the `al-testing` rule, and the `/scaffold-test-codeunit` command are now aligned with BCApps test conventions: `Library Assert` (codeunit **130002**, NOT legacy NAV codeunit 9), `EventSubscriberInstance = Manual`, `[TransactionModel(...)]` matching the production code's `Commit` behavior, and Given/When/Then narrative comments.

### BC-Bench-informed test generation and AL docs (new in 0.6.0)

The plugin now ships with the measured-winner test-generation prompt plus a full AL documentation skill, both vendored from MIT Microsoft sources:

- **ALTest domain-agent prompt** (`content/altest-prompt/ALTest.agent.md`) — vendored from `microsoft/BC-Bench` at pinned SHA `ef4f4668`. BC-Bench measured this prompt at **+10.7 pt mean and ~2x pass^5** on AL test generation. Invoked via `/al-write-test` or the `al-write-test` skill (auto-triggers when the user asks to write tests).
- **AL docs hierarchical-documentation skill** (`content/al-docs-references/`) — vendored from `microsoft/BCApps/tools/al-docs-plugin/`. 1150 lines across init/update/audit modes. Generates `data-model.md`, `business-logic.md`, `extensibility.md`, `patterns.md` for an AL codebase. Invoked via `/al-docs` (`init`/`update`/`audit` modes) or the `al-docs` skill.
- **Session-start model recommendation** — `scripts/session-start-context.sh` now surfaces BC-Bench's measured top models at session start: Claude Opus 4.7 (highest accuracy), Sonnet 4.6 (best cost/quality), `gpt-5.3-codex` (~3x faster). Warns against `gpt-4.1` (measured at 16.6% on AL — effectively unusable).
- **userPromptSubmit hook** — `scripts/detect-al-repo.sh` walks up from the user's cwd looking for `app.json` and `.AL-Go/settings.json`. When found, emits BC project metadata (name, publisher, app version, runtime, platform, target, AL-Go type/country/templateUrl) as `additional_context` on every prompt. The agent no longer needs to re-parse `app.json` itself.

### BCQuality structured review (new in 0.5.0)

The plugin now embeds the full BCQuality contract — Microsoft's machine-readable AL review system, pinned at SHA `4d59fb73` in `content/PINNED.json`.

- **154 knowledge articles + 234 AL samples** vendored in `content/bcquality/{microsoft,community}/knowledge/` across 7 domains (performance, privacy, security, style, testing, ui, upgrade) — every article passes the upstream R01–R25 frontmatter validator.
- **4 meta-skill contracts** (entry, READ, DO, WRITE) at `content/bcquality/` root, exposed to the agent via 4 agent-requestable rules.
- **`al-code-review` super-skill** that composes 6 leaf review skills (performance, security, privacy, upgrade, style, UI) and runs an agent self-review pass producing knowledge-validated agent findings.
- **Strict JSON output contract** (DO) with `outcome`, `findings[]` (severity, message, location, references, confidence, from-sub-skill), `suppressed[]`, `sub-results[]`. Identical shape to what AL-Go consumes in CI.
- **Layered knowledge** with `custom` > `community` > `microsoft` precedence — conflicts auto-resolve and the loser surfaces in `suppressed[]`.
- **Pre-seeded TAG custom layer** with 8 articles distilled from the user's existing tag-bc `.cursor/rules/` (object ID ranges, the `[Type] [ID] - TAG [Name].al` filename pattern, the `"TAG "` affix, the `BC/{API,CodeUnit,...}` folder layout, the `p`-prefix on parameters, the TAG variable vocabulary, the `verosoftdesign/tag/v1.0` API triplet, the CLEAN preprocessor pattern). Several CONTRADICT BCApps defaults and win on layer precedence.
- **Vendored 586-line upstream validator** at `scripts/validate-bcquality-frontmatter.py`. Runs after every refresh.
- **Findings renderer** (`scripts/render-findings.py` + `.sh` wrapper) for human-readable terminal output.
- **`/bcq-update`** refreshes all vendored sources (BCApps + BCQuality) and re-runs the validator.

## Roadmap

| Phase                       | Status    | Scope                                                                                                                                                                           |
| --------------------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1 — AL MCP inner loop       | ✅ v0.2.0 | build / compile / publish / symbols / diagnostics                                                                                                                               |
| 2 — AL-Go lifecycle         | ✅ v0.3.0 | 19 slash-invokable skills wrapping AL-Go workflows for scaffold → CI/CD → release → AppSource                                                                                    |
| 3 — BCApps quality baseline | ✅ v0.4.0 | vendored rulesets + VS Code defaults + 6 MIT review prompts; 5 always-on style rules; project-layout-aware module scaffolder; Library Assert testing baseline                   |
| 4 — BCQuality review        | ✅ v0.5.0 | 154+ knowledge articles, super-skill + 6 leaves, strict JSON contract, layered knowledge with TAG custom layer pre-seeded, upstream validator, findings renderer                |
| 5 — BC-Bench wins           | ✅ v0.6.0 | ALTest domain-agent test-generation prompt (+10.7 pt measured), BCApps al-docs skill (init/update/audit), session-start model recommendation, userPromptSubmit BC-metadata hook |
| 6 — BC runtime MCP          | Deferred  | hosted Business Central MCP for chat over BC data                                                                                                                               |

See `../../docs/business-central-al-rebuild/PLAN.md` for the full design.

## Prerequisites

### `altool` (for the AL MCP)

The AL MCP server needs `altool` (or `al`) on PATH.

**Easiest path:** after enabling the plugin, ask the agent to run `/al-setup`. It probes for the binaries, walks you through installation with explicit confirmation before anything runs, and fixes the `altool`/`al` alias mismatch if needed. The session-start hook also reports the current AL MCP status at the start of every Cursor chat.

If you'd rather install manually, pick **one** of:

- **VS Code AL Language extension** — `code --install-extension ms-dynamics-smb.al`. Includes `altool` under `~/.vscode/extensions/ms-dynamics-smb.al-*/bin/<os>/altool[.exe]`. Add that folder to PATH, or alias it.
- **AL Development Tools NuGet package** — `dotnet tool install --global Microsoft.Dynamics.BusinessCentral.Development.Tools`. Provides the cross-platform `al` binary in `~/.dotnet/tools`. Requires .NET 8 SDK. After install, either symlink `al` as `altool` (`ln -sf "$(command -v al)" ~/.local/bin/altool`) or edit `mcp.json` to use `"command": "al"` — `/al-setup` does either with your permission.

Restart Cursor after install so the MCP server picks up the new binary.

### `gh` CLI (for AL-Go lifecycle commands)

```bash
gh auth login          # one-time, with `workflow` scope
gh auth refresh -s workflow   # if you already authenticated without workflow scope
```

The agent invokes `gh workflow run` for every lifecycle command.

### BcContainerHelper (for `/al-secrets-setup`)

PowerShell 7+ on Windows/macOS/Linux (or PS 5.1 on Windows). Then:

```powershell
Install-Module BCContainerHelper -AllowPrerelease
```

Provides the `New-BcAuthContext` / `New-ALGo*Context` helpers that mint AL-Go's JSON-shaped secrets.

## Installation

Add this plugin via the marketplace, or place a copy at `~/.cursor/plugins/local/business-central-al/`.

Verify the AL MCP wiring by asking the agent in a Cursor chat:

> Use `al_symbolsearch` to find codeunits matching "Customer" in this project.

## Components

### Skills

| Skill                     | Purpose                                                                                                                                                                                                                       |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `business-central-al-tdd` | TDD-first workflow for AL behavior changes. Aligned with BCApps `Library Assert` conventions in v0.4.0.                                                                                                                       |
| `al-build-and-publish`    | Orchestrates the AL MCP tools into the validate / build-and-deploy / AppSourceCop workflows.                                                                                                                                  |
| `al-go-lifecycle`         | Orchestrates AL-Go workflows via `gh workflow run`. Handles preflight checks (repo detection, secret presence), dispatch, run-watching, and failure summarization. References `workflows.md` for the full workflow inventory. |
| `al-scaffold-module`      | Project-layout-aware module scaffolder. Detects BCApps `src/<Module>/src/` vs TAG-style `BC/{API,CodeUnit,Enums,...}` layouts, then generates a coherent set of AL files following the detected convention.                   |
| `al-entry`                | BCQuality entry-point router. Reads the task context, applies BCQuality's routing rules, and dispatches the named action skill(s).                                                                                            |
| `al-code-review`          | BCQuality super-skill. Composes the 6 leaf reviews + agent self-review pass. Emits a strict findings-report JSON per the DO contract.                                                                                         |
| `al-performance-review`   | BCQuality leaf. SetLoadFields ordering, FindSet variants, IsEmpty vs Count > 0, Commit-in-loops, etc.                                                                                                                         |
| `al-security-review`      | BCQuality leaf. SecretText, NonDebuggable, IsolatedStorage scope, IntegrationEvent var-parameter bypass, permission grants.                                                                                                   |
| `al-privacy-review`       | BCQuality leaf. DataClassification, PII in telemetry, error-text leakage. Excludes test code.                                                                                                                                 |
| `al-upgrade-review`       | BCQuality leaf. Enum-ordinal shifts (blocker), obsoletion staging, Upgrade Tags vs DataVersion checks, InitValue on existing tables.                                                                                          |
| `al-style-review`         | BCQuality leaf. Label suffixes, Locked, ToolTip, API-page naming. Honors TAG custom-layer overrides where they contradict BCApps defaults.                                                                                    |
| `al-ui-review`            | BCQuality leaf. ShowCaption, grid semantics, accessibility, control-add-in JS. Includes anti-false-positive guidance.                                                                                                         |
| `bcq-write-knowledge`     | Guided authoring for custom-layer knowledge articles. Applies the admission test, validates frontmatter via the upstream R01–R25 validator.                                                                                   |
| `al-write-test`           | Generate an AL test using the BC-Bench-measured ALTest domain-agent prompt (+10.7 pt vs baseline). Auto-invokes when the user asks to write, scaffold, or generate AL tests.                                                  |
| `al-docs`                 | Generate, refresh, or audit hierarchical AL documentation (init / update / audit modes). Wraps BCApps' MIT-licensed `al-docs-plugin`.                                                                                         |

### Rules

**Always-on (auto-applied to AL source):**

| Rule                          | Scope                                                                                                                                        |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `al-overview`                 | Plugin-capability summary so the agent knows what commands and skills are on hand. Pattern-matched on `app.json` and AL files.               |
| `al-workflow`                 | General AL repository workflow. Pattern-matched on `*.al` and `app.json`.                                                                    |
| `al-testing`                  | BCApps-aligned testing rules: `Library Assert` (codeunit 130002), `EventSubscriberInstance = Manual`, `[TransactionModel]`, Given/When/Then. |
| `al-naming-and-files`         | PascalCase identifiers, `<Object>.<Type>.al` filename pattern (with detection for repo-specific overrides), namespace and `using` order.     |
| `al-labels-and-locked`        | `Err`/`Msg`/`Qst`/`Lbl`/`Tok`/`Txt` suffixes (CodeCop AA0074), `Comment` for placeholders, `Locked = true` for URLs/tokens/telemetry.        |
| `al-license-header`           | Standard 4-line license block; publisher line configurable per repo.                                                                         |
| `al-xmldoc-public-procedures` | XML doc on every `Access = Public` codeunit procedure, integration event, internal event, and interface method.                              |

**Agent-requestable (loaded on demand):**

| Rule                       | Scope                                                                                                                        |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `al-mcp-usage`             | AL MCP tool catalog + the `al_symbolsearch` parameter-wrapper quirk.                                                         |
| `bcquality-read-contract`  | BCQuality READ contract pointer — frontmatter schema, sections, layer precedence, matching semantics, citation references.   |
| `bcquality-do-contract`    | BCQuality DO contract pointer — action-skill template, strict JSON output schema, severity, agent-findings encoding, rollup. |
| `bcquality-entry-contract` | BCQuality routing contract pointer — task-context shape, candidate enumeration, 3-tier worklist ranking, dispatch record.    |
| `bcquality-write-contract` | BCQuality WRITE contract pointer — admission test, frontmatter authoring, pre-PR checklist, R01–R25 validator reference.     |

### Commands

**Setup:**

| Command     | Purpose                                                                                                   |
| ----------- | --------------------------------------------------------------------------------------------------------- |
| `/al-setup` | Diagnose AL MCP prerequisites; (with explicit user permission) install `altool`/`al`. Run first time use. |

**Inner dev loop (Phase 1):**

| Command               | Wraps                                                |
| --------------------- | ---------------------------------------------------- |
| `/al-symbols`         | `al_downloadsymbols`                                 |
| `/al-symbol-search`   | `al_symbolsearch` (handles the `parameters` wrapper) |
| `/al-compile`         | `al_compile`                                         |
| `/al-build`           | `al_build`                                           |
| `/al-publish-sandbox` | `al_auth_login` + `al_publish`                       |

**AL-Go lifecycle (Phase 2):**

| Command                      | Wraps                                                  |
| ---------------------------- | ------------------------------------------------------ |
| `/al-new-pte`                | `gh repo create` + `Create a new app`                  |
| `/al-new-appsource`          | `gh repo create` + `Create a new app` (AppSource type) |
| `/al-add-test-app`           | `Create a new test app`                                |
| `/al-add-bcpt-app`           | `Create a new performance test app`                    |
| `/al-import-existing-app`    | `Add existing app or test app`                         |
| `/al-create-online-dev-env`  | `Create Online Dev. Environment`                       |
| `/al-publish-to-environment` | `Publish To Environment` (production-gated)            |
| `/al-current`                | `Test Current`                                         |
| `/al-next-minor`             | `Test Next Minor`                                      |
| `/al-next-major`             | `Test Next Major`                                      |
| `/al-troubleshoot`           | `Troubleshooting`                                      |
| `/al-update-system-files`    | `Update AL-Go System Files`                            |
| `/al-increment-version`      | `Increment Version Number`                             |
| `/al-release`                | `Create release`                                       |
| `/al-publish-appsource`      | `Publish To AppSource` (Go Live gated)                 |
| `/al-deploy-docs`            | `Deploy Reference Documentation`                       |
| `/al-secrets-setup`          | Interactive secret-minting wizard (BcContainerHelper)  |
| `/al-init-keyvault`          | Azure KV wiring + federated credential + KV codesign   |
| `/al-go-live`                | Compound: sandbox → release → AppSource with gates     |

**BCApps quality baseline (Phase 3):**

| Command                     | Purpose                                                                                                      |
| --------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `/al-apply-rulesets`        | Drop Microsoft's 9 vendored analyzer rulesets into the workspace and wire AL-Go + VS Code to consume them.   |
| `/al-apply-vscode-defaults` | Merge BCApps' `DefaultSettings.json` into the workspace's `.vscode/settings.json`, preserving existing keys. |

**BCQuality review (Phase 4):**

| Command                   | Purpose                                                                                                               |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `/bcq-review`             | Comprehensive AL review via the al-code-review super-skill (6 leaves + agent self-review pass).                       |
| `/bcq-review-performance` | Targeted review — performance leaf only.                                                                              |
| `/bcq-review-security`    | Targeted review — security leaf only.                                                                                 |
| `/bcq-review-privacy`     | Targeted review — privacy leaf only (excludes test code).                                                             |
| `/bcq-review-upgrade`     | Targeted review — upgrade leaf (enum shifts, obsoletion, Upgrade Tags, DataTransfer).                                 |
| `/bcq-review-style`       | Targeted review — style leaf (Labels, captions, API-page naming, file naming with TAG custom-layer overrides).        |
| `/bcq-review-ui`          | Targeted review — UI/accessibility leaf (returns not-applicable when the diff has no page or control-add-in changes). |
| `/bcq-write-knowledge`    | Author a new custom-layer knowledge article. Runs the upstream R01–R25 validator before commit.                       |
| `/bcq-update`             | Refresh all vendored upstream content (BCApps + BCQuality). Re-runs the validator. Updates `content/PINNED.json`.     |

**BC-Bench wins (Phase 5):**

| Command          | Purpose                                                                                                                              |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------ |
| `/al-write-test` | Generate an AL test using the BC-Bench ALTest domain-agent prompt (+10.7 pt mean and ~2x pass^5 measured against Opus 4.6 baseline). |
| `/al-docs`       | Generate, refresh, or audit hierarchical AL documentation (init / update / audit modes).                                             |

**TDD baseline:**

| Command                     | Purpose                                                                                          |
| --------------------------- | ------------------------------------------------------------------------------------------------ |
| `/tdd-checklist`            | AL-specific TDD checklist                                                                        |
| `/scaffold-test-codeunit`   | Drop a BCApps-style test codeunit skeleton (Library Assert, `EventSubscriberInstance = Manual`). |
| `/scaffold-handler-methods` | Drop handler method templates                                                                    |

### Hooks

- `sessionStart` — `scripts/session-start-context.sh` injects an AL-focused reminder when an agent session begins, including the live AL MCP probe status and the BC-Bench-measured model recommendation.
- `userPromptSubmit` — `scripts/detect-al-repo.sh` enriches every prompt with BC project metadata (publisher, version, runtime, AL-Go config) when the user is in an AL workspace. Best-effort; emits empty `{}` when no AL workspace is detected.

### MCP

- `mcp.json` — registers the `al` server (`altool launchmcpserver --transport stdio`). The Business Central runtime MCP (`https://mcp.businesscentral.dynamics.com`) is deferred to Phase 6.

## Safety rules baked into the lifecycle commands

- **Production deployments** require explicit user confirmation containing the word "production" in the current turn. AL-Go's `(PROD)` / `(FAT)` environment-name convention is honored.
- **AppSource Go Live** requires explicit user confirmation containing "go live" or "production". Default is Preview-only submission.
- **`Update AL-Go System Files`** defaults to PR mode (not direct commit) so changes are reviewable.
- **`/al-publish-sandbox` with destructive schema modes** (`ForceSync`, `Recreate`) require restated confirmation.
- **First AppSource upload** is surfaced as manual (marketing materials cannot be automated through Partner Center API).

## License

MIT. See `LICENSE`.

## Authoring notes

Working notes for maintainers live under `../../docs/business-central-al-rebuild/`:

- `PLAN.md` — full file inventory across all phases.
- `DECISIONS.md` — locked-in decisions and the vendoring contract.
- `PROGRESS.md` — phase-by-phase checklist.
- `GOTCHAS.md` — the small print from upstream Microsoft docs.
- `TAG_CUSTOM_LAYER.md` — TAG-specific BCQuality articles for Phase 4.
- `research/` — the four exhaustive research dossiers backing the plan.
