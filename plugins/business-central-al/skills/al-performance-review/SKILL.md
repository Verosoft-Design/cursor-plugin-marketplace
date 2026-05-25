---
name: al-performance-review
description: Review AL code for performance issues using BCQuality's curated performance knowledge plus BCApps' MIT-licensed performance review prompt. Detects SetLoadFields ordering errors, missing or wrong SetCurrentKey, IsEmpty vs Count > 0, FindFirst-with-Next loops, Commit inside loops, missing filter-before-FindSet, redundant CalcFields, and other BC-specific performance footguns.
---

# AL Performance Review (leaf)

This skill is the Cursor adapter for BCQuality's `al-performance-review` leaf skill.

## Authoritative spec

Read `<plugin>/content/bcquality/microsoft/skills/review/al-performance-review.md` in full. It declares the canonical Source → Relevance → Worklist → Action pattern for the performance domain.

Also read `<plugin>/content/bcapps-review-prompts/performance.md` — the MIT-licensed BCApps AI review prompt for performance (~28 KB). It complements the BCQuality knowledge files with bad/good AL code examples and richer reasoning. Both feed the worklist.

## Apply contract rules

Load `bcquality-do-contract` (output JSON shape), `bcquality-read-contract` (knowledge file parsing), and `al-mcp-usage` (for using `al_symbolsearch` and `al_getdiagnostics` to support findings when relevant).

## Source

Read every knowledge file under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/performance/*.md`. Today:

- 33+ files under `microsoft/knowledge/performance/` (canonical examples: `use-setloadfields-for-partial-records.md`, `findset-true-applies-updlock-on-read.md`, `use-isempty-for-existence-check.md`, `pair-findset-with-next-loop.md`, `avoid-commit-inside-loops.md`, `calcsums-instead-of-calcfields-in-loop.md`).
- 7+ files under `community/knowledge/performance/` (e.g. `use-deleteall-for-filtered-bulk-deletion.md`, `omit-filter-only-fields-from-setloadfields.md`).
- Any custom-layer files under `custom/knowledge/performance/`.

## Relevance

Filter by frontmatter per the READ contract:

- `bc-version`: match against the workspace's BC version (from `app.json` if present, else treat as unknown).
- `technologies`: intersect with `[al]`.
- `countries`: match per the `w1` sentinel rule.
- `application-area`: match per the `[all]` sentinel rule.

Files that are conditionally applicable (any dimension unknown) get findings with confidence capped at `medium` and the unknown dimensions named in the message.

## Worklist signal tokens (from upstream skill, verbatim)

`SetRange`, `SetFilter`, `SetLoadFields`, `SetCurrentKey`, `FindSet`, `ReadIsolation`, `LockTable`, `ModifyAll`, `DeleteAll`, `TextBuilder`, `Dictionary`, `temporary`, `repeat`, `until`, `CalcFields`, `CalcSums`.

Weight toward changed objects performing record iteration: tables, pages with `SourceTable` bindings, reports, queries, codeunits performing record iteration.

Resolve layer precedence per READ — `custom` > `community` > `microsoft`. Suppressed files go into the output's `suppressed[]` with `reason: "layer-precedence"`.

## Action

Per worklist entry, evaluate the diff or file against the file's `## Best Practice` and `## Anti Pattern` sections.

Severity rules from the upstream skill:

- `blocker` ONLY when the knowledge file states a platform-level guarantee (documented query timeouts, transaction size limits).
- `major` for clear anti-pattern matches with high confidence.
- `minor` for Best-Practice contradictions that aren't full anti-patterns.
- `info` when the file is clearly applicable but no violation is detected (useful as context).

Confidence: `high` only for unambiguous identifier/syntax/object-type matches; `medium` for heuristics or unknown dimensions; `low` for applicability-only advisories.

## Output

Single JSON document conforming to the DO output contract. Render via `scripts/render-findings.sh` for human-readable display in chat. Include each finding's `location.file:line` as a clickable reference.
