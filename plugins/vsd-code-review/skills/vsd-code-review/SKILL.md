---
name: vsd-code-review
description: VSD pre-merge code review — thermo-nuclear structure + KISS/YAGNI + Fallow + deslop + test bar (one shot, report only). Pass "rerun" to score prior blockers.
disable-model-invocation: true
---

**VSD code review** — pre-merge quality review of **current uncommitted or branch changes**. Report only — do not edit code, commit, or fix findings unless the user explicitly asks after the review (or run `/deslop` separately to auto-fix slop).

## Scope

Review the working tree diff (`git diff` + `git diff --cached`) or, if the user says "branch" / names a base, `git diff <base>...HEAD`. Default: uncommitted + staged changes.

If `$ARGUMENTS` is `rerun`, include a **Prior blockers scorecard** table (Fixed / Partial / Remaining) against blockers called out in the immediately preceding review in this thread. If no prior review exists, skip the scorecard and note that.

## Phase 1 — Gather context (run in parallel)

1. `git status --short`
2. `git diff --stat` and `git diff --cached --stat`
3. `git diff` and `git diff --cached` (or branch diff if requested)
4. Line counts for every touched file that is **>400 lines** or grew by **>30 lines** in the diff (`wc -l`)

Read the full contents of new files and the changed regions of modified files. Skim adjacent canonical modules the diff touches (same directory or imported helpers).

## Phase 2 — Fallow hygiene

Read this plugin's `rules/fallow.mdc` and follow it. Fallow is optional tooling — first check whether it is available in the workspace (a `fallow` binary on PATH, a `fallow` devDependency, or a `dead-code:audit` package script). If it is not, write `Fallow not available in this workspace — skipped.` under **Fallow hygiene** and move on.

When Fallow is available:

| When | Command |
|------|---------|
| Substantial TS/JS behavior change | the repo's dead-code audit script (e.g. `bun run dead-code:audit`) or `fallow audit --format json` |
| Suspected duplication / overlap with existing code | `fallow dupes --trace <file>:<line>` on the changed symbol or block |
| Before recommending deletion | `fallow inspect --symbol <file>:<export>` |

Fold Fallow findings into the report under **Fallow hygiene**. Prefer deletion over suppression. Do not recommend knip/jscpd or parallel dead-code tools.

## Phase 3 — Thermo-nuclear structural audit

1. Read the thermo-nuclear rubric: this plugin's `skills/thermo-nuclear-code-quality-review/SKILL.md`
2. Launch the **thermo-nuclear-code-quality-review** subagent (`Task`, `subagent_type: thermo-nuclear-code-quality-review`, `readonly: true`) with:
   - Full diff summary and stat
   - Contents of new/changed files
   - Line counts and any file crossing **1000 lines**
   - Explicit instruction: apply rubric + search for code-judo moves; do not approve on correctness alone
3. If that subagent type is not registered in this session, apply the rubric yourself in a readonly pass instead.
4. Synthesize the subagent result — do not paste it verbatim if redundant.

## Phase 4 — KISS / YAGNI pass (ponytail lens)

Read this plugin's `rules/ponytail.mdc` and apply it. One line per finding, biggest cut first:

`L:… [path]` — tag: **delete** | **yagni** | **shrink** | **stdlib** | **native**

Ask explicitly:

- Does this need to exist at all?
- Are there three layers doing one job (cron + runtime + retry)?
- Do new files/abstractions have more than one caller?
- Is there a pass-through wrapper that adds indirection without clarity?
- Is unrelated work bundled in the same diff?

End this section with net lines theoretically removable, or `Lean on structure.` if the thermo-nuclear pass already cleared YAGNI concerns.

## Phase 5 — Deslop (AI slop audit)

Read and apply this plugin's `skills/deslop/SKILL.md` — but in **report-only** mode here.

Scan **only lines added or modified** in the diff. Compare each hunk to the surrounding file's style (comment density, error handling, typing). Report only — do not edit unless the user asks (they can run `/deslop` to fix).

Flag:

- Extra comments that restate the obvious or break local style
- Defensive checks / try/catch abnormal for trusted code paths
- `any` casts or loose typing used only to silence the compiler
- Deep nesting where early returns would match the file
- Verbose naming, redundant wrappers, or patterns inconsistent with neighbors

One line per finding: `L:… [path]` — tag: **comment** | **defensive** | **any-cast** | **nest** | **style**

If clean: `No slop.`

## Phase 6 — Test & TDD bar

Read this plugin's `rules/test-driven-development.mdc` and apply it:

- Flag substantial behavior changes without targeted automated tests
- Note if tests exist but fail under the repo's test runner
- List the **minimum tests** that would unblock merge (smallest seam, not E2E)

## Required output format

Use this structure exactly (omit empty sections):

### Verdict

One line: **Do not merge** | **Conditional approve** | **Approve** — with the single biggest reason.

### Prior blockers scorecard *(rerun only)*

| # | Prior blocker | Status |
|---|---------------|--------|

Statuses: **Fixed** | **Partial** | **Remaining** | **N/A**

### Ship-stoppers

Numbered list. Config bugs, >1k-line files without extraction, broken tests, secrets, duplicate cron/routes, etc.

### Structural / code-judo

What to extract, merge, delete, or inline. Prefer "delete whole layer" over "rename helper."

### KISS / YAGNI cuts

Tagged one-liners from Phase 4.

### Deslop

Tagged one-liners from Phase 5, or `No slop.`

### Fallow hygiene

Findings from Phase 2 (new dead exports, dupes, regression baseline risk), or the skipped note when Fallow is unavailable.

### Test gaps

What's untested + minimum test to add.

### Approval bar

| Criterion | Pass? |
|-----------|-------|
| No structural regression | |
| No file >1k without justification | |
| No spaghetti / scattered special cases | |
| Canonical layer / no duplicate helpers | |
| Tests protect substantial behavior | |
| No AI slop introduced | |
| Fallow clean (no new dead-code regression) | |

### Ship after

Numbered checklist of **only** merge-blocking items. Separate **Follow-up polish** for non-blocking improvements.

---

**Tone:** Direct, demanding, actionable — like a lazy senior dev who cares about the codebase long-term. Do not soften structural issues. Do not flood with nits when ship-stoppers exist. Do not approve merely because behavior seems correct.
