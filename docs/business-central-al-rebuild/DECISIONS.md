# Decisions

User answered 2026-05-25.

| # | Question | Answer | Implications |
|---|---|---|---|
| 1 | Which phases to implement? | **All — Phase 1 → Phase 6, in order** | Build the complete stack. Phase 6 (BC runtime MCP) deferred per Q4 below, so effectively Phase 1–5 in this rebuild; Phase 6 is documented but not built yet. |
| 2 | Where to create the new plugin files? | **In the marketplace repo** — `plugins/business-central-al/` | Edits replace v0.1.0 in place. Bump `version: "0.2.0"` in `plugin.json`. Keep marketplace.json entry unchanged. |
| 3 | How to pull upstream content (BCQuality / BCApps rulesets / review prompts)? | **Vendor a pinned snapshot** in `plugins/business-central-al/content/` with `PINNED.json` + `/bcq-update` command (resolved 2026-05-25) | See "Vendoring contract" section below for the agreed shape. |
| 4 | Plan for the Business Central runtime MCP (Phase 6)? | **Defer** | Do not ship `businesscentral` server in `mcp.json` yet. Do not add `/bc-query` / `/bc-post` commands. Document it in README as "coming later". |
| 5 | How strict for always-on rules by default? | **Strict** — bundle the MIT license header rule as always-on, matching BCApps exactly | `al-license-header.mdc` ships with `alwaysApply: true`. Use the standard 4-line `// Copyright (c) Microsoft Corporation. All rights reserved. // Licensed under the MIT License. See License.txt in the project root for license information.` template **but make the publisher line configurable** so Verosoft/partners can swap in their own header. |
| 6 | Pre-populate BCQuality `custom/` layer with anything? | **Seed with TAG-specific articles** distilled from `/Users/alexisturgeon/Source/tag-bc/.cursor/rules/` | See `TAG_CUSTOM_LAYER.md` for the distilled patterns. Lives at `content/bcquality/custom/knowledge/<domain>/` inside the plugin. |

## Vendoring contract (resolved 2026-05-25)

All four upstream content sources are vendored into the plugin under `plugins/business-central-al/content/` and pinned via a single `content/PINNED.json` file.

Sources to vendor:
1. **BCQuality** (`microsoft/BCQuality`) — `microsoft/` + `community/` knowledge folders (~388 files) into `content/bcquality/microsoft/` and `content/bcquality/community/`. `custom/` is local-only and never overwritten.
2. **BCApps rulesets** (`microsoft/BCApps`) — the 9 `.ruleset.json` files from `src/rulesets/` into `content/bcapps-rulesets/`.
3. **BCApps review prompts** (`microsoft/BCApps`) — the 6 MIT prompts from `tools/Code Review/instructions/` into `content/bcapps-review-prompts/`.
4. **BCApps default VS Code settings** (`microsoft/BCApps`) — `build/scripts/DevEnv/DefaultSettings.json` into `content/bcapps-defaults/`.
5. **BC-Bench ALTest agent prompt** (`microsoft/BC-Bench`) — `src/bcbench/agent/shared/instructions/microsoftInternal-NAV/agents/ALTest.agent.md` into `content/altest-prompt/`.

`PINNED.json` shape:
```json
{
  "bcquality":              { "repo": "microsoft/BCQuality",  "ref": "<sha>",        "fetched_at": "<ISO date>", "license": "MIT" },
  "bcapps_rulesets":        { "repo": "microsoft/BCApps",     "ref": "<sha>",        "fetched_at": "<ISO date>", "license": "MIT" },
  "bcapps_review_prompts":  { "repo": "microsoft/BCApps",     "ref": "<sha>",        "fetched_at": "<ISO date>", "license": "MIT" },
  "bcapps_defaults":        { "repo": "microsoft/BCApps",     "ref": "<sha>",        "fetched_at": "<ISO date>", "license": "MIT" },
  "altest_prompt":          { "repo": "microsoft/BC-Bench",   "ref": "<sha>",        "fetched_at": "<ISO date>", "license": "MIT" }
}
```

Refresh command: **`/bcq-update [--source bcquality|bcapps_*|altest_prompt|--all] [--ref <sha-or-tag>]`** — re-runs the matching `scripts/vendor-*.sh`, updates `PINNED.json` with the new ref + fetched-at date. Defaults: `--all`, latest `main` from each source.

Rationale: reproducible, offline-friendly, and the BCQuality DO contract's optional `references[].sha` field is *designed* for SHA-pinned consumers. The ~5 MB cost is paid once.

Surfaced in plugin: the status line shows `BCQuality v<sha[0:7]> · BCApps v<sha[0:7]>` so users can see drift.

## All blockers cleared

As of 2026-05-25, Phase 1–5 are all unblocked. Phase 6 remains deferred.

## Implicit decisions made during research (worth re-confirming)

- Plugin **name stays** `business-central-al` (not renamed to `business-central-al-pro` etc.).
- **Two MCPs documented**, only the AL MCP wired by default. BC MCP is Phase 6 (deferred).
- Default model recommendation in session-start: **Claude Opus 4.6/4.7** (BC-Bench leader for both bug-fix and test-gen), **Claude Sonnet 4.6** as the cheaper "good enough" choice (66.9 % bug-fix vs 67.9 % for Opus), **`gpt-5.3-codex`** as the fast option (~107 s/task vs ~250–500 s). Warn against **`gpt-4.1`** (16.6 % on AL — effectively unusable).
- AL-Go version is **not hardcoded** — read `templateUrl` from `.github/AL-Go-Settings.json` and let `Update AL-Go System Files` move it forward.
- License-header rule is always-on but **the header text is a setting** so partners (Verosoft for TAG) can swap "Microsoft Corporation" for "Verosoft Design INC.".
