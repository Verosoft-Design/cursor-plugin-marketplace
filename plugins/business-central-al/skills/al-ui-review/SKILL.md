---
name: al-ui-review
description: Review AL page, pageextension, and control-add-in changes for UI and accessibility issues using BCQuality's curated UI knowledge plus BCApps' MIT-licensed accessibility review prompt. Detects ShowCaption = false on editable fields, nested grids, semantic-style without textual meaning, broken data-table heuristics, missing tooltips, accessibility violations in control add-in JS, and other BC-specific UI footguns. Returns not-applicable when the diff contains no UI files.
---

# AL UI Review (leaf)

This skill is the Cursor adapter for BCQuality's `al-ui-review` leaf skill.

## Authoritative spec

Read `<plugin>/content/bcquality/microsoft/skills/review/al-ui-review.md` in full. It declares the canonical Source → Relevance → Worklist → Action pattern for the UI domain.

Also read `<plugin>/content/bcapps-review-prompts/accessibility.md` — the MIT-licensed BCApps AI review prompt for accessibility (~26 KB). Both feed the worklist.

## Apply contract rules

Load `bcquality-do-contract`, `bcquality-read-contract`, and `al-mcp-usage`.

## Source

Read every knowledge file under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/ui/*.md`. Today:

- 19+ files under `microsoft/knowledge/ui/`. Canonical examples: `show-caption-on-editable-fields.md`, `no-nested-grids.md`, `group-labeled-first-child-exception.md`, `tabular-intent-requires-data-table-conditions.md`, `semantic-styles-need-independent-textual-meaning.md`. Includes anti-false-positive articles: `group-show-caption-false-outside-grid-is-not-a-violation.md`, `group-caption-quality-is-not-an-accessibility-issue.md`, `layout-table-with-captions-is-valid.md`.

## Relevance

This is the ONE leaf where `technologies` is `[al, javascript]` — control add-ins use JS/CSS/HTML. Match accordingly.

**UI-file filter (critical)**: this skill applies only to files declaring `page`, `pageextension`, `pagecustomization`, OR to control-add-in JavaScript/CSS/HTML that changes rendered UI. When the diff contains no such files, return `outcome: "not-applicable"` immediately. Do not evaluate knowledge files when the worklist is empty by construction.

## Worklist signal tokens (from upstream skill, verbatim)

`Caption`, `ToolTip`, `AboutTitle`, `AboutText`, `PageType`, `ShowCaption`, `InstructionalText`, `grid`, `fixed`, `GridLayout`, `Style`, `StyleExpr`, `Favorable`, `Unfavorable`, `Ambiguous`, `cuegroup`, `controladdin`, `usercontrol`, `aria-`, `tabindex`, `keydown`, `focus`, `innerHTML`, `createElement`, `&`, `Specifies`, `Message(`, `Confirm(`, `Error(` in a page context, `Disabled`, `Invalid`, `Whitelist`, `Blacklist`, trailing-punctuation patterns on captions.

Resolve layer precedence; suppressed files go into `suppressed[]`.

## Action

UI text findings are generally `minor` — they affect localization and polish rather than correctness.

`major` for: missing labels on editable fields, broken grid semantics that lose table structure, semantic color without textual meaning, UI-rendering control add-in changes that lack accessibility attributes (`aria-*`, `tabindex`, keyboard handlers).

`blocker` only when a documented platform-level requirement is violated (e.g. illegal `PageType` combination the runtime rejects).

Anti-false-positive articles are critical here — UI review is the most prone to over-flagging. Cite the relevant anti-false-positive article when the diff appears to trigger a known false positive (e.g. a `Group` with `ShowCaption = false` that lives outside a grid is NOT a violation per `group-show-caption-false-outside-grid-is-not-a-violation.md`).

## Output

Single JSON document conforming to the DO output contract.
