---
name: bcq-review-ui
description: Run only the AL UI/accessibility review (skip the other 5 leaves and the super-skill self-review). Use when the user specifically wants UI feedback — typically when adding/changing pages, pageextensions, control add-ins, or when auditing accessibility.
disable-model-invocation: true
---

# Targeted: UI / accessibility review

Dispatches `al-entry` with a goal explicitly naming "UI" or "accessibility". Entry's `narrower-sub-skill-selected` precedence selects `al-ui-review`.

## Inputs

PR diff, file path, or object list. The UI leaf has an explicit UI-file filter: it returns `outcome: "not-applicable"` when the diff contains no `page`/`pageextension`/`pagecustomization`/control-add-in files. So this command is cheap to run against arbitrary diffs.

## Output

A single JSON document per the DO contract from `al-ui-review` only.

The leaf reads:

- `<plugin>/content/bcquality/microsoft/skills/review/al-ui-review.md` (authoritative spec — note `technologies: [al, javascript]` for control-add-in coverage).
- Knowledge files under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/ui/`.
- `<plugin>/content/bcapps-review-prompts/accessibility.md`.

## When to prefer this

- Adding a new page (`PageType = List`, `Card`, `Document`, `API`, etc.).
- Modifying a `pageextension`.
- Touching control-add-in JavaScript / CSS / HTML.
- Auditing accessibility before an AppSource validation pass.

## Anti-false-positive articles are critical here

UI review is the most prone to over-flagging. The privacy/UI leaves have several articles that exist specifically to prevent the agent from flagging non-issues:

- `group-show-caption-false-outside-grid-is-not-a-violation.md`
- `group-caption-quality-is-not-an-accessibility-issue.md`
- `layout-table-with-captions-is-valid.md`
- `show-caption-false-allowed-on-non-editable-fields.md`
- `show-caption-in-promptdialog-prompt-area.md`
- `show-caption-in-repeater-allowed.md`

The leaf should cite these as `info`-severity reminders when the diff looks like it might trigger a false positive.
