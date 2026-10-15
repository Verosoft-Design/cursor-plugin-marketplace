---
name: al-upgrade-review
description: Review AL upgrade and install code using BCQuality's upgrade knowledge, covering upgrade codeunits, upgrade tags, data migration and transfer patterns, and what upgrade code must not do (for example ChangeCompany).
---

# AL Upgrade review (leaf)

Cursor adapter for BCQuality's `al-upgrade-review` leaf action skill (`microsoft/skills/review/al-upgrade-review.md`). It is one of the 19 leaves composed by `al-code-review`; Entry dispatches it on its own when the goal names this concern. This adapter holds no review policy; the vendored upstream skill is authoritative.

## BCQuality root

`BCQ` = `<plugin>/content/bcquality`, a mirror of the microsoft/BCQuality repo at the SHA pinned in `content/PINNED.json`. Resolve every repo-relative path the upstream files name (`skills/read.md`, `tools/...`, `knowledge-index.json`, `microsoft/knowledge/...`) against `BCQ`, never against the user's project.

## Execute

1. Read `BCQ/microsoft/skills/review/al-upgrade-review.md` in full and follow its Source, Relevance, Worklist, Action and Output steps exactly.
2. Read `BCQ/skills/read.md` and `BCQ/skills/do.md` on demand (summaries: the `bcquality-read-contract` rule, the `bcquality-do-contract` rule).
3. Inputs: `pr-diff`, `file-path`, or `folder-path`, carrying the actual diff or path. For `folder-path`, enumerate every relevant file under the folder; a folder has no baseline, so comparison-only rules do not apply.
4. Knowledge: the `upgrade` domain across all enabled layers: `BCQ/microsoft/knowledge/upgrade/`, `BCQ/community/knowledge/upgrade/`, `BCQ/custom/knowledge/upgrade/` (custom wins conflicts). Use READ's bounded retrieval (`pwsh BCQ/tools/Search-Knowledge.ps1` / `Get-KnowledgeArticles.ps1` over `BCQ/knowledge-index.json`) when `pwsh` and the index exist. Otherwise use READ's fallback: list the domain folders and read every selected article in full. A retrieval failure is never an empty result.
5. Where the AL MCP tools are available, use them per the `al-mcp-usage` rule to confirm symbols before reporting.

Also read `<plugin>/content/bcapps-review-prompts/upgrade.md` — the MIT-licensed BCApps AI review prompt for upgrade scenarios (~22 KB). Both feed the worklist. The prompt is frozen at BCApps `7040033d` (upstream deleted it when its PR reviewer switched to BCQuality), so BCQuality wins on conflict.

## Output

One strict-JSON findings report per DO, `skill.id: "al-upgrade-review"`:

- Every finding sets `domain: "Upgrade"`.
- A knowledge-backed finding has `id` equal to `references[0].path`, the exact path relative to `BCQ` (for example `microsoft/knowledge/upgrade/<slug>.md`), and cites only articles opened in full. `references[].sha` is the pinned `bcquality.ref`; omit it for `custom/` articles.
- An agent finding has `references: []` and an id of the form `agent:<slug>`. It stays within this domain and is capped at `severity: minor` and `confidence: medium`.
- Locations use 1-based line numbers in the final file. Mechanical fixes carry `suggested-code`, or else `suggested-code-omission-reason`.
- `completed` with no findings means nothing was flagged. `not-applicable` and `no-knowledge` are different outcomes. `partial` and `failed` are not clean results.

Render for chat with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference. User command: `/bcq-review-upgrade`.
