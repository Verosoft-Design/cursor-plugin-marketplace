# Master Plan — business-central-al v0.2.0

> Authored 2026-05-25. Source of truth for the rebuild. Update this file when the design changes.

## Target plugin location

`/Users/alexisturgeon/Source/cursor-plugin-marketplace/plugins/business-central-al/`

Same plugin name, same marketplace.json entry, version bumped from `0.1.0` → `0.2.0`.

## Final file tree

```
plugins/business-central-al/
├── .cursor-plugin/plugin.json                          # bump version to 0.2.0
├── README.md                                           # rewritten — lifecycle pitch + Phase 1–5 coverage
├── CHANGELOG.md                                        # NEW — semantic versioning
├── LICENSE                                             # kept
├── assets/logo.svg                                     # kept
│
├── mcp.json                                            # NEW — AL MCP wired (BC MCP deferred)
│
├── rules/
│   ├── al-overview.mdc                                 # NEW — always-on, terse framing
│   ├── al-naming-and-files.mdc                         # NEW — BCApps file naming + namespace
│   ├── al-labels-and-locked.mdc                        # NEW — Err/Msg/Qst/Lbl/Tok/Txt + Locked
│   ├── al-license-header.mdc                           # NEW — strict by default; header text configurable
│   ├── al-xmldoc-public-procedures.mdc                 # NEW — XML doc on Access = Public
│   ├── al-workflow.mdc                                 # KEPT (currently in plugin)
│   ├── al-testing.mdc                                  # KEPT + updated: Library Assert (codeunit 130002), EventSubscriberInstance = Manual, [TransactionModel] matching Commit, Given/When/Then comments
│   ├── bcquality-read-contract.mdc                     # NEW (Phase 4) — agent-requestable: READ semantics
│   ├── bcquality-do-contract.mdc                       # NEW (Phase 4) — agent-requestable: DO output schema
│   ├── bcquality-entry-contract.mdc                    # NEW (Phase 4) — agent-requestable: routing rules
│   ├── bcquality-write-contract.mdc                    # NEW (Phase 4) — agent-requestable: WRITE
│   └── al-mcp-usage.mdc                                # NEW (Phase 1) — agent-requestable: AL MCP tool catalog + the al_symbolsearch `parameters` wrapper quirk
│
├── skills/
│   ├── business-central-al-tdd/                        # KEPT (lightly updated)
│   │   ├── SKILL.md                                    # update to mandate Library Assert (codeunit 130002)
│   │   └── reference.md
│   ├── al-entry/SKILL.md                               # NEW (Phase 4)
│   ├── al-code-review/SKILL.md                         # NEW (Phase 4) — super-skill
│   ├── al-performance-review/SKILL.md                  # NEW (Phase 4) — leaf
│   ├── al-security-review/SKILL.md                     # NEW (Phase 4) — leaf
│   ├── al-privacy-review/SKILL.md                      # NEW (Phase 4) — leaf
│   ├── al-upgrade-review/SKILL.md                      # NEW (Phase 4) — leaf
│   ├── al-style-review/SKILL.md                        # NEW (Phase 4) — leaf
│   ├── al-ui-review/SKILL.md                           # NEW (Phase 4) — leaf
│   ├── al-write-test/SKILL.md                          # NEW (Phase 5) — adapted from BC-Bench ALTest.agent.md
│   ├── al-scaffold-module/SKILL.md                     # NEW (Phase 3) — BCApps-style facade+Impl module
│   ├── al-build-and-publish/SKILL.md                   # NEW (Phase 1) — wraps the AL MCP build→publish flow
│   ├── al-go-lifecycle/                                # NEW (Phase 2)
│   │   ├── SKILL.md
│   │   └── workflows.md                                # Inventory of every AL-Go workflow + inputs
│   ├── al-docs/                                        # NEW (Phase 5) — adapted from BCApps tools/al-docs-plugin
│   │   ├── SKILL.md
│   │   ├── init.md
│   │   ├── update.md
│   │   └── audit.md
│   └── bcq-write-knowledge/SKILL.md                    # NEW (Phase 4) — guides authoring custom kb files
│
├── commands/                                           # / slash commands
│   # KEPT
│   ├── tdd-checklist.md                                # KEPT
│   ├── scaffold-test-codeunit.md                       # KEPT (update for Library Assert)
│   ├── scaffold-handler-methods.md                     # KEPT
│
│   # Phase 1 — AL MCP inner dev loop
│   ├── al-symbols.md                                   # al_downloadsymbols
│   ├── al-symbol-search.md                             # al_symbolsearch
│   ├── al-compile.md                                   # al_compile + al_getdiagnostics
│   ├── al-build.md                                     # al_build
│   ├── al-publish-sandbox.md                           # al_auth_login + al_publish
│
│   # Phase 2 — AL-Go scaffold + CI/CD + ship
│   ├── al-new-pte.md
│   ├── al-new-appsource.md
│   ├── al-add-test-app.md
│   ├── al-add-bcpt-app.md
│   ├── al-import-existing-app.md
│   ├── al-create-online-dev-env.md
│   ├── al-publish-to-environment.md
│   ├── al-current.md
│   ├── al-next-minor.md
│   ├── al-next-major.md
│   ├── al-troubleshoot.md
│   ├── al-update-system-files.md
│   ├── al-increment-version.md
│   ├── al-release.md
│   ├── al-publish-appsource.md
│   ├── al-deploy-docs.md
│   ├── al-secrets-setup.md
│   ├── al-init-keyvault.md
│   ├── al-go-live.md                                   # compound: build→publish→test→release→AppSource
│
│   # Phase 3 — BCApps quality baseline
│   ├── al-apply-rulesets.md
│   ├── al-apply-vscode-defaults.md
│
│   # Phase 4 — BCQuality review
│   ├── bcq-review.md
│   ├── bcq-review-performance.md
│   ├── bcq-review-security.md
│   ├── bcq-review-privacy.md
│   ├── bcq-review-style.md
│   ├── bcq-review-upgrade.md
│   ├── bcq-review-ui.md
│   ├── bcq-write-knowledge.md
│   └── bcq-update.md
│
├── hooks/
│   └── hooks.json                                      # KEPT + extended (userPromptSubmit added in Phase 5)
│
├── scripts/
│   ├── session-start-context.sh                        # KEPT + expanded (BC-Bench model recommendations in Phase 5)
│   ├── detect-al-repo.sh                               # NEW (Phase 5) — sets env vars in AL workspaces
│   ├── vendor-bcquality.sh                             # NEW (Phase 4)
│   ├── vendor-rulesets.sh                              # NEW (Phase 3)
│   ├── vendor-bcapps-prompts.sh                        # NEW (Phase 3 or 4)
│   ├── vendor-altest-prompt.sh                         # NEW (Phase 5)
│   ├── validate-bcquality-frontmatter.py               # NEW (Phase 4) — vendored upstream R01–R25 validator
│   └── render-findings.sh                              # NEW (Phase 4) — pretty-prints findings-report JSON
│
└── content/                                            # NEW — vendored upstream content
    ├── PINNED.json                                     # NEW (Phase 3 onwards) — SHAs + fetched-at dates
    ├── bcquality/                                      # NEW (Phase 4)
    │   ├── microsoft/knowledge/<domain>/<slug>.{md,good.al,bad.al}
    │   ├── community/knowledge/<domain>/...
    │   └── custom/knowledge/<domain>/                  # Seeded from TAG_CUSTOM_LAYER.md
    ├── bcapps-rulesets/                                # NEW (Phase 3)
    │   ├── ruleset.json
    │   ├── Analyzer.ruleset.json
    │   ├── AppSourceCop.ruleset.json
    │   ├── CodeCop.ruleset.json
    │   ├── Compiler.ruleset.json
    │   ├── PTECop.ruleset.json
    │   ├── UICop.ruleset.json
    │   ├── internal.module.ruleset.json
    │   └── minorrelease.ruleset.json
    ├── bcapps-review-prompts/                          # NEW (Phase 4) — 6 MIT prompts from BCApps tools/Code Review/instructions/
    │   ├── performance.md
    │   ├── security.md
    │   ├── style.md
    │   ├── accessibility.md
    │   ├── upgrade.md
    │   └── privacy.md
    ├── bcapps-defaults/                                # NEW (Phase 3)
    │   └── DefaultSettings.json
    └── altest-prompt/                                  # NEW (Phase 5)
        └── ALTest.agent.md
```

## Phase-by-phase

### Phase 1 — AL MCP wiring + inner-loop commands (~1 day)

**Deliverable:** the agent can build, compile, publish, search symbols, get diagnostics natively from Cursor chat.

Files:
- `mcp.json` (only the `al` server; BC MCP deferred)
- `rules/al-mcp-usage.mdc` (the tool catalog + the `parameters` wrapper quirk for `al_symbolsearch` + the `${CodeCop}`/`${AppSourceCop}` analyzer placeholders)
- `commands/al-symbols.md`, `al-symbol-search.md`, `al-compile.md`, `al-build.md`, `al-publish-sandbox.md`
- `skills/al-build-and-publish/SKILL.md`
- `README.md` install section: how to make `altool` discoverable (VS Code AL extension or `Microsoft.Dynamics.BusinessCentral.Development.Tools` NuGet)
- Update `plugin.json` version → `0.2.0`

Source dossier: `research/algo-mcp-research.md` §7.

### Phase 2 — AL-Go lifecycle commands (~2 days)

**Deliverable:** every CI/CD lifecycle stage drivable from Cursor.

Files:
- `skills/al-go-lifecycle/SKILL.md` + `workflows.md`
- All `commands/al-*` files listed in the tree above (~17 files)
- Update README

Source dossier: `research/algo-mcp-research.md` §2, §3, §4, §6, §10.

**Key gotchas (also in GOTCHAS.md):**
- AL-Go version pin is in `.github/AL-Go-Settings.json` → `templateUrl`; do NOT hardcode `@v9.0`.
- Build job MUST be Windows + Docker. Housekeeping jobs can be `ubuntu-latest`.
- `unusedALGoSystemFiles` deprecated **after 2026-10-01** — use `customALGoFiles.filesToExclude`.
- `alwaysBuildAllProjects` deprecated **after 2025-10-01** — use `incrementalBuilds.onPull_Request: false`.
- First AppSource upload is manual — `/al-publish-appsource` must surface this in the prompt.
- Custom delivery scripts receive `$parameters` hashtable with folder paths that can be `$null`.

### Phase 3 — BCApps quality baseline (~1.5 days)

**Deliverable:** plugin enforces Microsoft's own AL quality bar.

**Prereq:** vendoring decision (Q3) confirmed.

Files:
- `scripts/vendor-rulesets.sh` (pins to a BCApps commit SHA — populates `content/bcapps-rulesets/` and `content/bcapps-defaults/`)
- `content/PINNED.json` (initial entry)
- `commands/al-apply-rulesets.md` (drops the 9 rulesets into `<workspace>/rulesets/`, wires `.AL-Go/settings.json` → `rulesetFile`)
- `commands/al-apply-vscode-defaults.md` (writes `.vscode/settings.json` from `content/bcapps-defaults/DefaultSettings.json`)
- `rules/al-overview.mdc`, `al-naming-and-files.mdc`, `al-labels-and-locked.mdc`, `al-license-header.mdc`, `al-xmldoc-public-procedures.mdc`
- Update `rules/al-testing.mdc` to mandate `Library Assert` (codeunit 130002), `EventSubscriberInstance = Manual`, `[TransactionModel(...)]` matching `Commit`, Given/When/Then comments
- `skills/al-scaffold-module/SKILL.md` (generates a BCApps-style facade + Impl module **with the option to honor existing project layout** — TAG uses BC/{API,CodeUnit,Enums,…} which differs from BCApps)

Source dossier: `research/bcapps-research.md` §3 (rulesets), §4 (CONTRIBUTING + DefaultSettings), §5 (module conventions), §9 (canonical patterns), §10 (recommendations).

### Phase 4 — BCQuality integration (~2-3 days)

**Deliverable:** Microsoft-grade structured AL review with the exact JSON contract AL-Go uses in CI.

**Prereq:** vendoring decision (Q3) confirmed.

Files:
- `scripts/vendor-bcquality.sh` (pulls `microsoft/BCQuality` at a pinned SHA, populates `content/bcquality/{microsoft,community}/`)
- `scripts/vendor-bcapps-prompts.sh` (pulls the 6 MIT review prompts from `microsoft/BCApps/tools/Code Review/instructions/`)
- `scripts/validate-bcquality-frontmatter.py` (vendored copy of upstream's 568-line validator, R01–R25)
- `scripts/render-findings.sh`
- Update `content/PINNED.json`
- `rules/bcquality-read-contract.mdc`, `bcquality-do-contract.mdc`, `bcquality-entry-contract.mdc`, `bcquality-write-contract.mdc` (agent-requestable — verbatim from `skills/entry.md`, `read.md`, `do.md`, `write.md` upstream)
- `skills/al-entry/SKILL.md`
- `skills/al-code-review/SKILL.md` (super-skill composing the 6 leaves + agent self-review pass; must produce DO-contract JSON with `from-sub-skill: "agent"` markers + `references: []` and `confidence ≤ medium` for agent findings)
- `skills/al-performance-review/SKILL.md`, `al-security-review/SKILL.md`, `al-privacy-review/SKILL.md`, `al-upgrade-review/SKILL.md`, `al-style-review/SKILL.md`, `al-ui-review/SKILL.md` (each one with full Source/Relevance/Worklist/Action sections, sourcing from `content/bcquality/*/knowledge/<domain>/*.md` AND cross-referencing `content/bcapps-review-prompts/<domain>.md` for complementary guidance)
- `skills/bcq-write-knowledge/SKILL.md`
- `commands/bcq-review.md`, `bcq-review-{performance,security,privacy,style,upgrade,ui}.md`, `bcq-write-knowledge.md`, `bcq-update.md`
- Seed `content/bcquality/custom/knowledge/` from `TAG_CUSTOM_LAYER.md` (see that file for the 6+ articles to author)

Source dossier: `research/bcquality-research.md` (entire file; §3 contracts, §5 review sub-skills, §6 remedial-knowledge list, §8 integration recommendations).

**Key gotchas:**
- BCQuality is in **active preview** (no releases yet) — pin a SHA and surface it in the status line. README warns of breaking changes.
- The super-skill MUST NOT filter sub-skills by task content (DO contract enforces this).
- `references[0].path` doubles as the finding `id` for citation-based findings; agent findings use `agent:<slug>` prefix.
- `al_ui_review` is the only leaf with `technologies: [al, javascript]` (covers control add-ins).
- `al-privacy-review` MUST exclude test code, test libraries, and `Subtype = Test` objects.

### Phase 5 — BC-Bench-informed quality lifts (~1.5 days)

**Deliverable:** the measured wins from the benchmark — model recommendation, ALTest agent, al-docs skill — baked in.

Files:
- `scripts/vendor-altest-prompt.sh` (pulls `ALTest.agent.md` from BC-Bench MIT source)
- `skills/al-write-test/SKILL.md` (wraps the ALTest prompt with Cursor-native invocation)
- `skills/al-docs/{SKILL.md,init.md,update.md,audit.md}` (adapted from BCApps `tools/al-docs-plugin/skills/al-docs/`)
- `scripts/detect-al-repo.sh` (sets env vars: `BC_PROJECT_PATH`, `BC_APP_VERSION`, `BC_RUNTIME`)
- Update `scripts/session-start-context.sh` to surface BC-Bench's model recommendation (default to Claude Opus 4.6/4.7 or Sonnet 4.6; mention `gpt-5.3-codex` as fast alternative; warn against `gpt-4.1`)
- Update `hooks/hooks.json` to add the `userPromptSubmit` hook running `detect-al-repo.sh`

Source dossier: `research/bcbench-research.md` (entire file; §6 leaderboard, §7.3 ALTest, §10 recommendations).

### Phase 6 — BC MCP runtime layer (DEFERRED per Decision Q4)

Not built in this rebuild. Documented in README as "coming later". File listing kept for future reference (see the original plan in chat).

## Cross-phase coordination

- Bump `version` in `.cursor-plugin/plugin.json` from `0.1.0` → `0.2.0` at the end of Phase 1 (the moment we ship a real change).
- Update `CHANGELOG.md` at the end of each phase.
- Update `PROGRESS.md` continuously.
- Update `README.md` per phase — don't wait until Phase 5.
- The marketplace's `.cursor-plugin/marketplace.json` does NOT need changes (same plugin name, same source path).
