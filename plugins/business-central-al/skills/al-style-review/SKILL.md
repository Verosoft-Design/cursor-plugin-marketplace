---
name: al-style-review
description: Review AL code style using BCQuality's curated style knowledge plus BCApps' MIT-licensed style review prompt. Detects approved-suffix violations on Labels (Err/Msg/Qst/Lbl/Tok/Txt), missing Comment on placeholder labels, missing Locked = true on URLs and telemetry, FieldName instead of FieldCaption in user text, StrSubstNo-wrapping of Error/Message, missing ToolTip on page fields, missing this. qualification, API-page naming conventions, and other BC-specific style footguns. Use alongside a formal analyzer — this skill adds remedial explanations of why each rule exists.
---

# AL Style Review (leaf)

This skill is the Cursor adapter for BCQuality's `al-style-review` leaf skill.

## Authoritative spec

Read `<plugin>/content/bcquality/microsoft/skills/review/al-style-review.md` in full. It declares the canonical Source → Relevance → Worklist → Action pattern for the style domain.

Also read `<plugin>/content/bcapps-review-prompts/style.md` — the MIT-licensed BCApps AI review prompt for style (~30 KB, the largest of the 6). Both feed the worklist.

## Apply contract rules

Load `bcquality-do-contract`, `bcquality-read-contract`, and `al-mcp-usage`.

## Source

Read every knowledge file under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/style/*.md`. Today:

- 33+ files under `microsoft/knowledge/style/`. Canonical examples: `label-suffix-approved-list.md`, `error-passes-parameters-directly-not-strsubstno.md`, `tooltip-required-on-page-fields.md`, `lowercase-reserved-keywords.md`, `this-keyword-in-codeunits.md`, `api-page-camelcase-properties.md`, `fieldcaption-not-fieldname-in-user-messages.md`, `named-invocations-not-object-ids.md`, `file-name-object-type-pattern.md`.
- Custom-layer style articles (TAG): `tag-object-id-ranges.md`, `tag-filename-pattern.md`, `tag-object-name-prefix.md`, `tag-project-folder-structure.md`, `tag-procedure-parameter-prefix.md`, `tag-variable-naming-conventions.md`. Several of these CONTRADICT microsoft-layer articles — the custom layer wins per READ precedence; the suppressed microsoft files appear in `suppressed[]`.

## Relevance

Filter by frontmatter per the READ contract.

## Worklist signal tokens (from upstream skill, verbatim)

`Label`, `TextConst`, `Locked`, `Comment`, `MaxLength`, `temporary`, `OptionMembers`, `OptionCaption`, `APIPublisher`, `APIGroup`, `APIVersion`, `EntityName`, `EntitySetName`, `DelayedInsert`, `FieldCaption`, `TableCaption`, `FieldName`, `TableName`, `Page.RunModal`, `Report.Run`, `this.`, `StrSubstNo`.

Weight toward API pages (`PageType = API`), tables and pages declaring `Label` or `TextConst`, codeunits issuing `Error`/`Message`/`Confirm`, and files violating the active filename convention (BCApps `<Object>.<Type>.al` OR TAG `[Type] [ID] - TAG [Name].al`, whichever the repo declares).

Resolve layer precedence; suppressed files go into `suppressed[]`.

## Action

Style findings rarely reach `blocker` — reserve it for cases where the knowledge file documents a platform-level requirement (for example API page property constraints the OData runtime rejects).

Most style findings are `minor` or `info`. Egregious misuse can reach `major`:

- `Error` with pre-built Text losing translation and telemetry classification → `major`.
- Object IDs outside the publisher's allocated range (per TAG `tag-object-id-ranges.md`) → `major`.
- Missing mandatory affix per `tag-object-name-prefix.md` → `major` (will break the AppSource build).

Use together with a formal analyzer (`/al-compile` with `enableCodeAnalysis: true` and the BCApps rulesets via `/al-apply-rulesets`). This skill adds BCQuality's remedial-knowledge explanations of why each rule exists; the analyzer catches the mechanical violations.

## Output

Single JSON document conforming to the DO output contract.
