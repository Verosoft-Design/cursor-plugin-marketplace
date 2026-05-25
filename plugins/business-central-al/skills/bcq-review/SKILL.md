---
name: bcq-review
description: Run the comprehensive BCQuality review on AL code changes. Routes via al-entry to al-code-review (super-skill) which composes the 6 leaf reviews plus an agent self-review pass and emits a single findings-report JSON. Use for PR reviews, full-file reviews, or whenever the user wants the full quality pass.
disable-model-invocation: true
---

# Comprehensive BCQuality review

Dispatches the `al-entry` skill, which selects `al-code-review` (the BCQuality super-skill) and runs all 6 leaf reviews (performance, security, privacy, upgrade, style, ui) plus an agent self-review pass.

## What to feed it

Pass whatever the user supplies:

- A PR diff (`gh pr diff <number>` output, or the diff against `main`).
- A single file path (`src/Sales/Posting.Codeunit.al`).
- An object list (`["TAG Equipment", "TAG Work Order Header"]`).
- The whole repo (`.` — slowest, broadest).

The strict intersection of these inputs and each sub-skill's declared `inputs` determines what each sub-skill actually receives.

## Flow

1. Invoke `al-entry` with the task context.
2. `al-entry` reads `<plugin>/content/bcquality/entry.md` and emits a dispatch record naming `al-code-review`.
3. `al-code-review` reads `<plugin>/content/bcquality/microsoft/skills/review/al-code-review.md` and invokes each of the 6 leaves in turn.
4. Each leaf reads its corresponding upstream skill spec and produces a findings-report JSON.
5. `al-code-review` rolls up the JSONs per DO, runs the agent self-review pass, and emits the final super-skill JSON.
6. The agent pretty-prints via `bash <plugin>/scripts/render-findings.sh` and surfaces clickable file:line references.

## Targeted alternatives

When the user specifies a domain, bypass the super-skill and dispatch the leaf directly:

- `/bcq-review-performance`
- `/bcq-review-security`
- `/bcq-review-privacy`
- `/bcq-review-upgrade`
- `/bcq-review-style`
- `/bcq-review-ui`

(`al-entry` will route these via the `narrower-sub-skill-selected` precedence rule.)

## Output

A single JSON document per the DO contract:

- `skill: { id: "al-code-review", version: 1 }`
- `outcome: "completed" | "partial" | "no-knowledge" | "not-applicable" | "failed"`
- `summary.counts.{blocker,major,minor,info}` summed across leaves
- `findings[]` — each with `id`, `severity`, `message`, `location`, `references`, `confidence`, `from-sub-skill`
- `sub-results[]` — each sub-skill's complete report verbatim, for traceability
- `suppressed[]` — knowledge files overridden by layer precedence (custom over community over microsoft)

Render in chat: a summary table grouped by severity and sub-skill, with each finding linkable to its `location.file:line` and to its cited knowledge file in `<plugin>/content/bcquality/`.

## Safety

- The super-skill MUST NOT filter sub-skills by task content. Every leaf gets invoked; leaves return `not-applicable` when they have nothing to do.
- Agent findings (from the self-review pass) MUST carry `from-sub-skill: "agent"`, `references: []`, `id: "agent:..."`, and `confidence ≤ medium`.
- A failed leaf's findings do NOT contribute to the super-skill's top-level `findings[]` — they remain in `sub-results[]` only.

## When the content is stale

If the underlying BCQuality content is suspected stale (more than a few weeks old), suggest `/bcq-update` to refresh the pinned vendored copy.
