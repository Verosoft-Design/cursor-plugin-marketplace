---
name: bcq-review-performance
description: Run only the BCQuality Performance review (al-performance-review) on AL code, covering filtering before iterating, SetLoadFields, IsEmpty vs Count, FindSet and locking, CalcFields/CalcSums, per-row work and Commit inside loops, keys and SIFT, and caching. The other 18 leaves and the `al-code-review` self-review pass are skipped. Use when the user specifically wants performance feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Performance review

Runs the `al-entry` skill with a goal that names performance explicitly, so Entry's super-skill precedence drops `al-code-review` (`narrower-sub-skill-selected`) and dispatches the `al-performance-review` leaf alone. The other 18 leaves and the `al-code-review` self-review pass are skipped.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-performance-review` adapter skill, which follows `<plugin>/content/bcquality/microsoft/skills/review/al-performance-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/performance/`.
- `<plugin>/content/bcapps-review-prompts/performance.md` (BCApps' MIT-licensed performance review prompt for complementary guidance; frozen at BCApps `7040033d`: upstream deleted these prompts in favour of BCQuality, so treat them as supplementary and let BCQuality win on conflict).

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-performance-review"`. Every finding carries `domain: "Performance"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- Hot-path, posting, or batch code changed.
- Investigating slow pages, reports, or job queue entries.
- Auditing data-access patterns in a file, PR, or app folder.

When the user does not name a specific concern, use `/bcq-review`. Its cross-domain self-review catches issues a single leaf cannot.
