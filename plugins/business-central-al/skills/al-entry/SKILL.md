---
name: al-entry
description: Route a Business Central AL task to the right BCQuality action skill. Builds the Entry task context, refreshes the knowledge index, applies BCQuality's entry-point routing (relevance, goal match, super-skill precedence, layer precedence), and executes the dispatched skill or skills. Use as the front door for /bcq-review and the targeted /bcq-review-* commands.
---

# AL Entry: task router

This skill is the Cursor adapter for BCQuality's entry-point skill. It does NOT replicate the routing logic. It loads the authoritative spec and applies it.

## BCQuality root

`BCQ` = `<plugin>/content/bcquality`, a mirror of the microsoft/BCQuality repo at the SHA pinned in `content/PINNED.json`. Entry is written for a checkout whose root is the current directory. Resolve every repo-relative path it names (`skills/...`, `tools/...`, `knowledge-index.json`, `microsoft/skills/...`) against `BCQ`, never against the user's project.

## What to do

1. **Load the spec.** Read `BCQ/skills/entry.md` in full. Apply the `bcquality-entry-contract` rule, and parse skill frontmatter per READ (`BCQ/skills/read.md`; summary in the `bcquality-read-contract` rule).
2. **Build the task context** per entry.md's input schema:
   - `goal`: the user's actual request, verbatim. Do not widen a focused request ("review performance") into a generic full review.
   - `inputs-available`: the inputs you actually have, with their values: `pr-diff` for a PR or working-tree diff, `file-path` for one file, or `folder-path` for an app or source folder. For a whole app in the current directory, use that directory as the `folder-path`. Every current review skill accepts exactly these three.
   - `technologies`: `[al]` when the input is AL. Add `javascript` for control add-ins.
   - `bc-version`, `countries`, `application-area`: pass only when known, for example `bc-version` from `app.json` `application`/`platform` and countries from `.AL-Go/settings.json` `country`. Otherwise omit them; an omitted dimension is a wildcard.
   - `enabled-layers`: if `BCQUALITY_ENABLED_LAYERS` is set, use its trimmed comma-separated entries; otherwise omit it (default: microsoft, community, custom). This only narrows discovery. It is not a deny mechanism, because every layer's files stay on disk.
   - `disabled-skills`: if `BCQUALITY_DISABLED_SKILLS` is set, use its trimmed comma-separated repo-relative paths; otherwise omit.
3. **Preparation: knowledge index.** If `pwsh` is available, run `pwsh <plugin>/content/bcquality/tools/Build-KnowledgeIndex.ps1`. It resolves its own root and writes `BCQ/knowledge-index.json`, which is git-ignored and never shipped. If `pwsh` is missing or the build fails, continue: the leaves fall back to READ's path-based discovery. A failed build is not a failed review, and build output never goes into the dispatch record.
4. **Enumerate candidates:** every `kind: action-skill` file under `BCQ/{microsoft,community,custom}/skills/**/*.md` in the enabled layers. Exclude `BCQ/skills/` (Entry, READ, DO, WRITE). At the pinned SHA these are:
   - `microsoft/skills/review/al-code-review.md`: the super-skill composing 19 leaves.
   - 19 Microsoft leaves under `microsoft/skills/review/`: `al-performance-review`, `al-security-review`, `al-privacy-review`, `al-upgrade-review`, `al-style-review`, `al-ui-review`, `al-error-handling-review`, `al-events-review`, `al-interfaces-review`, `al-breaking-changes-review`, `al-web-services-review`, `al-testing-review`, `al-data-modeling-review`, `al-query-review`, `al-reporting-review`, `al-appsource-review`, `al-telemetry-review`, `al-scm-review`, `al-finance-review`.
   - `community/skills/review/al-agents-review.md`: a top-level peer that `al-code-review` does not compose.
   - Anything under `custom/skills/`. It is empty today; a custom skill with the same `id` overrides the upstream one.
5. **Route** per entry.md: Relevance (`kind`, inputs intersect, filter match, not disabled), then the Worklist steps (goal match, super-skill precedence, layer precedence). Each dropped candidate goes to `skipped[]` once, with its first reason and `superseded-by` where required.
6. **Emit the dispatch record**: one JSON document per entry.md's Output (`outcome: routed | no-match | failed`, `dispatch[]`, `skipped[]`). Each `dispatch[].inputs` is the strict intersection of `inputs-available` and the skill's declared `inputs`.
7. **Execute the dispatch.** For each `dispatch[]` entry, run the matching plugin adapter skill (`al-code-review`, or `al-<domain>-review`), which reads `BCQ/<skill.path>`, passing exactly that entry's input subset. Each produces one findings report per DO.
8. **Return** every dispatched skill's findings report unchanged. For `no-match` or `failed`, return the dispatch record itself. Render for chat with `bash <plugin>/scripts/render-findings.sh`, which accepts a single report, a dispatch record, or a JSON array of reports.

## Dispatch decision examples

| User says                                               | Expected dispatch                                                                  |
| ------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| "Review this PR" / "review this app"                    | `al-code-review` (broad goal; its 19 leaves are `superseded-by-super-skill`)       |
| "Review this PR for performance issues"                 | `al-performance-review` (`al-code-review` dropped: `narrower-sub-skill-selected`)  |
| "Check security and privacy in src/Sales/"              | `al-security-review` and `al-privacy-review` (Entry can dispatch several)          |
| "Did I break any public APIs or events?"                | `al-breaking-changes-review` (plus `al-events-review` if the goal names events)    |
| "Review my API page" / "check this webhook handler"     | `al-web-services-review`                                                           |
| "Are these tests well isolated?"                        | `al-testing-review`                                                                |
| "Review the agent I'm building"                         | `al-agents-review` (community peer; never composed by `al-code-review`)            |
| "Is this page accessible?"                              | `al-ui-review`                                                                     |

## When the dispatch is empty or Entry fails

- No candidate survives: return `outcome: "no-match"` with `outcome-reason`, and list every considered candidate in `skipped[]`. Never synthesize a dispatch.
- `BCQ/skills/entry.md` is missing or the skill folders cannot be enumerated: return `outcome: "failed"` with an `outcome-reason` naming the missing piece, and point the user to `/bcq-update`.

## Reference

- `<plugin>/content/bcquality/skills/entry.md`: authoritative spec.
- the `bcquality-entry-contract` rule: plugin-side summary, with the skill and domain tables.
- the `bcquality-read-contract` rule: frontmatter matching and layer precedence.
- the `bcquality-do-contract` rule: the findings-report shape the dispatched skills return.
