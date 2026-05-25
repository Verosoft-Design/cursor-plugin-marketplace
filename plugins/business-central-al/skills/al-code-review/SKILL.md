---
name: al-code-review
description: Run a comprehensive BCQuality-driven review of AL code changes by composing the 6 leaf review skills (performance, security, privacy, upgrade, style, UI) plus an agent self-review pass. Emits a single findings-report JSON per the DO contract. Use for broad PR reviews, full-file reviews, or whenever the user asks for "a code review" without naming a specific domain.
---

# AL Code Review — super-skill orchestrator

This skill is the Cursor adapter for the BCQuality `al-code-review` super-skill.

## Authoritative spec

Read `<plugin>/content/bcquality/microsoft/skills/review/al-code-review.md` in full. It declares:

- `kind: action-skill`, `id: al-code-review`, `version: 1`
- `inputs: [pr-diff, file-path, object-list]` (any non-empty subset is sufficient)
- `outputs: [findings-report]`
- `sub-skills`: the 6 leaf skills listed under `microsoft/skills/review/`

The vendored upstream file has the full Source / Relevance / Worklist / Action sections. Follow them exactly.

## What this skill does in Cursor

1. **Apply contract rules.** Load `bcquality-do-contract` (output shape, severity, agent-findings encoding, composition rules) and `bcquality-read-contract` (knowledge file parsing).
2. **Invoke each sub-skill.** For each of the 6 leaves listed in the upstream super-skill's `sub-skills`:
   - `al-performance-review`, `al-security-review`, `al-privacy-review`, `al-upgrade-review`, `al-style-review`, `al-ui-review`
   - Pass the same task inputs to each (the strict intersection of inputs-available with each leaf's declared inputs).
   - Each leaf produces its own findings-report.
3. **Do NOT filter sub-skills by task content.** Per DO: "the super-skill MUST NOT filter sub-skills by task content. Each leaf is responsible for its own task-level applicability decision; leaves signal non-applicability by returning `outcome: 'not-applicable'` or `outcome: 'no-knowledge'`."
4. **Perform the agent self-review pass.** AFTER the sub-skill rollup, do a second pass against the same input using the agent's built-in BC and AL knowledge. BCQuality is _additive_ — it augments the agent's review judgement, it does not replace it. Surface defects the agent recognizes that the leaves missed because no BCQuality knowledge file covers them yet.
5. **Validate every agent finding against the loaded knowledge.** For each candidate finding the agent emits in step 4:
   - If a loaded BCQuality knowledge file MATCHES → upgrade to a knowledge-backed finding (merge with the corresponding sub-skill's output if already present; otherwise add to the appropriate leaf's findings).
   - If a loaded knowledge file CONTRADICTS → suppress the candidate.
   - Otherwise → emit as an agent finding with `from-sub-skill: "agent"`, `references: []`, `id: "agent:<slug>"`, `confidence` capped at `medium`, and a self-contained `message`.
6. **Roll up the outcome.** Per DO's precise rules:
   - All `failed` → super-skill `failed`.
   - Any `partial` (or `failed` mixed with non-`failed`) → `partial`.
   - All `not-applicable` → `not-applicable`.
   - All `no-knowledge`/`not-applicable` with at least one `no-knowledge` → `no-knowledge`.
   - Otherwise → `completed`.
7. **Roll up the summary.** Sum `summary.counts` and `summary.coverage` across invoked sub-skills.
8. **Emit the JSON.** Full DO-contract shape: top-level `findings[]` (sub-skill findings with `from-sub-skill` set + agent findings), plus `sub-results[]` containing each sub-skill's complete findings-report verbatim, plus `skipped-sub-skills[]` for any that were disabled.

## Output rendering

After emitting the JSON, optionally pipe through `bash <plugin>/scripts/render-findings.sh` for a human-readable summary table. Surface each finding's `location.file:line` as a clickable reference in chat. Reference each citation by its knowledge-file path with a link to the file in the plugin's content directory.

## Safety

- **Agent findings are capped at `medium` confidence.** Never `high` — without a knowledge-file citation there is no authoritative basis.
- **Agent finding `id` MUST start with `agent:`.** Mirror the `<sub-skill-id>:` prefix rule for sub-skill non-citation rollups.
- **A failed leaf's findings are NOT copied into the super-skill's top-level `findings[]`.** They remain in `sub-results[]` for traceability per DO.

## When to invoke

This skill is auto-dispatched by `al-entry` when the user's goal broadly matches "review" without naming a specific concern. Direct invocations:

- `/bcq-review` — the canonical entry point.
- `/bcq-review-performance`, `/bcq-review-security`, `/bcq-review-privacy`, `/bcq-review-style`, `/bcq-review-upgrade`, `/bcq-review-ui` — bypass the super-skill and invoke a single leaf (`al-entry` selects the leaf via `narrower-sub-skill-selected`).
