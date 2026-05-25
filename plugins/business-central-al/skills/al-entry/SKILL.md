---
name: al-entry
description: Route a Business Central AL task to the right BCQuality action skill. Reads the task context, applies BCQuality's entry-point routing (goal match → super-skill precedence → layer precedence), and dispatches the named skill or skills. Use as the front door for /bcq-review when the user does not specify a particular review domain.
---

# AL Entry — task router

This skill is the Cursor adapter for the BCQuality entry-point routing contract. It does NOT replicate the logic. It loads the authoritative spec and applies it.

## What to do

1. **Load the entry-point spec.** Read `<plugin>/content/bcquality/entry.md` in full. It defines the exact routing semantics.
2. **Load the contract rules.** Apply the `bcquality-entry-contract` rule (this skill's behavior is governed by it) and the `bcquality-read-contract` rule (skill frontmatter is parsed per READ's matching semantics).
3. **Build the task context.** Construct a `task-context` matching entry.md's input schema:
   - `goal`: free-text description of what the user asked for (extract from the prompt).
   - `inputs-available`: what the orchestrator can supply — typically `[pr-diff]` for a GitHub PR review, `[file-path]` for in-editor work, `[object-list]` when a specific set of AL objects is named, `[repository]` for whole-repo audits, `[telemetry-query]` for KQL queries.
   - `technologies`: usually `[al]`; add `[javascript]` for control add-ins; expand only when the task genuinely covers other tech.
   - `bc-version`: read from `app.json` of the workspace's AL project if present, otherwise omit (`unknown` treatment).
   - `countries`: read from `.AL-Go/settings.json` → `country` if present, otherwise omit.
   - `application-area`: derive from the changed objects' declared `ApplicationArea` when known, otherwise omit.
   - `enabled-layers`: `[microsoft, community, custom]` by default.
   - `disabled-skills`: empty by default. The user can override via plugin config.
4. **Enumerate candidates.** Find all action skills under `<plugin>/content/bcquality/{microsoft,community,custom}/skills/**/*.md`. Today that is:
   - `microsoft/skills/review/al-code-review.md` (super-skill, declared `sub-skills`)
   - `microsoft/skills/review/al-performance-review.md`
   - `microsoft/skills/review/al-security-review.md`
   - `microsoft/skills/review/al-privacy-review.md`
   - `microsoft/skills/review/al-upgrade-review.md`
   - `microsoft/skills/review/al-style-review.md`
   - `microsoft/skills/review/al-ui-review.md`
5. **Apply the 3-tier worklist ranking.** Per entry.md: Goal match → Super-skill precedence → Layer precedence. Drop unmatched candidates into the `skipped[]` list with the right reason.
6. **Emit a dispatch record.** Single JSON document per entry.md's output contract. Pass to the agent's next step.
7. **Invoke each dispatched skill.** For each entry in `dispatch[]`, read the corresponding upstream skill file (e.g. `content/bcquality/microsoft/skills/review/al-performance-review.md`) and execute its Source / Relevance / Worklist / Action pattern against the supplied inputs.
8. **Collect findings-reports.** Each dispatched skill produces a JSON per the DO contract. The agent returns them to the user.

## Dispatch decision examples

| User says                                             | Expected dispatch                                                               |
| ----------------------------------------------------- | ------------------------------------------------------------------------------- |
| "Review this PR"                                      | `al-code-review` (super-skill — broad goal)                                     |
| "Review this PR for performance issues"               | `al-performance-review` (narrower-sub-skill-selected — goal names performance)  |
| "Check for security and privacy issues in src/Sales/" | both `al-security-review` and `al-privacy-review` (Entry can dispatch multiple) |
| "Make this faster" + diff containing `FindFirst`      | `al-performance-review`                                                         |
| "Is this UI accessible?"                              | `al-ui-review`                                                                  |

## When the worklist is empty

If no candidate passes all three ranking tiers, return `outcome: no-match` per entry.md. Do NOT synthesize a dispatch from nothing.

## When invocation fails

If reading `content/bcquality/entry.md` fails (file missing, etc.), return `outcome: failed` with `outcome-reason` describing the missing infrastructure, and direct the user to `/bcq-update`.

## Reference

- `<plugin>/content/bcquality/entry.md` — authoritative spec.
- `<plugin>/rules/bcquality-entry-contract.mdc` — Cursor-side pointer rule.
- `<plugin>/rules/bcquality-read-contract.mdc` — for parsing skill frontmatter.
- `<plugin>/rules/bcquality-do-contract.mdc` — for the dispatch-record output shape.
