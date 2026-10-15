---
name: bcq-review-finance
description: Run only the BCQuality Finance review (al-finance-review) on AL code, covering general journal posting, ledger corrections, applications, VAT handling, and posting-linked dimensions. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants finance feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Finance review

Runs the `al-entry` skill with a goal that names finance explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-finance-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-finance-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-finance-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/finance/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-finance-review"`. Every finding carries `domain: "Finance"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Code builds or posts general journal lines.
- Ledger entries, applications, or corrections changed.
- VAT or dimension handling changed.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
