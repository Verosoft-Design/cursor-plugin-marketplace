# Progress Tracker

Update this file after each completed item. The agent should re-read it at the start of every working session.

Last updated: **2026-05-25 (ALL 5 PHASES COMPLETE; plugin at v0.6.0; BCApps pinned at SHA dc1242e3; BCQuality pinned at SHA 4d59fb73; BC-Bench pinned at SHA ef4f4668; 427 vendored upstream files; 8 TAG custom-layer articles seeded and validated; Phase 6 [BC runtime MCP] remains deferred per Decision Q4)**

## Status legend

- [ ] pending
- [/] in progress
- [x] done
- [-] skipped / deferred

---

## Phase 0 — Planning & preserve research

- [x] Read existing `business-central-al` plugin (v0.1.0)
- [x] Research BCQuality
- [x] Research AL-Go + BC MCP servers
- [x] Research BC-Bench
- [x] Research BCApps
- [x] Synthesize master plan
- [x] Get user decisions
- [x] Preserve research dossiers in `docs/business-central-al-rebuild/research/`
- [x] Preserve TAG source rules in `docs/business-central-al-rebuild/tag-source/`
- [x] Write PLAN.md, DECISIONS.md, PROGRESS.md, GOTCHAS.md, TAG_CUSTOM_LAYER.md, README.md
- [x] Resolve Q3 (vendoring strategy) — answer: vendor pinned snapshot with PINNED.json + /bcq-update
- [ ] Wait for user "go" signal to begin Phase 1

---

## Phase 1 — AL MCP wiring + inner-loop commands ✅ DONE 2026-05-25

- [x] `mcp.json` (al server only; BC MCP deferred)
- [x] `rules/al-mcp-usage.mdc`
- [x] `commands/al-symbols.md`
- [x] `commands/al-symbol-search.md`
- [x] `commands/al-compile.md`
- [x] `commands/al-build.md`
- [x] `commands/al-publish-sandbox.md`
- [x] `skills/al-build-and-publish/SKILL.md`
- [x] Update `.cursor-plugin/plugin.json` version → `0.2.0`
- [x] Update `README.md` with AL MCP install instructions (VS Code AL extension OR NuGet)
- [x] Create `CHANGELOG.md`
- [x] Sanity checks: plugin.json + mcp.json validate, no lint errors

---

## Phase 2 — AL-Go lifecycle commands ✅ DONE 2026-05-25 (v0.3.0)

- [x] `skills/al-go-lifecycle/SKILL.md`
- [x] `skills/al-go-lifecycle/workflows.md`
- [x] `commands/al-new-pte.md`
- [x] `commands/al-new-appsource.md`
- [x] `commands/al-add-test-app.md`
- [x] `commands/al-add-bcpt-app.md`
- [x] `commands/al-import-existing-app.md`
- [x] `commands/al-create-online-dev-env.md`
- [x] `commands/al-publish-to-environment.md`
- [x] `commands/al-current.md`
- [x] `commands/al-next-minor.md`
- [x] `commands/al-next-major.md`
- [x] `commands/al-troubleshoot.md`
- [x] `commands/al-update-system-files.md`
- [x] `commands/al-increment-version.md`
- [x] `commands/al-release.md`
- [x] `commands/al-publish-appsource.md`
- [x] `commands/al-deploy-docs.md`
- [x] `commands/al-secrets-setup.md`
- [x] `commands/al-init-keyvault.md`
- [x] `commands/al-go-live.md`
- [x] Bump `.cursor-plugin/plugin.json` version → `0.3.0`, expand keywords
- [x] Update README.md with Phase 2 component tables and roadmap
- [x] Update CHANGELOG.md with v0.3.0 entry
- [x] Sanity checks: plugin.json valid, no lint errors

---

## Phase 3 — BCApps quality baseline ✅ DONE 2026-05-25 (v0.4.0)

- [x] `scripts/vendor-bcapps.sh` (consolidated rulesets + defaults + prompts into one idempotent script — supports `--latest` and `--ref <sha>`)
- [x] `content/PINNED.json` (initial entry: BCApps SHA `dc1242e31a055ec355b6b8ccf8e7ed94e68016d7`)
- [x] `content/bcapps-rulesets/*.json` (9 files vendored)
- [x] `content/bcapps-defaults/DefaultSettings.json` (vendored)
- [x] `content/bcapps-review-prompts/*.md` (6 files vendored — also feeds Phase 4)
- [x] `commands/al-apply-rulesets.md`
- [x] `commands/al-apply-vscode-defaults.md`
- [x] `rules/al-overview.mdc`
- [x] `rules/al-naming-and-files.mdc`
- [x] `rules/al-labels-and-locked.mdc`
- [x] `rules/al-license-header.mdc` (strict default; header text configurable; opt-out documented)
- [x] `rules/al-xmldoc-public-procedures.mdc`
- [x] Update `rules/al-testing.mdc` for Library Assert + EventSubscriberInstance = Manual + [TransactionModel] + Given/When/Then
- [x] Update `commands/scaffold-test-codeunit.md` for Library Assert
- [x] `skills/al-scaffold-module/SKILL.md` (with project-layout-aware detection for BCApps vs TAG)
- [x] Update `skills/business-central-al-tdd/SKILL.md` for Library Assert
- [x] Bump `.cursor-plugin/plugin.json` version → `0.4.0`, expand keywords
- [x] Update README.md (preserved user's added `/al-setup` command + table additions)
- [x] Update CHANGELOG.md with v0.4.0 entry
- [x] Sanity checks: plugin.json valid, all 9 rulesets validate as JSON, vendor script idempotent, no lint errors

**Note on plan adjustments:**

- PLAN.md listed `vendor-rulesets.sh` and `vendor-bcapps-prompts.sh` as separate scripts. Consolidated into one `vendor-bcapps.sh` since all 3 categories (rulesets, defaults, prompts) come from the same `microsoft/BCApps` repo. Phase 4 will follow the same pattern with `vendor-bcquality.sh`; Phase 5 with `vendor-bcbench.sh`.
- User added `commands/al-setup.md` between Phase 2 and Phase 3 (not part of the original plan). README updated to reference it.

---

## Phase 4 — BCQuality integration ✅ DONE 2026-05-25 (v0.5.0)

- [x] `scripts/vendor-bcquality.sh` (tarball-based, idempotent, validates on every run; preserves custom layer)
- [x] `scripts/validate-bcquality-frontmatter.py` (586-line upstream validator vendored)
- [x] `scripts/render-findings.py` + `scripts/render-findings.sh` (wrapper) — pretty-prints DO findings-report JSON
- [x] Update `content/PINNED.json` with bcquality entry (SHA `4d59fb73`)
- [x] `content/bcquality/microsoft/` (141 articles + 211 AL samples + 7 review skills)
- [x] `content/bcquality/community/` (13 articles + 23 AL samples)
- [x] `content/bcquality/{entry,read,do,write}.md` (4 meta-skill contracts at root)
- [x] `content/bcquality/custom/knowledge/` (8 TAG articles seeded — 6 style + 1 api + 1 upgrade — all pass R01–R25)
- [x] `rules/bcquality-read-contract.mdc`
- [x] `rules/bcquality-do-contract.mdc`
- [x] `rules/bcquality-entry-contract.mdc`
- [x] `rules/bcquality-write-contract.mdc`
- [x] `skills/al-entry/SKILL.md`
- [x] `skills/al-code-review/SKILL.md` (super-skill with agent self-review pass + knowledge-validation)
- [x] `skills/al-performance-review/SKILL.md`
- [x] `skills/al-security-review/SKILL.md`
- [x] `skills/al-privacy-review/SKILL.md`
- [x] `skills/al-upgrade-review/SKILL.md`
- [x] `skills/al-style-review/SKILL.md`
- [x] `skills/al-ui-review/SKILL.md`
- [x] `skills/bcq-write-knowledge/SKILL.md`
- [x] `commands/bcq-review.md`
- [x] `commands/bcq-review-performance.md`
- [x] `commands/bcq-review-security.md`
- [x] `commands/bcq-review-privacy.md`
- [x] `commands/bcq-review-style.md`
- [x] `commands/bcq-review-upgrade.md`
- [x] `commands/bcq-review-ui.md`
- [x] `commands/bcq-write-knowledge.md`
- [x] `commands/bcq-update.md`
- [x] Bump `.cursor-plugin/plugin.json` → `0.5.0`, expand keywords
- [x] Update README.md with Phase 4 sections and tables
- [x] Update CHANGELOG.md with v0.5.0 entry
- [x] Sanity checks: PINNED.json valid, vendor-bcquality.sh idempotent (0 errors/warnings), render-findings.sh renders sample JSON cleanly, no lint errors

---

## Phase 5 — BC-Bench wins ✅ DONE 2026-05-25 (v0.6.0)

- [x] `scripts/vendor-bcbench.sh` (idempotent vendor for BC-Bench, supports `--latest` and `--ref <sha>`)
- [x] `scripts/vendor-bcapps.sh` extended to also vendor BCApps al-docs-plugin content into `content/al-docs-references/`
- [x] `content/altest-prompt/ALTest.agent.md` (267 lines vendored from BC-Bench MIT at SHA `ef4f4668`)
- [x] `content/al-docs-references/` (5 files: SKILL.md, al-docs-init.md, al-docs-update.md, al-docs-audit.md, al-scoring.md — vendored from BCApps MIT)
- [x] Update `content/PINNED.json` (add bcbench source + al_docs category under bcapps)
- [x] `skills/al-write-test/SKILL.md` (Cursor adapter for ALTest prompt; auto-invokes on test-generation intent)
- [x] `skills/al-docs/SKILL.md` (single Cursor adapter with init/update/audit mode routing — simpler than the original per-mode file split; routes to the upstream reference files)
- [x] `commands/al-write-test.md` (explicit invocation)
- [x] `commands/al-docs.md` (explicit invocation with mode argument)
- [x] `scripts/detect-al-repo.sh` (POSIX sh; walks up from PWD looking for app.json + .AL-Go/settings.json; emits JSON BC project metadata)
- [x] Expand `scripts/session-start-context.sh` with BC-Bench-measured model recommendation (Opus 4.7 / Sonnet 4.6 default, gpt-5.3-codex for speed, warn against gpt-4.1)
- [x] Update `hooks/hooks.json` to add `userPromptSubmit` hook running `detect-al-repo.sh`
- [x] Bump `.cursor-plugin/plugin.json` → `0.6.0`, expand keywords
- [x] Update README.md with Phase 5 sections and tables
- [x] Update CHANGELOG.md with v0.6.0 entry
- [x] Sanity checks: PINNED.json valid, vendor-bcbench.sh + vendor-bcapps.sh both idempotent, detect-al-repo.sh tested against real tag-bc workspace, no lint errors

**Note on plan adjustments:**

- PLAN.md listed `vendor-altest-prompt.sh` as a separate script. Renamed to `vendor-bcbench.sh` for symmetry with `vendor-bcapps.sh` and `vendor-bcquality.sh` (one script per upstream Microsoft repo). If BC-Bench eventually grows additional vendored assets (BCApps-style prompts, evaluators, etc.), they go in the same script.
- PLAN.md listed `skills/al-docs/{init,update,audit}.md` as separate Cursor skill files. Consolidated into one `skills/al-docs/SKILL.md` that routes by mode and delegates to the upstream reference files in `content/al-docs-references/`. This matches BCApps' own design (one skill, three mode references) and avoids duplicating 1150+ lines into Cursor format.

---

## Phase 6 — BC MCP runtime layer

- [-] DEFERRED per Decision Q4. Documented in README as "coming later".

---

## Sanity checks (run after each phase)

- [ ] `plugin.json` validates as JSON
- [ ] All declared component paths exist
- [ ] No `..` traversal or absolute paths in `plugin.json` or `mcp.json`
- [ ] All rules have valid frontmatter (description, optional globs/alwaysApply)
- [ ] All skills have YAML frontmatter (name + description, ≤1024 chars total)
- [ ] All commands have YAML frontmatter (name + description)
- [ ] Marketplace.json entry still resolves
- [ ] `ReadLints` clean on every edited file
- [ ] `CHANGELOG.md` updated for the phase
- [ ] `PROGRESS.md` updated
