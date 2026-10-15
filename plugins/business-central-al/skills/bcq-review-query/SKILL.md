---
name: bcq-review-query
description: Run only the BCQuality Query review (al-query-review) on AL code, covering filter order relative to Open, DataItemTableFilter and ColumnFilter precedence, and reopening or reusing query instances. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants query feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Query review

Runs the `al-entry` skill with a goal that names query explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-query-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-query-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-query-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/query/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-query-review"`. Every finding carries `domain: "Query"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- A query object was added or changed.
- Code opens, filters, and reads Query variables.
- Reports or APIs are built on queries.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
