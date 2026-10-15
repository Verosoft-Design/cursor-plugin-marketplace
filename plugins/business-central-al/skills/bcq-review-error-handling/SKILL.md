---
name: bcq-review-error-handling
description: Run only the BCQuality Error handling review (al-error-handling-review) on AL code, covering Error and ErrorInfo usage, actionable and collectible errors, TryFunction and GetLastErrorText, Confirm in validation, and trigger return values. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants error handling feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Error handling review

Runs the `al-entry` skill with a goal that names error handling explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-error-handling-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-error-handling-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-error-handling-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/error-handling/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-error-handling-review"`. Every finding carries `domain: "Error Handling"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Validation, posting, or batch code raises errors.
- TryFunction, ErrorInfo, or collectible errors are used.
- Error messages shown to users changed.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
