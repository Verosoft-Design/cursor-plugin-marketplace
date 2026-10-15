---
name: al-code-review
description: Run a comprehensive BCQuality-driven review of AL code by composing the 19 leaf review skills (performance, security, privacy, upgrade, style, UI, error handling, events, interfaces, breaking changes, web services, testing, data modeling, query, reporting, AppSource, telemetry, SCM, finance), then a cross-cutting agent self-review pass. Emits one rolled-up findings-report JSON per the DO contract. Use for broad PR, file, or whole-app reviews when the user asks for "a code review" without naming a specific domain.
---

# AL Code Review: super-skill orchestrator

This skill is the Cursor adapter for BCQuality's `al-code-review` super-skill. It holds no review policy of its own.

## BCQuality root

`BCQ` = `<plugin>/content/bcquality`, a mirror of the microsoft/BCQuality repo at the SHA pinned in `content/PINNED.json`. Resolve every repo-relative path upstream names against `BCQ`.

## Authoritative spec

Read `BCQ/microsoft/skills/review/al-code-review.md` in full and follow it exactly. Its frontmatter declares:

- `kind: action-skill`, `id: al-code-review`, `version: 1`
- `inputs: [pr-diff, file-path, folder-path]`, `outputs: [findings-report]`
- `sub-skills`: 19 ordered leaf slots under `microsoft/skills/review/`

Also read `BCQ/skills/do.md` (summary: the `bcquality-do-contract` rule) and `BCQ/skills/read.md` (summary: the `bcquality-read-contract` rule).

## What this skill does in Cursor

1. **Resolve the leaf slots, in frontmatter order.** For each slot, take the highest-precedence enabled, non-disabled implementation of that `id` (custom, then community, then microsoft) without reordering. With `pwsh`, `BCQ/tools/Build-SkillIndex.ps1` and `BCQ/tools/Resolve-SkillWorklist.ps1` do this. The order is:
   `al-performance-review`, `al-security-review`, `al-privacy-review`, `al-upgrade-review`, `al-style-review`, `al-ui-review`, `al-error-handling-review`, `al-events-review`, `al-interfaces-review`, `al-breaking-changes-review`, `al-web-services-review`, `al-testing-review`, `al-data-modeling-review`, `al-query-review`, `al-reporting-review`, `al-appsource-review`, `al-telemetry-review`, `al-scm-review`, `al-finance-review`.
   `al-agents-review` (community) is NOT a slot. It is an Entry-level peer, so suggest `/bcq-review-agents` separately when the code uses the Agent SDK.
2. **Relevance never looks at task content.** A leaf is skipped only when the user disabled it (`skipped-sub-skills` reason `configuration`) or when its declared `inputs` do not accept the supplied input (`not-applicable`). Each leaf decides its own applicability and returns `not-applicable` or `no-knowledge`.
3. **Record the expected composition before dispatch:** the ordered selected leaves (`id`, `version`) and the skipped ones with their reasons. Keep this list privately; do not rebuild it from leaf output.
4. **Run every selected leaf as its own discrete pass.** When the Task/Agent tool is available, give each leaf a fresh subagent containing only the input, its adapter skill (`al-<domain>-review`), and READ/DO. Leaves may run concurrently. Never collapse several leaves into one shared reasoning step, because leaves then silently under-report. Wait for every started leaf before rolling up.
5. **Acceptance gate for each leaf's JSON (DO).** Keep the raw return unchanged. It must be strict JSON with valid enums and counts. Each knowledge-backed `id` must equal `references[0].path`, and that path must exist under `BCQ` and have been read in full by the leaf. Each location must be an existing 1-based line of the reviewed file, with `range.start-line == line`. The only permitted repair is DO's bounded normalization: drop an inconsistent `location.range` when the finding has no `suggested-code`. Anything else invalidates the whole leaf. Record it as a `failed` sub-result with no findings; never salvage individual findings. With `pwsh`, `BCQ/tools/Validate-FindingsReport.ps1` runs this gate.
6. **Roll up** into `sub-results` (declared slot order, one per invoked leaf, no duplicates). Copy findings from non-failed leaves into the top-level `findings[]` with `from-sub-skill: <leaf id>`, and preserve `domain` verbatim. Prefix leaf slug ids (non-citation) with `<leaf id>:`; citation ids stay as paths. Merge duplicates (same file, overlapping lines, same correction): keep the more specific owner's reference as `references[0]`/`id`, add the other references, and keep the higher justified severity and confidence.
7. **Run the agent self-review pass** only after every leaf has returned. Look only for cross-cutting defects that span leaf domains. Validate each candidate against the knowledge the leaves loaded: a matching article upgrades it to a knowledge-backed finding with the owning leaf's `from-sub-skill` and `domain`, and a contradicting article suppresses it. Anything left is emitted with `from-sub-skill: "agent"`, `domain: "Agent"`, `references: []`, an `agent:<slug>` id, `severity` at most `minor`, `confidence` at most `medium`, and a self-contained message. Zero agent findings is a normal result.
8. **Summary and outcome (DO rollup):**
   - `summary.counts` counts the final top-level `findings[]` (failed leaves excluded, duplicates merged). It is NOT the sum of leaf counts.
   - `summary.coverage` is the sum over non-failed leaves.
   - Outcome: every leaf `failed` gives `failed`. Any `partial`, or `failed` mixed with any other outcome, gives `partial`. All `not-applicable` gives `not-applicable`. Only `no-knowledge`/`not-applicable`, with at least one `no-knowledge`, gives `no-knowledge`. Anything else gives `completed`. An empty worklist gives `not-applicable`.
   - If some selected leaves never returned (budget or timeout), the outcome is `partial` (or `failed` when no non-failed report exists). Name the missing leaf ids in `outcome-reason` and skip the self-review.
   - `outcome-reason` is required for `partial` and `failed`. Top-level `suppressed[]` stays empty.
9. **Emit** one strict-JSON document: `skill`, `outcome`, `outcome-reason`, `summary`, `findings[]`, `suppressed[]`, `sub-results[]`, and `skipped-sub-skills[]` when any leaf was skipped.

## Output rendering

After emitting the JSON, optionally pipe it through `bash <plugin>/scripts/render-findings.sh` for a summary grouped by severity, with domain labels and per-leaf outcomes. Give each finding's `location.file:line` as a clickable reference, and link each citation to its file under `<plugin>/content/bcquality/`.

## Safety

- Agent findings never exceed `minor`/`medium`, and their ids start with `agent:`.
- A failed or invalid leaf's findings are never copied into the top-level `findings[]` or counted. Its report stays in `sub-results[]`.
- Never cite a knowledge path that was not opened in full during this run, and never construct a plausible slug.

## When to invoke

`al-entry` dispatches this skill when the user's goal is a broad review. Direct entry points:

- `/bcq-review`: the canonical full review.
- `/bcq-review-<domain>` for a single leaf. `al-entry` drops this super-skill with `narrower-sub-skill-selected`. Available: `performance`, `security`, `privacy`, `upgrade`, `style`, `ui`, `error-handling`, `events`, `interfaces`, `breaking-changes`, `web-services`, `testing`, `data-modeling`, `query`, `reporting`, `appsource`, `telemetry`, `scm`, `finance`, plus `agents` (community peer).
