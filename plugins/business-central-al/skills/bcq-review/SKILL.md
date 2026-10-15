---
name: bcq-review
description: Run the comprehensive BCQuality review on AL code. Routes via al-entry to al-code-review (super-skill), which composes the 19 leaf reviews plus a cross-cutting agent self-review pass and emits one rolled-up findings-report JSON. Use for PR reviews, file reviews, or reviewing a complete app folder when the user wants the full quality pass.
disable-model-invocation: true
---

# Comprehensive BCQuality review

Runs the `al-entry` skill. For a broad goal, Entry selects `al-code-review` (the BCQuality super-skill), which runs all 19 leaf reviews and then a cross-cutting agent self-review pass.

## What to feed it

Pass whatever the user supplies, as the actual value:

- `pr-diff`: a PR diff (`gh pr diff <number>`) or the working tree against `main`.
- `file-path`: one file (`src/Sales/Posting.Codeunit.al`).
- `folder-path`: an app or source folder (the folder with `app.json`; `.` for the current app). Every relevant file under it is reviewed. A folder has no baseline, so comparison-only rules (for example breaking changes against a previous version) cannot fire.

Each leaf receives the strict intersection of these inputs and its declared `inputs`.

## Flow

1. Run `al-entry` with the user's request as `goal`. It refreshes `content/bcquality/knowledge-index.json` when `pwsh` is available and emits a dispatch record naming `al-code-review`.
2. `al-code-review` follows `<plugin>/content/bcquality/microsoft/skills/review/al-code-review.md`. It records the expected composition, then runs each of the 19 leaves as its own isolated pass, in subagents when available.
3. Each leaf (`al-<domain>-review`) follows its upstream spec and returns a findings-report JSON. Each JSON passes DO's acceptance gate; an invalid one is recorded as `failed`.
4. `al-code-review` rolls up the accepted reports, runs the cross-cutting self-review, and emits the final JSON.
5. Pretty-print with `bash <plugin>/scripts/render-findings.sh` and give clickable `file:line` references.

## Targeted alternatives

When the user names a concern, run the matching leaf only. `al-entry` drops the super-skill with `narrower-sub-skill-selected`.

- Code quality and runtime: `/bcq-review-performance`, `/bcq-review-security`, `/bcq-review-privacy`, `/bcq-review-error-handling`, `/bcq-review-telemetry`
- Lifecycle and contracts: `/bcq-review-upgrade`, `/bcq-review-breaking-changes`, `/bcq-review-events`, `/bcq-review-interfaces`, `/bcq-review-web-services`, `/bcq-review-appsource`
- Objects and design: `/bcq-review-data-modeling`, `/bcq-review-query`, `/bcq-review-reporting`, `/bcq-review-ui`, `/bcq-review-style`, `/bcq-review-testing`
- Functional domains: `/bcq-review-scm`, `/bcq-review-finance`

`/bcq-review-agents` (Business Central Agent SDK code) is a community-layer peer that `al-code-review` does not compose. Run it in addition when the app builds agents.

## Output

A single JSON document per the DO contract:

- `skill: { "id": "al-code-review", "version": 1 }`
- `outcome`: `completed | partial | no-knowledge | not-applicable | failed`. `partial` and `failed` are NOT clean results, and `outcome-reason` names the affected leaves.
- `summary.counts.{blocker,major,minor,info}` counts the final top-level findings, after merging and excluding failed leaves.
- `summary.coverage.{worklist-size,items-evaluated}` is summed over non-failed leaves.
- `findings[]`: each has `id`, `severity`, `message`, `location` (`file`, `line`, optional `range`), `references`, `confidence`, `from-sub-skill`, `domain` (for example `Performance`, `Web Services`, `Agent`), and `suggested-code` or `suggested-code-omission-reason` for mechanical fixes.
- `suppressed[]`: empty at the top level; each leaf reports its own layer-precedence suppressions.
- `sub-results[]`: every leaf's complete report, in slot order.
- `skipped-sub-skills[]`: leaves skipped by configuration or input incompatibility.

Render in chat as a summary grouped by severity and domain, with each finding linked to its `location.file:line` and to its cited knowledge file under `<plugin>/content/bcquality/`.

## Safety

- The super-skill never filters leaves by task content. Every selected leaf runs, and a leaf with nothing to do returns `not-applicable`.
- Agent findings carry `references: []`, an `agent:` id, `severity` of at most `minor`, and `confidence` of at most `medium`. Super-skill agent findings also carry `from-sub-skill: "agent"` and `domain: "Agent"`.
- A failed or invalid leaf contributes nothing to the top-level `findings[]` or counts; it stays in `sub-results[]` only.

## When the content is stale

If the vendored BCQuality content seems stale (see `bcquality.fetched_at` in `<plugin>/content/PINNED.json`), suggest `/bcq-update`.

## Microsoft's own reviewer (optional)

Microsoft runs the same BCQuality knowledge in its PR review engine, published as the `al-review` plugin in `microsoft/BC-ALAgents` (`claude plugin marketplace add microsoft/BC-ALAgents`, then `claude plugin install al-review@bc-alagents`). It needs `pwsh`, the `powershell-yaml` module and a signed-in GitHub Copilot CLI, because its engine runs the review through Copilot. Mention it when the user wants results identical to Microsoft's BCApps PR reviews; otherwise this skill is the self-contained path.
