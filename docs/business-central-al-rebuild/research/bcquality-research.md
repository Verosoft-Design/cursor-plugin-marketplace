# BCQuality — Exhaustive Research Report

> Source: <https://github.com/microsoft/BCQuality> (branch `main`, fetched 2026-05-25).
> The repository contains the README, agent-consumption doc, 4 global skill files (entry + READ/DO/WRITE), 7 action-skill files (al-code-review super-skill plus 6 leaf review skills), 154 knowledge articles (`.md`), and 234 sibling AL sample files (`.good.al` / `.bad.al`). Repo top-level files: `README.md`, `agent-consumption.md`, `LICENSE`, `SECURITY.md`, `CODEOWNERS`, `.gitignore`.

---

## 1. Executive summary

**BCQuality** is Microsoft's emerging *machine-readable* quality bar for Business Central / AL development. It is "a curated knowledge base and skills library… [that provides] structured, machine-readable guidance that development agents and tools can consume — establishing a consistent quality bar across tooling and teams" (README). Crucially the repo is **content only**: it contains no agents and no orchestrator. Agents (AL-Go, IDE extensions, GitHub Agent invocations, etc.) point at the repo, invoke a single entry-point skill (`/skills/entry.md`), and follow a strict 4-step skill template (**Source → Relevance → Worklist → Action**) that always produces the same JSON output shape. The knowledge base is deliberately **remedial** — a file exists only because "a modern LLM reviewing or generating BC code [would] make a mistake this file would have prevented" (README admission test). Authority is layered: `/microsoft/` → `/community/` → `/custom/` with `/custom/` highest precedence on conflicts (READ).

For a Cursor plugin, the integration shape is straightforward but powerful: treat BCQuality as a *content source* you map into Cursor's own skills + rules + commands. (1) Mirror the 6 review domains as Cursor skills that read the corresponding `microsoft/knowledge/<domain>/*.md` files. (2) Surface `entry.md` as a routing command. (3) Pin the four global meta-skills (entry, read, do, write) as agent-requestable rules so the plugin's agent always interprets knowledge files correctly. (4) Materialize the standardized JSON output contract so PR-review or in-editor diagnostics map cleanly. (5) Allow the user to add their own `/custom/knowledge/` content under `.cursor/bcquality/custom/` — the layer precedence rule means this works for free.

---

## 2. Repository structure

Full tree (from `https://api.github.com/repos/microsoft/BCQuality/git/trees/main?recursive=1`, 438 paths total):

```
├── README.md
├── agent-consumption.md          # operational consumption flow (mermaid + actors)
├── CODEOWNERS                    # /microsoft/, /skills/, /.github/ → @jeschulz
├── LICENSE                       # MIT
├── SECURITY.md                   # links to aka.ms/SECURITY.md
├── .gitignore
│
├── .github/
│   ├── scripts/
│   │   └── validate_frontmatter.py   # 568 lines, rules R01-R25
│   └── workflows/
│       └── validate-frontmatter.yml  # PR + push to main, Python 3.12 + pyyaml
│
├── skills/                        # Global: entry-point + 3 meta-skill contracts
│   ├── README.md
│   ├── entry.md                   # kind: entry-point, id: entry
│   ├── read.md                    # kind: meta-skill, id: read (READ)
│   ├── do.md                      # kind: meta-skill, id: do  (DO)
│   └── write.md                   # kind: meta-skill, id: write (WRITE)
│
├── microsoft/                     # Microsoft-endorsed layer
│   ├── knowledge/
│   │   ├── performance/   (35 articles, 51 samples)
│   │   ├── privacy/       (17 articles, 18 samples)
│   │   ├── security/      (18 articles, 35 samples)
│   │   ├── style/         (33 articles, 56 samples)
│   │   ├── testing/       (1 article,   2 samples)
│   │   ├── ui/            (19 articles, 15 samples)
│   │   └── upgrade/       (18 articles, 34 samples)
│   └── skills/
│       └── review/
│           ├── al-code-review.md          # SUPER-SKILL (sub-skills: 6 below)
│           ├── al-performance-review.md
│           ├── al-security-review.md
│           ├── al-privacy-review.md
│           ├── al-upgrade-review.md
│           ├── al-style-review.md
│           └── al-ui-review.md
│
├── community/                     # BC community layer
│   ├── knowledge/
│   │   ├── performance/   (7 articles, 13 samples)
│   │   └── security/      (6 articles, 10 samples)
│   └── skills/                    # empty (.gitkeep only)
│
└── custom/                        # Partner / customer overrides (template)
    ├── README.md                   # "Custom layer" template explainer
    ├── knowledge/                  # .gitkeep
    └── skills/                     # .gitkeep
```

Totals: **154 knowledge articles** + **234 AL sample files** across both layers. Microsoft layer dominates everything except where community has chosen to contribute (currently only `performance` and `security`). All 7 leaf-skill files for review live under `microsoft/skills/review/`.

Important meta-facts from the README and `agent-consumption.md`:
- "BCQuality contains knowledge and skills. It does **not** contain agents. Agents that consume BCQuality ship with AL-Go and other orchestrators." (README)
- The repo is in active preview: "This project is under active development. Large and potentially breaking changes are expected. Public preview will soon be announced." (top of README)
- The CODEOWNERS file gates Microsoft-endorsed content to a single reviewer (`@jeschulz`); community content "reviewers are added as the contributor base grows".

---

## 3. Skill architecture

### 3.1 The actors and the flow

From `agent-consumption.md`:

> - **Orchestrator** — the tool that triggers work (e.g. AL-Go on a pull request, or a VS Code extension on save). Lives *outside* BCQuality. Knows *when* to run something, not *what* to run.
> - **Agent** — an LLM-driven process spawned by the orchestrator. The agent has no built-in knowledge of BC or of BCQuality's conventions. It knows how to read instructions and call tools.
> - **BCQuality repo** — two kinds of content:
>   - **Global skills** in `/skills/` — the `entry.md` entry-point skill plus the READ · DO · WRITE contracts that govern the rest of the repo.
>   - **Layer content** in `/microsoft/`, `/community/`, and `/custom/` — knowledge files and action skills grouped by authority.

The mermaid diagram from `agent-consumption.md`:

```
Orchestrator (AL-Go)
   ↓  1: trigger + task context
Agent
   ↓  2: invoke entry.md
Entry (routing skill)
   ↓  3: dispatch record
Agent
   ↓  4: invoke dispatched skill
Action skill (e.g. al-code-review)
   ↓  5: execute Source → Relevance → Worklist → Action  (reading READ · DO on demand)
   ↓  6: emit findings · references · confidence
Orchestrator   ← 7: integrate
```

Mental model — one sentence (quoted from agent-consumption.md):
> The orchestrator knows **when** to run; Entry decides **which skill** to run; the action skills define **what** to do; the meta-skills teach the agent **how** to behave; the knowledge files are **what** the agent knows.

### 3.2 The `entry.md` entry-point skill

`entry.md` is the only hardcoded contract an orchestrator needs to know. It accepts a `task-context` YAML object, evaluates *action skills* (not knowledge files) through the same 4-step pattern, and returns a *dispatch record*.

Frontmatter:

```yaml
---
kind: entry-point
id: entry
version: 1
title: Entry — route a task to the action skill(s) that apply
---
```

Inputs schema:

```yaml
task-context:
  goal: string            # free-text description of what needs doing
  inputs-available:       # values the orchestrator has ready to pass to a chosen skill
    - pr-diff
    - file-path
  technologies: [al]
  bc-version: 28
  countries: [w1]
  application-area: [finance]
  enabled-layers: [microsoft, community, custom]
  disabled-skills: []     # repo-relative paths the consumer has opted out of
```

Entry's Source = "all action skills under `*/skills/**/*.md` across the layers named in `enabled-layers`" — meta-skills in `/skills/` "are not candidates and MUST be excluded. Entry never dispatches Entry."

Entry's Worklist applies a critical three-tier ranking:
1. **Goal match.** Score `description` and `id` against the goal; "agents MUST prefer exact keyword overlap before fuzzy signals."
2. **Super-skill precedence.** A super-skill supersedes its listed sub-skills *only when the goal is a broader match for the super-skill*. "When the goal specifically names a concern the sub-skill handles (for example, goal = *'performance review'* with `al-code-review` and `al-performance-review` both present), the sub-skill wins and the super-skill is dropped with `reason: 'narrower-sub-skill-selected'`. Otherwise the super-skill wins and each listed sub-skill in the set is dropped with `reason: 'superseded-by-super-skill'`. The principle is: Entry dispatches the narrowest skill that satisfies the goal."
3. **Layer precedence.** When two candidates share the same `id` across layers, "keep the highest-precedence one. Skill layer precedence is `/custom/` over `/community/` over `/microsoft/` — the same ordering READ defines for knowledge files."

Entry's Output (verbatim from `skills/entry.md`):

```json
{
  "skill": { "id": "entry", "version": 1 },
  "outcome": "routed | no-match | failed",
  "outcome-reason": "string",
  "dispatch": [
    {
      "skill": {
        "id": "al-code-review",
        "version": 1,
        "path": "microsoft/skills/review/al-code-review.md"
      },
      "rationale": "string",
      "inputs": ["pr-diff"]
    }
  ],
  "skipped": [
    {
      "skill": { "id": "string", "path": "string" },
      "reason": "inputs-unsatisfied | filter-mismatch | goal-mismatch | layer-precedence | superseded-by-super-skill | narrower-sub-skill-selected | configuration",
      "superseded-by": { "id": "string", "path": "string", "version": 1 }
    }
  ]
}
```

Entry's `inputs` field in every dispatched skill is computed as the **strict intersection** of `task-context.inputs-available` and the dispatched skill's declared `inputs`. "The agent MUST pass exactly this subset when invoking the skill. Sending a strict intersection avoids accidental information leakage between skills."

### 3.3 The READ meta-skill (`skills/read.md`)

READ defines what a knowledge file is. Quoting verbatim:

> A knowledge file is a single markdown file that covers **one concern** in Business Central development. It has:
> - A YAML frontmatter block with the fields below. All fields are required.
> - A `## Description` section. Required.
> - Optional sections — typically `## Best Practice` and `## Anti Pattern`, but any `##` section is permitted.
> - No fenced code blocks. Sample code lives in **sibling files** next to the article …
> A file that violates any of these rules is invalid and MUST be skipped by consumers. Do not attempt to partially parse invalid files.

READ also defines the **frontmatter matching semantics** that Entry, the action skills, and any contract-conformant consumer use:

> - **`bc-version`** — the file matches if its set is `[all]`, or if the target BC version is an element of the file's expanded `bc-version` set. Range shorthand (`[26..28]`) MUST be expanded before comparison.
> - **`technologies`** — non-empty intersection between the task's technologies and the file's technologies. There is no sentinel for this field.
> - **`countries`** — the file matches if its set contains `w1`, or if there is a non-empty intersection with the task's countries.
> - **`application-area`** — the file matches if its set contains `all`, or if there is a non-empty intersection with the task's application areas.

When a dimension is missing from the task context, READ requires an **unknown / conditionally applicable** treatment, not silent matching:

> If the file's value for that dimension is a universal sentinel (`all` for bc-version, `w1` for countries, `all` for application-area), the rule matches. Otherwise the rule is treated as **unknown**, not as a match and not as a failure.
> A file with any `unknown` rule is **conditionally applicable**. … if it does, every finding derived from such a file MUST have `confidence` no higher than `medium` and MUST record the unknown dimensions in the finding's `message`.

**Layer precedence (from READ):**

> 1. `/custom/` wins over `/community/` and `/microsoft/`.
> 2. `/community/` wins over `/microsoft/`.
>
> A conflict exists when both of the following are true:
> - **Applicability overlaps.** The files' frontmatter filters (`bc-version`, `technologies`, `countries`, `application-area`) have a non-empty intersection under the matching rules below. `domain` is a retrieval aid; it is not part of the applicability test.
> - **Normative guidance contradicts.** Content in the `## Best Practice` or `## Anti Pattern` sections is logically incompatible …

**Sample files convention** is fully defined inside READ:

> Knowledge files MUST NOT contain fenced code blocks. When an article needs to show code, it ships the code as one or more **sibling files** next to the article, using this naming convention:
>
> ```
> <layer>/knowledge/<domain>/<slug>.md         # the article
> <layer>/knowledge/<domain>/<slug>.good.al    # best-practice demonstration
> <layer>/knowledge/<domain>/<slug>.bad.al     # anti-pattern demonstration
> ```
> Articles MAY have a `good` sample only, a `bad` sample only, both, or neither. The article text SHOULD reference each sample it ships, using a relative path like `` `<slug>.good.al` ``.
> Samples are **demonstration-only**. They are not deployed, not compiled as part of a published app, and not derived from the Business Central base application source.

### 3.4 The DO meta-skill (`skills/do.md`)

DO defines the action-skill template and the universal JSON output contract.

**Action-skill frontmatter schema:**

```yaml
---
kind: action-skill
id: al-code-review
version: 1
title: AL code review
description: Reviews AL source changes against performance and security guidance.
inputs: [pr-diff, object-list]
outputs: [findings-report]
bc-version: [26..28]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> `kind`, `id`, `version`, `title`, `description`, `inputs`, `outputs` are required and specific to action skills.
> `bc-version`, `technologies`, `countries`, `application-area` are optional filters that let an orchestrator pre-select applicable skills for a task. They follow the same semantics as in READ.
> `inputs` is a list of abstract input types the skill **accepts**. Standard values: `pr-diff`, `object-list`, `file-path`, `repository`, `telemetry-query`. Semantics are any-of: the orchestrator supplies whichever listed input types it has, and the skill is invoked with a non-empty subset of its declared `inputs`. A skill that cannot proceed with the supplied subset MUST return `outcome: "not-applicable"`. `outputs` is always a single-element list naming the output kind; today only `findings-report` is defined.
> `sub-skills` is an optional field. When present and non-empty, the skill is a **super-skill** that composes other action skills…

**Required sections (always 5, in order):**
1. `## Source` — declares which folders and tags to search for knowledge.
2. `## Relevance` — declares how to filter the candidates.
3. `## Worklist` — declares how to narrow filtered candidates to the set that applies to this task.
4. `## Action` — declares what the skill does with the narrowed set.
5. `## Output` — declares the shape of the produced output; typically a reference to the contract.

**The 4-step pattern** (verbatim from DO):

> **Source.** List the folders and tag filters to collect candidates from. Sources span layers: an action skill sources from the same `domain` subfolder across every enabled layer. Example: *"Source from `/*/knowledge/performance/` and `/*/knowledge/security/`."*
>
> **Relevance.** Apply frontmatter filters to the candidates. Typical filters: match `bc-version` against the target environment, match `technologies` against the languages in scope, match `countries` and `application-area` against the consuming codebase's context. The exact matching rules are defined in READ (*Frontmatter matching semantics*). Files that do not match are discarded.
>
> **Worklist.** Narrow the relevant candidates to the subset that applies to the current task. This is where the task-specific signal enters: the objects changed in the PR, the queries being audited, the skeleton being generated. Typical moves: match `keywords` against task vocabulary, match file topics against changed objects, deduplicate by concern.
>
> **Action.** Execute the skill's work against the worklist. Evaluate each item in the worklist against the task input and emit findings. The action step is where skill behavior differs; the preceding three steps are uniform.

**The universal JSON output contract** (verbatim from DO):

```json
{
  "skill": { "id": "string", "version": 1 },
  "outcome": "completed | not-applicable | no-knowledge | partial | failed",
  "outcome-reason": "string",
  "summary": {
    "counts": { "blocker": 0, "major": 0, "minor": 0, "info": 0 },
    "coverage": { "worklist-size": 0, "items-evaluated": 0 }
  },
  "findings": [
    {
      "id": "string",
      "severity": "blocker | major | minor | info",
      "message": "string",
      "location": {
        "file": "string",
        "line": 0,
        "range": { "start-line": 0, "end-line": 0 }
      },
      "references": [
        { "path": "string", "sha": "string" }
      ],
      "confidence": "high | medium | low",
      "from-sub-skill": "string"
    }
  ],
  "suppressed": [
    {
      "reference": { "path": "string", "sha": "string" },
      "reason": "layer-precedence | configuration"
    }
  ],
  "sub-results": [
    { "...full nested findings-report..." : null }
  ],
  "skipped-sub-skills": [
    {
      "skill": { "id": "string", "version": 1 },
      "reason": "configuration | not-applicable"
    }
  ]
}
```

**Outcome semantics** (verbatim):
- `completed` — the skill ran end-to-end; `findings` reflects the full result (including the empty set).
- `not-applicable` — the skill's frontmatter filters did not match the task context; the skill declined to run.
- `no-knowledge` — the skill ran but found no applicable knowledge files; `findings` MUST be empty.
- `partial` — the skill evaluated part of its worklist but did not finish. `summary.coverage` reflects the evaluated subset. Set `outcome-reason` to explain.
- `failed` — the skill encountered an error and produced no reliable findings. Set `outcome-reason`. Consumers SHOULD ignore `findings` on a failed outcome.

> An empty `findings` array with `outcome: completed` means the skill ran and found nothing to flag. Orchestrators MUST NOT conflate this with `not-applicable` or `no-knowledge`.

**Findings `id` rules:**

> For citation-based findings (any finding with a non-empty `references`), `id` MUST equal `references[0].path` — the primary knowledge file's repo-relative path. For skills that detect concerns without a direct citation, `id` is a skill-defined slug (kebab-case, stable across versions of the skill). The same `id` produced in two runs MUST refer to the same concern; consumers MAY deduplicate findings by `id`.
>
> When a super-skill rolls up a non-citation finding from a sub-skill (an `id` that is a slug, not a path), the super-skill MUST prefix the `id` with `<sub-skill-id>:` to avoid collisions across sub-skills (for example, a slug `missing-test` from `al-security-review` becomes `al-security-review:missing-test`). Citation-based findings are already globally unique through their repo-relative path and MUST NOT be rewritten.

**Agent findings** (the additive layer):

> A super-skill MAY emit findings that the agent identified through its own reasoning rather than from a BCQuality knowledge file. BCQuality is an **additive** knowledge layer: it augments the agent's pre-existing review judgement, it does not replace it. An agent finding is encoded by:
> - `from-sub-skill: "agent"` — the canonical marker. Use this exact value; do not invent equivalents.
> - `references: []` — required.
> - `id` — a skill-defined slug, prefixed with `agent:` (mirroring the `<sub-skill-id>:` rule). For example, `agent:obsolete-find-signature`.
> - `confidence` — capped at `medium`.
> - `message` — non-empty and self-contained.
>
> Agent findings are emitted **only by super-skills** (the `al-code-review` super-skill is the canonical example). Leaf sub-skills MUST NOT emit agent findings.
> Before emitting an agent finding, a super-skill MUST validate the candidate against the BCQuality knowledge it has already loaded for the task — if a knowledge file matches, the candidate is upgraded to a knowledge-backed finding (and merged or deduplicated against any sub-skill output that already covers the same concern); if a knowledge file explicitly contradicts the candidate, it is suppressed.

**Severity taxonomy** (verbatim):
- `blocker` — violates platform-level guarantees; the work cannot proceed as-is.
- `major` — significant defect; should be fixed before merge.
- `minor` — quality concern; worth flagging but not a gate.
- `info` — observation or context; not actionable on its own.

**Composition (super-skills)** rules (verbatim):

> A **super-skill** is an action skill whose frontmatter declares a non-empty `sub-skills: [...]`. A super-skill does not evaluate knowledge files directly; it invokes other action skills and composes their output.
> Composition is flat: a super-skill MAY list only leaf skills (skills without their own `sub-skills`). Nested super-skills are not permitted in v1.

Outcome rollup (verbatim — quoted as bullets):

> Let S be the multiset of sub-skill outcomes for sub-skills in the worklist (skipped sub-skills do not contribute):
> - `failed` — every element of S is `failed`.
> - `partial` — S contains at least one `partial`, OR S contains at least one `failed` alongside at least one non-`failed` outcome.
> - `not-applicable` — every element of S is `not-applicable`.
> - `no-knowledge` — every element of S is `no-knowledge` or `not-applicable`, and at least one is `no-knowledge`.
> - `completed` — otherwise (every element of S is `completed`, `no-knowledge`, or `not-applicable`, with at least one `completed`).
> When the worklist is empty (every sub-skill was skipped), `outcome` is `not-applicable`…

### 3.5 The WRITE meta-skill (`skills/write.md`)

WRITE is the authoring guide and exists only for scaffolding new content. Quotable highlights:

> One knowledge file covers **one concern**. If two ideas would share a file, split them into two files and cross-reference from the Description. A good test: could an action skill reasonably want to cite one without the other? If yes, they are two concerns.
>
> Symptoms that a file is trying to be two:
> - Two Best Practice sections.
> - A Description that uses "and" to join two topics.
> - `keywords` that span two unrelated vocabularies.
>
> Target under 100 lines. Ideal under 50. Long files almost always mean two concerns; the fix is to split, not to compress.

Choosing `bc-version`:

> Default to `[all]` when the guidance is universal — a BC language pattern, a property on a long-standing platform type, a CodeCop rule, or a platform behaviour that has not changed across versions. Use an explicit list or range (`[26, 27, 28]`, `[26..28]`) only when the guidance is tied to a version-gated API, a deprecation, or platform behaviour that genuinely differs across versions. Most knowledge files should be `[all]`; reach for a range only with a concrete reason.

The **Pre-PR checklist** (verbatim from WRITE):

> - Frontmatter has all six required fields with valid values (see READ).
> - The file has a `## Description` section.
> - No fenced code blocks.
> - File is under 100 lines.
> - File covers one concern.
> - File is in the correct layer and domain folder.
> - Name is kebab-case and descriptive.
> Agents scaffolding new files SHOULD run this checklist programmatically before emitting the file.

---

## 4. Knowledge file format

### 4.1 Frontmatter schema (v1)

From `skills/read.md`:

```yaml
---
bc-version: [all]                       # or [26, 27, 28] or the range shorthand [26..28]
domain: performance
keywords: [query, filtering, partial]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

All six fields are **required** (CI fails on missing/empty per rule R02 below). Per-field semantics:

| Field | Type | Sentinels | Notes |
|---|---|---|---|
| `bc-version` | array | `[all]` | also accepts explicit `[26, 27, 28]` or range shorthand `[26..28]`; consumers must expand ranges before comparison; `[all]` is mutually exclusive with explicit versions. |
| `domain` | single string | n/a | open enumeration; standard values include `performance`, `security`, `ux`, `telemetry`, `testing`, `api`, `pipelines`, `finance`, `supply-chain`, `manufacturing`, `jobs`; unknown domains are valid. |
| `keywords` | array of kebab-case strings | n/a | 3–10 typical; lowercase kebab-case; "describe the concern in the vocabulary an engineer or agent would search for". |
| `technologies` | array of strings | **no `all` allowed** | examples: `al`, `javascript`, `powershell`, `kql`, `azure-devops`, `github-actions`. |
| `countries` | array of strings | `[w1]` (worldwide) | otherwise lowercase ISO 3166-1 alpha-2; `[w1]` is mutually exclusive with country codes. |
| `application-area` | array of strings | `[all]` | examples: `finance`, `manufacturing`, `jobs`, `warehousing`, `service`; `[all]` is mutually exclusive with specific areas. |

### 4.2 Required and optional sections

- **`## Description`** — required. Primary retrieval target. 2–5 sentences. "Write it as if a skill is deciding whether to load this file based on this text alone." (WRITE)
- **`## Best Practice`** — optional, recommended. **Normative**: consumers MAY rely on contents for conflict detection.
- **`## Anti Pattern`** — optional, recommended. **Normative**.
- Any other `##` section is permitted and is **non-normative** (e.g., `## See also`, `## Applies to`). "Consumers MUST NOT treat its contents as binding guidance."

### 4.3 Hard rules

- **No fenced code blocks.** (CI rule R10.) Code samples live in sibling `.good.al` / `.bad.al` files only.
- **File ≤ 100 lines.** (CI rule R11; WRITE recommends under 50.)
- **Atomic — one concern per file.** (WRITE)
- **kebab-case file name.** (CI rule R12.)
- **Path shape `<layer>/knowledge/<domain>/<slug>.md`.** (CI rule R13.)
- **Sample file naming `<slug>.<kind>.<ext>` where kind ∈ {good, bad}.** (CI rule R14.)

### 4.4 The remedial-knowledge admission test

From README (verbatim):

> If this file did not exist, would a modern LLM reviewing or generating BC code make a mistake this file would have prevented?
>
> If the answer is no — the advice is generic software-engineering guidance, or the LLM already knows the BC mechanic in question — the file does not belong here, regardless of how sound the content is. A file earns its place by encoding something BC-specific that LLMs demonstrably get wrong: a CodeCop rule number, a platform API whose semantics the training data gets backwards, a non-obvious ordering rule, a BC property whose default is a footgun.
>
> Good fit: "`SetLoadFields` must be called before filters, not after" (non-obvious ordering rule). "`FindSet(true)` takes a LockTable and the two-parameter signature is obsolete" (subtle platform behaviour + outdated training data). "CodeCop AA0233 flags `FindFirst … Next` loops" (rule-specific).
>
> Poor fit: "Use HTTPS instead of HTTP." "Don't hardcode secrets." "Keep transactions short." These are true but any capable LLM already applies them without prompting.

### 4.5 Sample knowledge files (verbatim)

A representative slice across domains follows. Each entry shows the **full markdown body** so you can see exactly how frontmatter, sections, and sample-file cross-references are written in practice.

---

#### 4.5.1 `microsoft/knowledge/performance/use-setloadfields-for-partial-records.md`

```yaml
---
bc-version: [all]
domain: performance
keywords: [setloadfields, partial-record, normal-field, flowfield, get, findset]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

Body:

> # Use SetLoadFields to load only the fields the code reads
>
> ## Description
> `SetLoadFields(...)` declares the subset of normal fields the next read should materialize, "reducing data read and transfer thereby improving performance significantly." Per the upstream guidance, "the gains scale with the amount of rows read, so for loops that read many rows `SetLoadFields` is even more important." Primary-key fields, `SystemId`, and system audit fields are loaded automatically, "and fields that are filtered on are also automatically included" — those do not need to appear in the list. `SetLoadFields` only affects `FieldClass = Normal`; it does not narrow FlowFields or FlowFilters.
>
> ## Best Practice
> Before a `Get`, `FindSet`, or `FindFirst` that the procedure follows by reading only a handful of the table's fields, call `SetLoadFields` listing exactly those fields. The pattern `SetLoadFields(...); if Record.Get(...) then ...` is the upstream-endorsed shape. Skip `SetLoadFields` when the table has few fields (under ten), when the code reads most of them (above 60 %), when the loop runs ten or fewer iterations, or when the table is exempt for other reasons (`singleton-setup-tables-need-no-access-optimization.md`, `temporary-tables-have-no-database-cost.md`). For report dataitems, use `AddLoadFields` in `OnPreDataItem` instead (see `addloadfields-in-report-onpredataitem.md`).
>
> See sample: `use-setloadfields-for-partial-records.good.al`.
>
> ## Anti Pattern
> Loading a wide table and reading one field per row in a loop. The bytes transferred per row are dominated by the columns the procedure does not touch; the SQL query selects them anyway. The same applies to a single `Get` on a wide table — the platform reads the whole row when a single field would have sufficed.
>
> See sample: `use-setloadfields-for-partial-records.bad.al`.

Its sibling `use-setloadfields-for-partial-records.good.al`:

```al
codeunit 50218 "Perf Sample LoadFields Good"
{
    procedure ListUSCustomerNames()
    var
        Customer: Record Customer;
    begin
        Customer.SetLoadFields(Name);
        Customer.SetRange("Country/Region Code", 'US');
        if Customer.FindSet() then
            repeat
                Message(Customer.Name);
            until Customer.Next() = 0;
    end;

    procedure LookupSkuPolicy(LocationCode: Code[10]) Policy: Enum "SKU Creation Method"
    var
        Location: Record Location;
    begin
        Location.SetLoadFields("SKU Creation Policy");
        if Location.Get(LocationCode) then
            Policy := Location."SKU Creation Policy";
    end;
}
```

And its sibling `use-setloadfields-for-partial-records.bad.al`:

```al
codeunit 50219 "Perf Sample LoadFields Bad"
{
    procedure ListUSCustomerNames()
    var
        Customer: Record Customer;
    begin
        // Loads every Customer column on every row, when only Name is read.
        Customer.SetRange("Country/Region Code", 'US');
        if Customer.FindSet() then
            repeat
                Message(Customer.Name);
            until Customer.Next() = 0;
    end;
}
```

Note the structural pattern: knowledge file references its samples by relative filename inside the article body, and each sample is a self-contained codeunit (typically in the 50200–50300 range) so it compiles in isolation if a consumer wants to lint it.

---

#### 4.5.2 `microsoft/knowledge/performance/findset-true-applies-updlock-on-read.md`

```yaml
---
bc-version: [all]
domain: performance
keywords: [findset, updlock, readisolation, locking, modify, obsolete-syntax]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> # FindSet(true) applies UpdLock on the read; the two-parameter form is obsolete
>
> ## Description
> `FindSet()` and `FindSet(false)` are read-only — no locking. Per the upstream guidance, `FindSet(true)` "signifies the intent is to modify records" and "sets `ReadIsolation::UpdLock` on the record before finding rows." That is exactly the right shape when the loop body modifies each row: the read takes the same lock the modification will need, avoiding the deadlock window between an unlocked read and a later upgrade. The older two-parameter form `FindSet(ForUpdate, UpdateKey)` is obsolete — only the single-parameter signature should appear in new code.
>
> ## Best Practice
> Use `FindSet(true)` only when the loop body genuinely modifies the iterated rows; use `FindSet()` (or `FindSet(false)`) when the loop only reads. Do not write `FindSet(true, true)` or `FindSet(true, false)` — the two-parameter form is the obsolete signature.
>
> See sample: `findset-true-applies-updlock-on-read.good.al`.
>
> ## Anti Pattern
> `FindSet(true)` on a loop that does not modify the iterated rows takes an `UpdLock` the work does not need; competing readers and writers stall against a lock the loop never uses. The mirror anti-pattern is `FindSet()` (no parameter) on a loop that *does* modify each row — the read takes a shared lock, the `Modify` then needs to upgrade, and the gap between them is a deadlock candidate.
>
> See sample: `findset-true-applies-updlock-on-read.bad.al`.

---

#### 4.5.3 `microsoft/knowledge/performance/use-isempty-for-existence-check.md`

```yaml
---
bc-version: [all]
domain: performance
keywords: [isempty, count, findfirst, existence-check, exists]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> # Use IsEmpty for existence checks, not Count() or FindFirst()
>
> ## Description
> When the caller only needs to know whether any row matches a filter, `IsEmpty()` is the API designed for the question. Per the upstream guidance, "`IsEmpty()` is more efficient as it stops at first record found." `Count() > 0` materializes a count the caller does not need; `FindFirst()` materializes a row the caller does not need. Both do work that `IsEmpty` does not.
>
> ## Best Practice
> Phrase existence checks as `if not Record.IsEmpty() then ...` (or `if Record.IsEmpty() then ...` for the negative). Apply filters via `SetRange`/`SetFilter` before the call so the existence check runs against the intended subset. Reserve `Count` for cases where the actual number matters and `FindFirst` for cases where the record fields are read.
>
> See sample: `use-isempty-for-existence-check.good.al`.
>
> ## Anti Pattern
> `if Customer.Count() > 0 then ...` and `if Customer.FindFirst() then ...` (when the record is discarded) — both are flagged by the upstream guidance as the wrong tool. The first asks the database for the full count; the second asks for a row's fields. Both answers go unused.
>
> See sample: `use-isempty-for-existence-check.bad.al`.

---

#### 4.5.4 `microsoft/knowledge/security/secrettext-for-credentials.md`

```yaml
---
bc-version: [all]
domain: security
keywords: [secrettext, credentials, api-key, token, debugger, unwrap]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> # Use SecretText for credentials, API keys, and tokens
>
> ## Description
> `SecretText` is the AL data type for values that should never appear in a debugger session, in a log, or in a variable watch. The compiler enforces two guarantees: a string literal cannot be assigned directly to a `SecretText` variable, and a `SecretText` cannot be assigned back to a `Text` or `Code` without an explicit `Unwrap` call. Together these prevent the two common accidents — embedding a secret in source code, and quietly converting a secret to plain text where the debugger can read it. Use `SecretText` for parameters, return values, and local variables that carry API keys, tokens, passwords, connection strings, or any other value an attacker with debugger access should not see.
>
> ## Best Practice
> Declare credential-carrying parameters and variables as `SecretText` from the call site that retrieves the secret all the way to the call site that consumes it (typically an `HttpClient` header or URI). Never round-trip through `Text` — every conversion is a potential exposure point. Retrieve secrets from `IsolatedStorage` with the `SecretText` overload of `Get` rather than the `Text` overload. See sample: `secrettext-for-credentials.good.al`.
>
> ## Anti Pattern
> Holding a credential in a `Text` variable (`BearerToken: Text`), concatenating it into a header, then passing it to `HttpClient`. The token is visible in the debugger and in any error that prints the variable, and the compiler offers no help because the type was wrong from the start. Reviewers should flag any local or parameter named like a secret (`ApiKey`, `Token`, `Password`, `ClientSecret`) whose type is `Text` or `Code`. See sample: `secrettext-for-credentials.bad.al`.

`secrettext-for-credentials.bad.al`:

```al
codeunit 50208 "Sec Sample SecretText Bad"
{
    procedure CallExternalApi()
    var
        ApiKey: Text;
        BearerToken: Text;
        HttpClient: HttpClient;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
    begin
        ApiKey := GetApiKey();
        BearerToken := GetAccessToken();
        Headers := HttpClient.DefaultRequestHeaders();
        Headers.Add('Authorization', 'Bearer ' + BearerToken);
        Headers.Add('X-Api-Key', ApiKey);
        HttpClient.Get('https://api.example.com/data', Response);
    end;

    local procedure GetApiKey(): Text begin end;
    local procedure GetAccessToken(): Text begin end;
}
```

---

#### 4.5.5 `microsoft/knowledge/security/integrationevent-var-parameter-bypasses-security-guards.md`

```yaml
---
bc-version: [all]
domain: security
keywords: [integrationevent, var, guard, ishandled, bypass, security-check]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> # Do not expose security guards as `var` parameters on IntegrationEvent
>
> ## Description
> A `var` parameter on an `[IntegrationEvent]` is a mutable hook: any subscriber can overwrite the value and the publisher will see the new value when control returns. That is the right shape for "let an extension contribute to a payload"; it is the wrong shape for "let an extension confirm a security decision". A `var HasAccess: Boolean` or `var SkipValidation: Boolean` lets any subscriber on the tenant flip the result of the publisher's permission check to `true` (or set "skip" to `true`) before the publisher reads it. The publisher's check becomes advisory, which is the same as not having a check.
>
> ## Best Practice
> Keep the security decision inside the publisher, where it is not bypassable. Fire an `OnAfter*` informational event after the check completes, with the result passed by value (not `var`) so subscribers can react — log, audit, surface a warning — but cannot rewrite the outcome. When subscribers legitimately need to add their own checks, expose an `OnAfterCheckPermissions(...)` that can only tighten access (e.g., a subscriber can `Error()`), never loosen it. See sample: `integrationevent-var-parameter-bypasses-security-guards.good.al`.
>
> ## Anti Pattern
> `OnBeforeCheckPermissions(var HasAccess: Boolean; var SkipValidation: Boolean; TableNo: Integer)`, followed in the caller by `if SkipValidation then exit;`. Any subscriber sets `SkipValidation := true` and the check is gone. Reviewers should flag any `IntegrationEvent` whose signature contains a `var Boolean` whose name reads like a security decision (`HasAccess`, `IsAllowed`, `SkipValidation`, `BypassCheck`, `IsAuthorized`). See sample: `integrationevent-var-parameter-bypasses-security-guards.bad.al`.

---

#### 4.5.6 `microsoft/knowledge/privacy/no-pii-in-telemetry-message-string.md`

```yaml
---
bc-version: [all]
domain: privacy
keywords: [telemetry, session-logmessage, strsubstno, pii, customer-data, employee-code, filename]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> # Do not embed customer data in the telemetry message text
>
> ## Description
> `Session.LogMessage`'s message argument is a plain `Text`. Unlike `Error()`, the platform does not inspect this string field-by-field — whatever is in the text is what telemetry receives. So a call that builds the message via `StrSubstNo` from customer-bearing fields ships those values to telemetry verbatim, regardless of the `DataClassification` argument on the same call. Flagged content includes customer names, email addresses, phone numbers, addresses, employee codes or IDs, attachment filenames, user-provided text that may carry PII, and dumps of `Record` content.
>
> ## Best Practice
> Keep the telemetry message a static, non-personal string ("Customer record processed", "Error processing uploaded file"). When structured context is genuinely needed, attach it through custom dimensions, where individual values can be reviewed and classified at the dimension level rather than baked into a free-text message.
> See sample: `no-pii-in-telemetry-message-string.good.al`.
>
> ## Anti Pattern
> `Session.LogMessage('0000', StrSubstNo('Processed %1', Customer.Name), ...)` — the customer name is in telemetry the moment the line runs. Detection signal: a `StrSubstNo` whose result is the second argument of `Session.LogMessage`. The same shape with `FileName`, `EmployeeCode`, or any record field is the same problem.
> See sample: `no-pii-in-telemetry-message-string.bad.al`.

---

#### 4.5.7 `microsoft/knowledge/privacy/data-classification-is-table-field-property.md`

```yaml
---
bc-version: [all]
domain: privacy
keywords: [data-classification, page-field, table-field, api-page, card-page, list-page]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> # DataClassification is a table-field property, not a page-field property
>
> ## Description
> `DataClassification` is defined on table fields. Pages — including `Card`, `List`, `API`, and `ListPart` — do not own a classification; they simply expose fields whose classification is inherited from the underlying table. A page-level `DataClassification` property does not exist, so neither a missing nor a "wrong" classification can be reported against a page. When the underlying table field is misclassified, the fix is on the table definition, not on every page that surfaces the field.
>
> ## Best Practice
> When reviewing a page that exposes a field believed to be under-classified, follow the field back to its source table and inspect (or correct) the `DataClassification` there. A single corrected table field propagates to every page, report and API that uses it.
>
> ## Anti Pattern
> Flagging a page (or trying to add a `DataClassification` property to a page field) because the page displays personal data. Pages display data that authenticated, permissioned users are already entitled to see; the classification belongs on the table field that stores the data, not on the UI that renders it.

(Note: this is one of several **"anti-false-positive"** articles whose purpose is to *prevent* LLM reviewers from flagging a non-issue.)

---

#### 4.5.8 `microsoft/knowledge/style/label-suffix-approved-list.md`

```yaml
---
bc-version: [all]
domain: style
keywords: [label, textconst, suffix, aa0074, codecop, msg, err, qst, lbl, tok]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> # Use approved suffixes on Label and TextConst names (CodeCop AA0074)
>
> ## Description
> CodeCop AA0074 flags `Label` and `TextConst` identifiers that do not end with an approved usage suffix. The suffix signals at the call site how the text is consumed and what translation behaviour it should get. The approved suffixes and their intended usage are: `Msg` for text shown via `Message()`; `Err` for text passed to `Error()`; `Qst` for text used with `Confirm` or `StrMenu`; `Lbl` for captions and tooltips; `Tok` for short tokens such as `'GET'`, `'PUT'`, `'HTTPS'`, GUIDs, or JSON/XML snippets that are not translated (typically with `Locked = true`); and `Txt` for general text including telemetry messages. A `Label` named `Text000` or `CannotDeleteLine` without a suffix violates the rule, regardless of how readable the prose is.
>
> ## Best Practice
> Pick the suffix that matches the call where the label is consumed: `UpdateCompleteMsg` for `Message(...)`, `CustomerNotFoundErr` for `Error(...)`, `DeleteRecordQst` for `Confirm(...)`, `CustomerNameLbl` for tooltips and captions, `GetMethodTok` for locked tokens, `TelemetryDataTxt` for telemetry payloads. Suffix choices between `Tok`, `Lbl`, `Txt`, and `Msg` are judgment calls when the suffix is valid for the usage — what matters is that the suffix is on the approved list and matches the actual call.
>
> See sample: `label-suffix-approved-list.good.al`.
>
> ## Anti Pattern
> A `Label` declared with no suffix (`CannotDeleteLine: Label '…';`), a generic name (`Text000: Label '…';`), or a suffix that contradicts the usage (`WrongSuffixTok: Label 'Customer %1 not found.'` then passed to `Error()`). All three trip AA0074 or its reviewers and obscure the call-site contract.
>
> See sample: `label-suffix-approved-list.bad.al`.

---

#### 4.5.9 `microsoft/knowledge/style/error-passes-parameters-directly-not-strsubstno.md`

```yaml
---
bc-version: [all]
domain: style
keywords: [error, strsubstno, label, parameters, concatenation, aa0231]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> # Pass parameters directly to `Error()`, do not wrap with `StrSubstNo`
>
> ## Description
> `Error()` accepts a format string and a variable number of arguments — `Error(SomeLabelErr, Arg1, Arg2)`. The platform performs the substitution itself, which is the path the translation pipeline understands. Wrapping the same call as `Error(StrSubstNo(SomeLabelErr, Arg1, Arg2))` hides the placeholders from the platform and removes the format-string identity from the call-site, so analyzers cannot match the call to its label and translators lose the link between the formatted message and its template. The corresponding anti-pattern for hardcoded strings — `Error('Customer ' + CustomerNo + ' not found')` — is even worse: it builds an untranslatable, unanalyzable string at runtime.
>
> ## Best Practice
> Declare a `Label` with the `Err` suffix and the appropriate `Comment` for placeholders, then call `Error(YourErr, arg1, arg2)`. The same rule applies to `Message`, `Confirm`, and other UI primitives: format string in, parameters as separate arguments, no `StrSubstNo` wrapper at the call site, no string concatenation. An `Error('')` (empty message) is acceptable when the calling code expects another layer to emit the actual diagnostic.
>
> See sample: `error-passes-parameters-directly-not-strsubstno.good.al`.
>
> ## Anti Pattern
> `Error(StrSubstNo(CustomerNotFoundErr, CustomerNo))` and `Error(CustomerNotFoundErr + ': ' + CustomerNo)` both defeat the translation and analysis machinery. Reviewers should treat `StrSubstNo` appearing as an argument to `Error`, `Message`, `Confirm`, or `StrMenu` as an unconditional signal to rewrite.
>
> See sample: `error-passes-parameters-directly-not-strsubstno.bad.al`.

---

#### 4.5.10 `microsoft/knowledge/upgrade/enum-values-additive-at-end.md`

```yaml
---
bc-version: [all]
domain: upgrade
keywords: [enum, ordinal, additive, append, backward-compatible, breaking-change]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> # Add new enum values only at the end
>
> ## Description
> An AL `enum` is a fixed list of ordinal-named values. Persisted rows reference enum members by ordinal, not by name. The only enum mutation that preserves the meaning of every existing row is **appending a new value at the end** — every previously valid ordinal still maps to the same member. Inserting a new value in the middle, renumbering existing values, or removing a value without obsoletion all shift ordinals: rows written with the old layout silently take on the new member at their saved ordinal.
>
> ## Best Practice
> When adding an enum value, place it after the last existing `value(N; ...)` entry, with an ordinal strictly greater than every existing one. Never renumber existing entries. To retire a value, do not delete it: mark it `ObsoleteState = Pending` (and later `Removed`) with `ObsoleteReason` and `ObsoleteTag` so the ordinal remains taken.
>
> See sample: `enum-values-additive-at-end.good.al`.
>
> ## Anti Pattern
> Inserting a value between existing entries ("just put `NewMiddleValue` between `First` and `Second`"), or removing a value from the enum without first going through `ObsoleteState = Pending` → `Removed`. Every row whose persisted ordinal matched the removed or shifted value now reads as a different member.
>
> See sample: `enum-values-additive-at-end.bad.al`.
>
> ## See also
> - `obsoletion-requires-reason-and-tag.md` — how to retire an enum member correctly.
> - `obsolete-pending-to-removed-staging.md` — the `Pending → Removed` lifecycle.

(Note the use of a *non-normative* `## See also` section as cross-references.)

---

#### 4.5.11 `microsoft/knowledge/upgrade/use-upgrade-tags-not-version-checks.md`

```yaml
---
bc-version: [all]
domain: upgrade
keywords: [upgrade-tag, version-check, dataversion, has-upgrade-tag, set-upgrade-tag, control-flow]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> # Control upgrade execution with upgrade tags, not version checks
>
> ## Description
> Each piece of upgrade logic must run exactly once per company (or database) across the lifetime of an extension. The platform mechanism for that is the `Upgrade Tag` codeunit: a procedure asks `HasUpgradeTag(MyTag())` at entry, performs its work, then calls `SetUpgradeTag(MyTag())` to record completion. Subsequent upgrades on the same tenant see the tag and skip the work. Hand-rolled `if MyApp.DataVersion().Major < N then ...` chains are the wrong tool: they are version-coupled, accumulate stale branches over time, and break when a tenant skips a version.
>
> ## Best Practice
> Every upgrade procedure starts with a `HasUpgradeTag` guard and ends with `SetUpgradeTag` once the work is committed. Each feature gets its own tag string so features can be re-run independently if needed.
>
> See sample: `use-upgrade-tags-not-version-checks.good.al`.
>
> ## Anti Pattern
> Branching on `MyApp.DataVersion().Major > N`, or chains of `< N` / `< M` to decide which upgrade step to run. Such code becomes unmaintainable after a few releases and silently does the wrong thing on tenants that skip versions.
>
> See sample: `use-upgrade-tags-not-version-checks.bad.al`.
>
> ## See also
> - `first-install-dataversion-zero-check.md` — the one situation where reading `DataVersion()` is the right call.
> - `register-upgrade-tags-with-subscribers.md` — how to make a tag known to the platform.

---

#### 4.5.12 `microsoft/knowledge/ui/no-nested-grids.md`

```yaml
---
bc-version: [all]
domain: ui
keywords: [grid, nested-grid, fixed, data-table, accessibility]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> # Nested grids are not supported
>
> ## Description
> A grid nested inside another grid is not a supported pattern in Business Central. Even if an inner grid independently meets the data-table heuristic, the outer grid fails because its groups contain non-field children (the inner grids). The result is broken table semantics for both layers.
> Always flag a nested grid as a violation. The fix is to restructure the page so there is at most one grid in any branch of the layout tree, choosing either a data-table or a layout-table arrangement.
>
> ## Anti Pattern
> Wrapping a working data-table grid inside another grid in an attempt to compose two tabular regions side by side. The outer grid silently degrades to layout-table rendering, the inner grid's headers are no longer associated with the outer structure, and editable fields with `ShowCaption = false` lose their labels.
>
> See sample: `no-nested-grids.bad.al`.

(Note: this is a `Description` + `Anti Pattern` only — Best Practice was omitted because the corrective action is "use the documented data-table arrangement", which is covered by sibling articles. This is a valid shape — only `## Description` is mandatory.)

---

#### 4.5.13 `microsoft/knowledge/testing/transactionmodel-attribute-governs-test-transactions.md`

```yaml
---
bc-version: [all]
domain: testing
keywords: [transactionmodel, attribute, test, autorollback, autocommit, testisolation]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> # Match TransactionModel to the commit behavior of the code under test
>
> ## Description
> `[TransactionModel(...)]` declares how a test method interacts with the database's write transaction. The attribute applies only to methods inside a codeunit with `SubType = Test` and takes one of three values: `AutoRollback`, `AutoCommit`, or `None`. The choice must match the code being exercised — in particular, whether that code calls `Commit()`. Per the platform reference, "if the code that you test includes calls to the COMMIT Method, then set the TransactionModel property on the test method to AutoCommit." Applying `AutoRollback` to a test that drives code which calls `Commit` produces a runtime error on the first Commit, not a meaningful assertion failure — the test does not complete, and the reviewer sees an infrastructure error instead of a business-logic verdict.
>
> ## Best Practice
> Default to `AutoRollback`: it opens a write transaction at the start of the test, runs the test body, and rolls back at the end, leaving the database in its original state. Pick `AutoCommit` only when the code under test genuinely calls `Commit` — posting routines, job-queue handlers, integration flows — and pair that test's codeunit with a `TestIsolation`-enabled test runner so committed changes are reverted at a higher scope. Pick `None` only for read-only tests or tests that drive UI code without writing from the test method itself, for example tests that validate calculation formulas or read-only projections.
>
> See sample: `transactionmodel-attribute-governs-test-transactions.good.al`.
>
> ## Anti Pattern
> Applying `AutoRollback` to every test method without checking whether the tested business logic calls `Commit`. The test throws at the first Commit, leaving no verdict on the behavior it intended to verify; in a CI run this looks like a flake or a setup bug, not a specification mismatch. The mirror-image anti-pattern is defaulting to `AutoCommit` across the suite "to avoid the error" — without a `TestIsolation` runner this permanently dirties the test database between runs and produces order-dependent test outcomes.
>
> See sample: `transactionmodel-attribute-governs-test-transactions.bad.al`.

---

#### 4.5.14 `community/knowledge/performance/use-deleteall-for-filtered-bulk-deletion.md`

(Community layer — note the boilerplate "Contributions welcome" note common to community files.)

```yaml
---
bc-version: [all]
domain: performance
keywords: [deleteall, bulk-delete, sql, ondelete, trigger-bypass]
technologies: [al]
countries: [w1]
application-area: [all]
---
```

> # Use DeleteAll for filtered bulk deletion
>
> > Contributions welcome — open a PR to refine or extend this article.
>
> ## Description
> `DeleteAll` translates to a single SQL `DELETE` with the record variable's current filters applied as the WHERE clause. A loop of `FindSet` + `Delete` instead issues one SQL statement per row. On any dataset larger than a handful of records, the gap is an order of magnitude or more. The tradeoff is that `DeleteAll` bypasses the `OnDelete` table trigger, so the decision hinges on whether that trigger's logic is required for this specific deletion.
>
> ## Best Practice
> After narrowing the record set with `SetRange`/`SetFilter`, use `DeleteAll` whenever the `OnDelete` trigger has no logic that this call depends on — typically the case for housekeeping routines, staging-table cleanup, and deletions already validated upstream. When the trigger IS required, either keep the explicit loop-plus-`Delete` pattern and comment why, or pre-run the trigger logic against a temporary buffer and then `DeleteAll` the primary table.
>
> See sample: `use-deleteall-for-filtered-bulk-deletion.good.al`.
>
> ## Anti Pattern
> Iterating with `FindSet` + `Delete` to clear a filtered set of records that carry no meaningful `OnDelete` logic. Every row pays a full AL round-trip; on a ten-thousand-row cleanup the loop can take minutes where `DeleteAll` takes under a second.
>
> See sample: `use-deleteall-for-filtered-bulk-deletion.bad.al`.

---

## 5. The 6 review sub-skills

`microsoft/skills/review/al-code-review.md` is the canonical super-skill. Its frontmatter lists the 6 sub-skills verbatim:

```yaml
sub-skills:
 - microsoft/skills/review/al-performance-review.md
 - microsoft/skills/review/al-security-review.md
 - microsoft/skills/review/al-privacy-review.md
 - microsoft/skills/review/al-upgrade-review.md
 - microsoft/skills/review/al-style-review.md
 - microsoft/skills/review/al-ui-review.md
```

Each leaf skill follows the same 5-section DO template. The table below captures the **Source path, Relevance dimensions, Worklist signal, and Action behaviour** for each. All six declare `inputs: [pr-diff, file-path]`, `outputs: [findings-report]`, `bc-version: [all]`, `countries: [w1]`, `application-area: [all]`. `al-ui-review` is the only one to declare `technologies: [al, javascript]`; the other five are AL-only.

### 5.1 `al-performance-review`
- **Source.** All knowledge files under `*/knowledge/performance/**/*.md`, across every enabled layer.
- **Relevance.** Match `bc-version` (PR's `app.json` or orchestrator), `technologies: [al]`, `countries` from `app.json` (else `unknown`), `application-area` = union of areas declared by changed objects (do not substitute `[all]`).
- **Worklist signal tokens** (verbatim list): `SetRange`, `SetFilter`, `SetLoadFields`, `SetCurrentKey`, `FindSet`, `ReadIsolation`, `LockTable`, `ModifyAll`, `DeleteAll`, `TextBuilder`, `Dictionary`, `temporary`, `repeat`, `until`, `CalcFields`, `CalcSums`. Plus weighting toward changed objects "performing record iteration" — tables, pages with SourceTable bindings, reports, queries, codeunits performing record iteration.
- **Action.** Match Best Practice/Anti Pattern sections. `blocker` only when the knowledge file states a platform-level guarantee (documented query timeouts or transaction size limits); otherwise ceiling is `major`. `minor` for contradicting Best Practice without being a full anti-pattern. `info` for clearly-applicable-but-no-violation cases. Confidence: `high` for unambiguous identifier/syntax/object-type matches, `medium` for heuristics or `unknown` dimensions, `low` for applicability-only advisories.

### 5.2 `al-security-review`
- **Source.** All knowledge files under `*/knowledge/security/**/*.md`, across every enabled layer.
- **Relevance.** Same dimensions and rules as performance.
- **Worklist signal tokens** (verbatim list): `IsolatedStorage`, `SetEncrypted`, `OAuth2`, `SecretText`, `Unwrap`, `NonDebuggable`, `Password`, `Token`, `HttpClient`, `Uri`, `AreURIsHaveSameHost`, `IsValidURIPattern`, `RecordRef`, `RecordId`, `Open`, `IntegrationEvent`, `SkipValidation`, `HasAccess`, `Permission`, `UserSecurityId`, `Commit`. Weighted toward permission sets, codeunits handling authentication/authorization, IsolatedStorage, OAuth2 flows, web service endpoints, API pages, event publishers, RecordRef helpers.
- **Action.** Same severity rules. `blocker` only when the knowledge file documents a "platform-level guarantee (for example, documented secret-handling rules, permission-model invariants, or data-protection requirements)."

### 5.3 `al-privacy-review`
- **Source.** All knowledge files under `*/knowledge/privacy/**/*.md`, across every enabled layer.
- **Relevance.** Same as above.
- **Worklist signal tokens** (verbatim list): `DataClassification`, `CustomerContent`, `EndUserIdentifiableInformation`, `EndUserPseudonymousIdentifiers`, `SystemMetadata`, `ToBeClassified`, `PrivacyNotice`, `GetLastErrorText`, `TelemetryScope`, `FeatureTelemetry`, `CustomDimensions`, `LogUsage`, `LogUptake`, `LogError`, `HybridSL`, `HybridGP`, `HybridBC`. **Excludes test codeunits, test libraries, test helper code, files under test/Test/Tests paths, and objects with `Subtype = Test`** — "test data is synthetic and does not ship to customers." Weighted toward tables/tableextensions, codeunits calling `Error`, `Session.LogMessage`, `FeatureTelemetry`, outgoing HTTP requests, migration codeunits, IsolatedStorage I/O.
- **Action.** `blocker` only for "documented telemetry-classification rules or GDPR-adjacent data-handling requirements."

### 5.4 `al-upgrade-review`
- **Source.** All knowledge files under `*/knowledge/upgrade/**/*.md`, across every enabled layer.
- **Relevance.** Same as above.
- **Worklist** is narrower by design: the skill returns `not-applicable` "when the diff touches no upgrade, install, schema, or enum surface."
- **Worklist signal tokens** (verbatim list): `Subtype = Upgrade`, `Upgrade Tag`, `HasUpgradeTag`, `SetUpgradeTag`, `OnValidateUpgrade`, `DataTransfer`, `CopyFields`, `InitValue`, `ObsoleteState`, `ObsoleteReason`, `ObsoleteTag`, `DataVersion`, `ExecutionContext`, `PrimaryKey`, `key(`, `field(`, `value(`, `enum`, `enumextension`, `HybridSL`, `HybridGP`, `HybridBC`, `HybridBaseDeployment`. Weighted toward codeunits with `Subtype = Upgrade` / `Install`, tables and tableextensions adding/changing fields, enums and enumextensions, `Hybrid*`/`Migration`/`Upgrade` namespaces, the `OnUpgradePerCompany`, `OnUpgradePerDatabase`, `OnValidateUpgradePerCompany`, `OnValidateUpgradePerDatabase`, `OnInstallAppPerCompany` triggers, and the `OnGetPerCompanyUpgradeTags`/`OnGetPerDatabaseUpgradeTags` subscribers.
- **Action.** `blocker` is broader here: "irreversible data corruption (enum-ordinal shift, unguarded reads that abort the upgrade) and for changes that would ship to customers without a migration path (new InitValue on an existing table without upgrade code)."

### 5.5 `al-style-review`
- **Source.** All knowledge files under `*/knowledge/style/**/*.md`, across every enabled layer.
- **Relevance.** Same as above.
- **Worklist signal tokens** (verbatim list): `Label`, `TextConst`, `Locked`, `Comment`, `MaxLength`, `temporary`, `OptionMembers`, `OptionCaption`, `APIPublisher`, `APIGroup`, `APIVersion`, `EntityName`, `EntitySetName`, `DelayedInsert`, `FieldCaption`, `TableCaption`, `FieldName`, `TableName`, `Page.RunModal`, `Report.Run`, `this.`, `StrSubstNo`. Weighted toward API pages (`PageType = API`), tables/pages declaring `Label`/`TextConst`, codeunits issuing `Error`/`Message`/`Confirm`, and files violating the `<Object>.<Type>.al` convention.
- **Action.** "Style findings rarely reach `blocker` — reserve it for cases where the knowledge file documents a platform-level requirement (for example, API page property constraints the OData runtime rejects). Most style findings are `minor` or `info`; egregious misuse (`Error` with pre-built Text losing translation and telemetry classification) may reach `major`." The skill explicitly says "Use together with a formal analyzer; this skill adds BCQuality's remedial-knowledge explanations of why each rule exists."

### 5.6 `al-ui-review`
- **Source.** All knowledge files under `*/knowledge/ui/**/*.md`, across every enabled layer.
- **Relevance.** Same dimensions; `technologies: [al] or [javascript]` (it's the only review skill that processes JS — control add-ins).
- **Worklist** has an explicit **UI-file filter**: applies to files declaring `page`, `pageextension`, `pagecustomization`, and to "control add-in JavaScript/CSS/HTML that changes rendered UI. When the diff contains no such files, return `outcome: 'not-applicable'` without evaluating knowledge files."
- **Worklist signal tokens** (verbatim list): `Caption`, `ToolTip`, `AboutTitle`, `AboutText`, `PageType`, `ShowCaption`, `InstructionalText`, `grid`, `fixed`, `GridLayout`, `Style`, `StyleExpr`, `Favorable`, `Unfavorable`, `Ambiguous`, `cuegroup`, `controladdin`, `usercontrol`, `aria-`, `tabindex`, `keydown`, `focus`, `innerHTML`, `createElement`, `&`, `Specifies`, `Message(`, `Confirm(`, `Error(` in a page context, `Disabled`, `Invalid`, `Whitelist`, `Blacklist`, trailing punctuation patterns on captions.
- **Action.** "UI text findings are generally `minor` — they affect localization and polish rather than correctness. Accessibility findings for missing labels, broken grid semantics, semantic color without text meaning, or UI-rendering control add-in changes can be `major`."

### 5.7 `al-code-review` (the super-skill that composes the above)

Two things distinguish the super-skill from the leaves:

1. **It must NOT filter sub-skills by task content.** Quoted from the skill itself: "Per the DO contract, the super-skill MUST NOT filter sub-skills by task content. `al-code-review` does not inspect the PR diff to predict whether, for example, there is anything for `al-security-review` to find. Each leaf is responsible for its own task-level applicability decision; leaves signal non-applicability by returning `outcome: 'not-applicable'` or `outcome: 'no-knowledge'`."
2. **It performs an "agent self-review pass" after sub-skill rollup.** Quoted from the skill: "After the sub-skill rollup, perform a self-review pass against the same task input using the agent's built-in BC and AL knowledge. BCQuality is an **additive** knowledge layer: it augments the agent's review judgement, it does not replace it. The goal of this pass is to surface defects the agent recognises on its own — bugs, anti-patterns, error-handling gaps, AL idioms — that the leaf sub-skills did not catch because no BCQuality knowledge file covers them yet." For every agent candidate it validates against the loaded BCQuality knowledge: matching file → upgrade to knowledge-backed; contradicting file → suppress; no match → emit as `from-sub-skill: "agent"` with `references: []`, `id: agent:<slug>`, `confidence ≤ medium`.

Output (verbatim populated example):

```json
{
  "skill": { "id": "al-code-review", "version": 1 },
  "outcome": "completed",
  "summary": {
    "counts": { "blocker": 1, "major": 1, "minor": 3, "info": 0 },
    "coverage": { "worklist-size": 4, "items-evaluated": 4 }
  },
  "findings": [
    {
      "id": "microsoft/knowledge/performance/filter-before-find.md",
      "severity": "major",
      "message": "FindSet is called on a record variable without any prior SetRange/SetFilter. This forces a full-table scan.",
      "location": {
        "file": "src/Sales/PostingRoutines.Codeunit.al",
        "line": 140,
        "range": { "start-line": 140, "end-line": 144 }
      },
      "references": [
        { "path": "microsoft/knowledge/performance/filter-before-find.md" }
      ],
      "confidence": "high",
      "from-sub-skill": "al-performance-review"
    },
    ...
    {
      "id": "agent:missing-error-handling-on-http-client",
      "severity": "minor",
      "message": "HttpClient.Send is called without inspecting the response status or wrapping the call in a TryFunction. Network or remote-server failures will surface as runtime errors to the user. Recommendation: branch on the HttpResponseMessage.IsSuccessStatusCode and either retry, surface a controlled error, or fall back, depending on the integration's contract.",
      "location": { "file": "src/Integration/ApiClient.Codeunit.al", "line": 60, "range": { "start-line": 60, "end-line": 64 } },
      "references": [],
      "confidence": "medium",
      "from-sub-skill": "agent"
    }
  ],
  "suppressed": [],
  "sub-results": [ /* full nested findings-report per invoked sub-skill */ ]
}
```

Empty-corpus rollup (verbatim):

```json
{
  "skill": { "id": "al-code-review", "version": 1 },
  "outcome": "no-knowledge",
  "summary": {
    "counts": { "blocker": 0, "major": 0, "minor": 0, "info": 0 },
    "coverage": { "worklist-size": 0, "items-evaluated": 0 }
  },
  "findings": [],
  "suppressed": [],
  "sub-results": [
    { "skill": { "id": "al-performance-review", "version": 1 }, "outcome": "no-knowledge", "summary": { "counts": { "blocker": 0, "major": 0, "minor": 0, "info": 0 }, "coverage": { "worklist-size": 0, "items-evaluated": 0 } }, "findings": [], "suppressed": [] },
    ...
  ]
}
```

---

## 6. The "remedial knowledge" list — concrete BC mistakes the KB exists to fix

Across the 154 articles, you can group the remedial knowledge into clear categories. The list below is curated from the actual files I read and from the keyword inventories of each review skill. Every entry is a *concrete* mistake an LLM is known to make on AL code and that the KB explicitly addresses. **This is the most directly useful list for a Cursor plugin: it doubles as a checklist of things your plugin should look for.**

### Performance (LLM gets data-access shapes wrong)
1. **`SetLoadFields` must come BEFORE `SetRange`/`Get`/`FindSet`** — ordering rule the model misses. Article: `use-setloadfields-for-partial-records.md`.
2. **`FindSet(true)` *is* an UpdLock**; never use the obsolete 2-parameter form `FindSet(ForUpdate, UpdateKey)`. Article: `findset-true-applies-updlock-on-read.md`.
3. **Use `IsEmpty`, not `Count > 0` or `FindFirst` for existence checks.** Article: `use-isempty-for-existence-check.md`.
4. **Use `Get` over `FindFirst` when the full primary key is known.** Article: `use-get-instead-of-findfirst-on-full-primary-key.md`.
5. **Pair `FindSet` with `repeat..Next`; never pair `FindFirst`/`FindLast`/`Get` with `Next`.** (CodeCop AA0181, AA0233.) Article: `pair-findset-with-next-loop.md`.
6. **`SetRange`/`SetFilter` ahead of `FindSet`, not as an `if` inside the loop.** Article: `apply-filters-before-iterating.md`.
7. **`ModifyAll`/`DeleteAll` instead of per-row `Modify`/`Delete`** — single SQL statement, but be aware of trigger-and-media-field regressions. Articles: `prefer-modifyall-over-per-row-modify.md`, `triggers-and-media-field-regress-modifyall.md`.
8. **`CalcSums` instead of `CalcFields` inside a loop.** Article: `calcsums-instead-of-calcfields-in-loop.md`.
9. **Pick a key matching your filters with `SetCurrentKey`.** Article: `setcurrentkey-aligns-key-with-filters.md`.
10. **Avoid `RecordRef`/`FieldRef` in hot loops (10k+) when a typed record fits** — but accept them for generic metadata iteration. Article: `avoid-recordref-in-hot-loop.md`.
11. **No `Commit` inside loops** — use Codeunit.Run-based atomic sub-operations or bounded checkpoints. Articles: `avoid-commit-inside-loops.md`, `codeunit-run-as-atomic-sub-operation.md`.
12. **`Codeunit.Run` requires a prior `Commit` if the caller already holds a write transaction.** The atomic-sub-operation pattern needs a read-only outer scope. `[CommitBehavior]` does not silence the implicit commit; `[TryFunction]` is not a substitute. Article: `codeunit-run-requires-prior-commit-inside-transaction.md`.
13. **`MaintainSQLIndex = false` on a key disables SIFT for FlowFields that depend on it.** Article: `maintainsqlindex-false-breaks-flowfield-sift.md`.
14. **Temporary tables are in-memory — access-pattern rules do not apply.** *(Anti-false-positive.)* Article: `temporary-tables-have-no-database-cost.md`.
15. **Singleton setup tables need no access optimization.** *(Anti-false-positive.)* Article: `singleton-setup-tables-need-no-access-optimization.md`.
16. **Admin/migration/wizard pages tolerate lower-severity findings.** *(Severity-shaping context.)* Article: `admin-and-migration-pages-tolerate-lower-perf.md`.
17. **`do-not-locktable-in-read-only-procedure.md`** — `LockTable` on a read path is a deadlock risk.
18. **`prefer-readisolation-over-locktable-for-reads.md`** — modern replacement for the C/AL `LockTable` idiom.
19. **`avoid-redundant-get-when-record-already-loaded.md`** — re-loading the same row.
20. **`avoid-get-inside-loop-on-large-table.md`** — N+1 anti-pattern.
21. **`apply-guards-before-get.md`** — cheap guards before the DB hit.
22. **`avoid-user-prompts-inside-transactions.md`** — Confirm inside a write tx is a hold-time bomb.
23. **`flowfield-source-key-needs-sumindexfields.md`** — FlowField without SumIndexFields tables-scans.
24. **`pass-false-to-insert-when-trigger-not-needed.md`** — skip OnInsert when safe.
25. **`prefer-dictionary-over-temporary-table-for-lookups.md`** — Dictionary is faster for in-memory key→value.
26. **`use-textbuilder-for-string-concatenation-in-loops.md`** — Text concatenation is O(n²); TextBuilder isn't.
27. **`addloadfields-in-report-onpredataitem.md`** — report-dataitem flavor of SetLoadFields.
28. **`do-not-remove-sourcetabletemporary-from-api-page.md`** — removing the property is a breaking change.
29. **`do-not-modify-in-onaftergetrecord.md`** — page-trigger trap.
30. **`guard-event-subscribers-before-db-call.md`** — early-return subscribers when irrelevant.
31. **`understand-implicit-transaction-boundary.md`** — AL auto-commits on success; explicit Commit is rarely needed.
32. **`use-tryfunction-for-error-catching-not-rollback.md`** — TryFunction catches but does not open its own rollback boundary.
33. **`production-scale-tables-warrant-extra-analysis.md`** — meta-rule on triage.

### Security (LLM gets BC-specific primitives wrong)
1. **`SecretText`, not `Text`, for credentials/tokens/passwords/keys.** Article: `secrettext-for-credentials.md`.
2. **`SecretText` with `HttpClient`** — use `SecretText` overloads end-to-end. `secrettext-with-httpclient.md`.
3. **`SecretStrSubstNo` for composing secrets** — never plain `StrSubstNo`. `secretstrsubstno-for-composing-secrets.md`.
4. **`[NonDebuggable]` required when unwrapping `SecretText`.** `nondebuggable-required-when-unwrapping-secrettext.md`.
5. **IntegrationEvent must not expose secrets** — payloads are broadcast to all subscribers. `integrationevent-must-not-expose-secrets.md`.
6. **`var` parameters on IntegrationEvent bypass security guards.** Flag any `var <name>: Boolean` whose name reads like a security decision (`HasAccess`, `IsAllowed`, `SkipValidation`, `BypassCheck`, `IsAuthorized`). `integrationevent-var-parameter-bypasses-security-guards.md`.
7. **`IsolatedStorage` access must be `local` or `internal`** — `isolatedstorage-access-must-be-local-or-internal.md`.
8. **Choose `IsolatedStorage.DataScope::Module` vs `Company` deliberately.** `isolatedstorage-datascope-module-vs-company.md`.
9. **`IsolatedStorage.SetEncrypted` for sensitive values.** `isolatedstorage-setencrypted-for-sensitive-values.md`.
10. **`[CommitBehavior]` attribute scopes explicit commits.** `commitbehavior-attribute-scopes-explicit-commits.md`.
11. **`RecordRef.Open` with caller table must not be public** — back door around permissions. `recordref-open-with-caller-table-must-not-be-public.md`.
12. **`InherentPermissions`/`InherentEntitlements` minimal grant** — `'r'` not `'RIMD'`, Essential not Premium. `inherent-permissions-minimal-grant.md`.
13. **Indirect permissions for elevated access** — `indirect-permissions-for-elevated-access.md`.
14. **No wildcard permission grants.** `permission-set-avoid-wildcard-grants.md`.
15. **`Validate URL` patterns on user-input URLs** — `validate-user-configurable-urls.md`.
16. **`ValidateTableRelation = false` on user input is a SQL-injection-class risk.** `validatetablerelation-false-on-user-input.md`.
17. **AL has no built-in `HtmlEncode`** — `al-has-no-built-in-htmlencode.md`.
18. **`GetLastErrorText` storage is a privacy concern, not a security one.** *(Categorization.)* `getlasterrortext-storage-is-privacy-not-security.md`.

### Privacy / GDPR / Telemetry (very BC-specific classification model)
1. **`DataClassification` is required on PII table fields**, default `SystemMetadata` is a footgun. `data-classification-required-on-pii-fields.md`.
2. **`DataClassification` is a TABLE-FIELD property, not a page property.** *(Anti-false-positive.)* `data-classification-is-table-field-property.md`.
3. **In-memory dictionaries/lists/temp tables are NOT a privacy concern.** *(Anti-false-positive.)* `in-memory-data-not-a-privacy-concern.md`.
4. **Page display is not a privacy concern.** *(Anti-false-positive.)* `page-display-is-not-a-privacy-concern.md`.
5. **Table-level `DataClassification` cascades to fields** — `table-level-data-classification-cascades.md`.
6. **Resolve `ToBeClassified` before release.** `resolve-tobeclassified-before-release.md`.
7. **`FlowField`/`FlowFilter` classification is `SystemMetadata`** — `flowfield-flowfilter-classification-systemmetadata.md`.
8. **Do NOT embed customer data in `Session.LogMessage` message text** — telemetry can't reclassify a free-text string. `no-pii-in-telemetry-message-string.md`.
9. **`Session.LogMessage` requires explicit `DataClassification`** — `session-logmessage-requires-dataclassification.md`.
10. **`FeatureTelemetry.CustomDimensions` follows the same rule** — no PII in dimension values. `featuretelemetry-customdimensions-no-pii.md`.
11. **Do NOT pre-build error text with `StrSubstNo` before `Error()`** — the platform loses ability to classify/strip PII. `avoid-strsubstno-prebuild-before-error.md`.
12. **`Error()` direct substitution is safe for telemetry** — `error-direct-substitution-safe-for-telemetry.md`.
13. **`Error` vs `Message` telemetry-logging differ.** `error-vs-message-telemetry-logging.md`.
14. **`GetLastErrorText` is customer content** — never wrap it in `StrSubstNo`. `getlasterrortext-customer-content-in-errors.md`.
15. **Migration destination classification rules** — `migration-destination-classification.md`.
16. **Privacy notice consent required for external data transfer** — `privacy-notice-consent-for-external-data-transfer.md`.
17. **Register integration in Privacy Notice Registrations** — `register-integration-in-privacy-notice-registrations.md`.

### Style (CodeCop-grade, AppSource technical-validation–grade)
1. **CodeCop AA0074: approved Label/TextConst suffixes** — `Msg/Err/Qst/Lbl/Tok/Txt`. `label-suffix-approved-list.md`.
2. **CodeCop AA0218: every page field needs a non-empty `ToolTip`** — AppSource tech-val rejects pages without them. `tooltip-required-on-page-fields.md`.
3. **CodeCop AA0241: reserved keywords lowercase.** `lowercase-reserved-keywords.md`.
4. **CodeCop AA0248: use `this.` in codeunits.** `this-keyword-in-codeunits.md`.
5. **Use `FieldCaption`/`TableCaption` (NOT `FieldName`/`TableName`) in user-facing text.** `fieldcaption-not-fieldname-in-user-messages.md`.
6. **Pass parameters directly to `Error()`** — never wrap with `StrSubstNo` (breaks translation and telemetry). `error-passes-parameters-directly-not-strsubstno.md`.
7. **API pages use camelCase, alphanumeric-only properties.** `api-page-camelcase-properties.md`.
8. **API page `DelayedInsert = true`** — `api-page-delayedinsert-true.md`.
9. **API page version format** — `api-page-version-format.md`.
10. **API page entity singular vs set plural** — `api-page-entity-naming-singular-plural.md`.
11. **Object name 30-character limit.** `object-name-30-char-limit.md`.
12. **Page name must match SourceTable.** `page-name-must-match-source-table.md`.
13. **File name pattern `<Object>.<Type>.al`.** `file-name-object-type-pattern.md`.
14. **Call objects by name, not numeric ID.** `named-invocations-not-object-ids.md`.
15. **Temporary variables get `Temp` prefix.** `temporary-variable-temp-prefix.md`.
16. **Variable declaration order by type.** `variable-declaration-order-by-type.md`.
17. **Variable names must not shadow.** `variable-name-must-not-shadow.md`.
18. **Caption required on page fields.** `caption-required-on-page-fields.md`.
19. **Tooltip starts with `'Specifies'`** (referenced from the al-ui-review example).
20. **`AboutTitle`/`AboutText` teaching tips.** `abouttitle-abouttext-teaching-tips.md`.
21. **`OptionCaption` required and matches member count.** `optioncaption-required-and-matches-membercount.md`.
22. **Label `Locked` for non-translatable.** `label-locked-for-non-translatable.md`.
23. **Label `Comment` explains placeholders.** `label-comment-explains-placeholders.md`.
24. **Event subscriber param names match publisher.** `event-subscriber-param-names-match-publisher.md`.
25. **Single space around binary operators / after `not`.** `single-space-around-binary-operators.md`, `single-space-after-not-operator.md`.
26. **No space before method parenthesis.** `no-space-before-method-parenthesis.md`.
27. **Function-call parentheses required.** `function-call-parentheses-required.md`.
28. **No `begin/end` around single statement.** `no-begin-end-around-single-statement.md`.
29. **`begin` on same line as `then`/`else`/`do`.** `begin-on-same-line-as-then-else-do.md`.
30. **Block keywords start a new line.** `block-keywords-start-new-line.md`.
31. **No `else` after terminating statement.** `no-else-after-terminating-statement.md`.
32. **`case` action on line after possibility.** `case-action-on-line-after-possibility.md`.
33. **XmlDoc for public library procedures.** `xmldoc-for-public-library-procedures.md`.

### UI / Accessibility (very BC-platform-specific)
1. **`ShowCaption = false` is almost always an accessibility bug on editable fields.** `show-caption-on-editable-fields.md`.
2. **Group-labeled first-child exception** — three exact conditions. `group-labeled-first-child-exception.md`.
3. **`ShowCaption` allowed on non-editable fields.** `show-caption-false-allowed-on-non-editable-fields.md`.
4. **`ShowCaption` in PromptDialog prompt area allowed.** `show-caption-in-promptdialog-prompt-area.md`.
5. **`ShowCaption` in repeater allowed.** `show-caption-in-repeater-allowed.md`.
6. **`Group ShowCaption = false` outside a grid is NOT a violation.** *(Anti-false-positive.)* `group-show-caption-false-outside-grid-is-not-a-violation.md`.
7. **Group caption quality is NOT an accessibility issue.** *(Anti-false-positive.)* `group-caption-quality-is-not-an-accessibility-issue.md`.
8. **Nested grids are not supported.** `no-nested-grids.md`.
9. **Tabular intent requires data-table conditions.** `tabular-intent-requires-data-table-conditions.md`.
10. **Layout table with captions is valid.** `layout-table-with-captions-is-valid.md`.
11. **Standalone content in layout table.** `standalone-content-in-layout-table.md`.
12. **Grid data-table heuristic** — the underlying classification rule. `grid-data-table-heuristic.md`.
13. **Semantic styles need independent textual meaning** — color-only isn't accessible. `semantic-styles-need-independent-textual-meaning.md`.
14. **Cosmetic styles need NO textual context.** `cosmetic-styles-need-no-textual-context.md`.
15. **Semantic style in CueGroup exception.** `semantic-style-in-cuegroup-exception.md`.
16. **`StyleExpr` text vs boolean.** `style-expr-text-vs-boolean.md`.
17. **`OnDrillDown` on non-editable fields renders as link.** `on-drill-down-on-non-editable-fields-renders-as-link.md`.
18. **Control add-in accessibility is the developer's responsibility** — no AL-platform safety net. `control-add-in-accessibility-is-developer-responsibility.md`.
19. **Control add-in has no BC color tokens.** `control-add-in-has-no-bc-color-tokens.md`.

### Upgrade / Migration / Schema (the most dangerous category)
1. **Enum values are additive at the end — NEVER renumber, insert, or delete.** `enum-values-additive-at-end.md`. **Blocker-severity.**
2. **Obsoletion requires `ObsoleteState` + `ObsoleteReason` + `ObsoleteTag`** (typically the release version). `obsoletion-requires-reason-and-tag.md`.
3. **Obsolete-pending → removed staging.** `obsolete-pending-to-removed-staging.md`.
4. **Control upgrade execution with **Upgrade Tags**, not `DataVersion` checks.** `use-upgrade-tags-not-version-checks.md`.
5. **First-install `DataVersion = 0` check** — the one place reading `DataVersion()` is correct. `first-install-dataversion-zero-check.md`.
6. **Register upgrade tags with subscribers.** `register-upgrade-tags-with-subscribers.md`.
7. **`InitValue` does NOT back-fill existing rows** — needs upgrade code. `initvalue-does-not-update-existing-rows.md`.
8. **`DataTransfer` for bulk init** — `datatransfer-for-bulk-init.md`.
9. **`DataTransfer` skips triggers and event subscribers** — the foot-gun for existing fields with `OnValidate`. `datatransfer-skips-triggers-and-subscribers.md`.
10. **No external HTTP/DotNet calls inside upgrade codeunits.** `no-external-calls-in-upgrade.md`.
11. **Do NOT block upgrade on data errors** — quarantine, don't abort. `do-not-block-upgrade-on-data-errors.md`.
12. **Guard database reads inside upgrades.** `guard-database-reads.md`.
13. **Minimize `OnValidate` upgrade triggers.** `minimize-onvalidate-upgrade-triggers.md`.
14. **Upgrade codeunit `Subtype = Upgrade`** — `upgrade-codeunit-subtype.md`.
15. **Triggers call helpers, not implementations.** `triggers-call-helpers-not-implementations.md`.
16. **Skip nonessential work via `ExecutionContext`.** `skip-nonessential-work-via-execution-context.md`.
17. **Primary-key and field-type changes are safe only on tables without existing data.** `breaking-changes-only-on-tables-without-data.md`. **Blocker-severity.**
18. **Hybrid migration codeunits are NOT standard upgrade.** `hybrid-migration-codeunits-not-standard-upgrade.md`.

### Testing
1. **`[TransactionModel(...)]` choice must match whether the code under test calls `Commit()`.** `transactionmodel-attribute-governs-test-transactions.md`.

### Notable design pattern — "anti-false-positive" articles
Several articles exist **specifically to prevent LLM reviewers from flagging non-issues**. These are worth recognizing because most LLM-driven review tools generate noise rather than miss findings:
- `temporary-tables-have-no-database-cost.md`
- `singleton-setup-tables-need-no-access-optimization.md`
- `admin-and-migration-pages-tolerate-lower-perf.md`
- `data-classification-is-table-field-property.md`
- `in-memory-data-not-a-privacy-concern.md`
- `page-display-is-not-a-privacy-concern.md`
- `group-show-caption-false-outside-grid-is-not-a-violation.md`
- `group-caption-quality-is-not-an-accessibility-issue.md`
- `layout-table-with-captions-is-valid.md`

Often these articles omit `## Best Practice` and only include `## Anti Pattern` — where the "anti-pattern" is the *reviewer's* over-flagging. This is the BCQuality team treating *false-positive prevention* as first-class remedial knowledge for agents.

---

## 7. CI / Validation

### 7.1 Workflow

`.github/workflows/validate-frontmatter.yml` (verbatim):

```yaml
name: Validate frontmatter and structure
on:
  pull_request:
    branches: [main]
  push:
    branches: [main]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - name: Check out repository
        uses: actions/checkout@v4
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - name: Install dependencies
        run: pip install pyyaml
      - name: Run validator
        run: python .github/scripts/validate_frontmatter.py --root .
```

### 7.2 The validator (`.github/scripts/validate_frontmatter.py`, 568 lines)

It implements **25 rules** (R01–R25) that operationalize the contracts in READ/DO/WRITE/entry.md. Below is the full catalog distilled from the script's docstring and `report.error(path, "RNN", ...)` call sites.

| Rule | Applies to | Description |
|---|---|---|
| **R01** | all | Frontmatter parses — opening/closing `---`, valid YAML, mapping at top level, UTF-8 file. |
| **R02** | knowledge | Required keys present (`bc-version`, `domain`, `keywords`, `technologies`, `countries`, `application-area`), no extras, no empty values. |
| **R03** | knowledge | `bc-version` is `[all]`, list of positive integers, or single-element range shorthand `[26..28]`. `[all]` is mutually exclusive with explicit versions. Range start ≤ end. |
| **R04** | knowledge | `domain` is a non-empty string. |
| **R05** | knowledge | `keywords` non-empty list of lowercase-kebab-case strings; warns if > 10. |
| **R06** | knowledge | `technologies` non-empty list; `'all'` sentinel is forbidden. |
| **R07** | knowledge | `countries` non-empty list of `w1` OR lowercase ISO alpha-2; `w1` mutually exclusive with codes. |
| **R08** | knowledge | `application-area` non-empty list; `all` mutually exclusive with specific areas. |
| **R09** | knowledge | Contains a `## Description` section. |
| **R10** | knowledge | **No fenced code blocks** in the body — the file errors on the first ` ``` ` found. |
| **R11** | knowledge | File ≤ 100 lines (`MAX_KNOWLEDGE_LINES = 100`). |
| **R12** | knowledge | File-name slug is lowercase kebab-case. |
| **R13** | knowledge | Path shape is exactly `<layer>/knowledge/<domain>/<slug>.md` (4 parts). |
| **R14** | knowledge samples | Sample file name matches `<slug>.<kind>.<ext>` with kebab-case slug; non-`.md` files in a domain folder must reference an existing `<slug>.md`; warns on non-standard kinds (only `good` and `bad` are standard). |
| **R15** | action-skill | Required action-skill keys present (`kind`, `id`, `version`, `title`, `description`, `inputs`, `outputs`); warns on unknown keys outside the allowed optional set (`bc-version`, `technologies`, `countries`, `application-area`, `sub-skills`); no empty values. |
| **R16** | action-skill | `id` lowercase kebab-case; `version` is a positive integer (not bool). |
| **R17** | action-skill | `inputs` non-empty list; warns on non-standard values (standard set: `pr-diff`, `object-list`, `file-path`, `repository`, `telemetry-query`). |
| **R18** | action-skill | `outputs` non-empty list; only `findings-report` is currently allowed. |
| **R19** | action-skill | Optional filter dimensions (`bc-version`, `technologies`, `countries`, `application-area`) validate the same way as knowledge files when present. |
| **R20** | action-skill | `sub-skills` (if present) non-empty list of repo-relative paths ending in `.md`. |
| **R21** | action-skill | Body contains the 5 sections `## Source`, `## Relevance`, `## Worklist`, `## Action`, `## Output`, each exactly once, in that order. |
| **R22** | meta-skill | Required keys present (`kind`, `id`, `version`, `title`); `id` kebab-case; `version` positive int. |
| **R23** | entry-point | Required keys present (`kind`, `id`, `version`, `title`); `id` MUST equal `"entry"`; `version` positive int. |
| **R24** | global | **Skill `id`s are unique within their kind** across the whole repo. |
| **R25** | path/kind | `kind` in frontmatter matches the file's path role: files in `<layer>/skills/` must declare `kind: action-skill`; `/skills/{read,write,do}.md` must declare `kind: meta-skill`; `/skills/entry.md` must declare `kind: entry-point`. |

Output formatting: plain "`<rel>:<line>: [<rule>] <level>: <message>`" locally, or GitHub Actions annotations (`::error file=...,line=...::[Rxx] message`) when `GITHUB_ACTIONS=true`. Exit code 1 on any error, 0 with warnings.

The validator is itself the *operational* spec — anywhere READ/DO/WRITE are ambiguous in prose, the script's rule is the source of truth.

---

## 8. Integration recommendations for a Cursor plugin

The plugin's job is to **map BCQuality's repo-shape contract into Cursor-native primitives** so the user gets the same review behaviour inside the IDE that AL-Go gets in CI. Here is a concrete mapping that respects the contracts.

### 8.1 High-level plugin architecture

```
.cursor/plugins/bcquality/                # Your plugin's repo
├── plugin.json                            # standard Cursor plugin manifest
├── rules/
│   ├── bcquality-overview.mdc             # always-applied: short framing
│   ├── bcquality-read-contract.mdc        # agent-requestable: full READ contract
│   ├── bcquality-do-contract.mdc          # agent-requestable: full DO contract  
│   ├── bcquality-entry-contract.mdc       # agent-requestable: entry routing
│   └── bcquality-write-contract.mdc       # agent-requestable: WRITE authoring
│
├── skills/
│   ├── al-code-review/SKILL.md            # super-skill orchestrator
│   ├── al-performance-review/SKILL.md
│   ├── al-security-review/SKILL.md
│   ├── al-privacy-review/SKILL.md
│   ├── al-upgrade-review/SKILL.md
│   ├── al-style-review/SKILL.md
│   └── al-ui-review/SKILL.md
│
├── commands/                              # / commands in chat
│   ├── bcq-review.md                      # default: dispatch via entry
│   ├── bcq-review-performance.md
│   ├── bcq-review-security.md
│   ├── bcq-write-knowledge.md             # uses WRITE meta-skill
│   └── bcq-update.md                      # refresh local cache
│
├── content/                               # local cache of BCQuality content
│   ├── microsoft/                         # synced from upstream (read-only)
│   ├── community/                         # synced from upstream (read-only)
│   └── custom/                            # user's own overrides (writable)
│       ├── knowledge/<domain>/<slug>.md
│       └── skills/<id>.md
│
├── scripts/
│   ├── sync.sh                            # git sparse-clone or curl tarball
│   └── validate.py                        # vendored copy of upstream validator
│
└── README.md
```

### 8.2 Mapping table

| BCQuality concept | Cursor primitive | Concrete file in your plugin |
|---|---|---|
| `skills/entry.md` (entry-point routing) | A `/bcq-review` slash command + an `al-code-review` skill that reads `task-context` from the chat session | `commands/bcq-review.md` + `skills/al-code-review/SKILL.md` |
| `skills/read.md` (READ meta-skill) | An agent-requestable rule so any agent action picks it up before parsing a knowledge file | `rules/bcquality-read-contract.mdc` |
| `skills/do.md` (DO meta-skill) | An agent-requestable rule that pins the JSON output shape, severity taxonomy, and 4-step pattern | `rules/bcquality-do-contract.mdc` |
| `skills/write.md` (WRITE meta-skill) | An agent-requestable rule used by the `bcq-write-knowledge` command only | `rules/bcquality-write-contract.mdc` |
| `microsoft/skills/review/al-*-review.md` | Six Cursor skills, each pointing at its domain's knowledge files | `skills/al-<domain>-review/SKILL.md` |
| `microsoft/knowledge/<domain>/` (read content) | Bundled or sparse-checkout'd into `content/microsoft/` | `content/microsoft/...` |
| `community/knowledge/<domain>/` | Same — bundled or synced | `content/community/...` |
| `custom/knowledge/<domain>/` | The user's own overrides, stored next to the cache so layer precedence works | `content/custom/...` |
| The JSON `findings-report` output | Surfaced in chat as a structured response and (optionally) as VS Code/Cursor diagnostics by writing to `.cursor/diagnostics/` or by emitting LSP-style problem markers via a hook | n/a — runtime |
| Sample sibling files (`.good.al`, `.bad.al`) | Referenced from skill instructions for the agent's reasoning; optionally surface a "show good/bad example" code action | Read at skill-execution time |
| CI validator (R01–R25) | Run `scripts/validate.py` from a Cursor hook (`onSavePath: content/custom/**`) to prevent invalid custom knowledge from breaking the layer | `scripts/validate.py` + `hooks/validate-custom.json` |

### 8.3 Skill file templates (Cursor format)

Each leaf review skill in your plugin should adapt the upstream DO 4-step pattern into a Cursor `SKILL.md`. Example for the performance leaf:

```markdown
# AL Performance Review

Use when reviewing AL code changes for performance issues — typically in
response to /bcq-review-performance, or as part of /bcq-review when
al-code-review dispatches sub-skills.

## Source
Read every `<plugin>/content/{microsoft,community,custom}/knowledge/performance/*.md`
file. Read each file's frontmatter exactly as described in the READ contract
rule. Discard files whose frontmatter is invalid.

## Relevance
Filter using the frontmatter matching semantics from the READ rule:
- bc-version against the target BC version (read from app.json if present;
  otherwise treat as unknown).
- technologies must intersect [al].
- countries match per [w1]-sentinel rule.
- application-area match per [all]-sentinel rule.
Conditionally-applicable files get confidence ≤ medium and the unknown
dimension must be named in the finding's message.

## Worklist
For each relevant file, score against the changed AL objects and against the
performance token list: SetRange, SetFilter, SetLoadFields, SetCurrentKey,
FindSet, ReadIsolation, LockTable, ModifyAll, DeleteAll, TextBuilder,
Dictionary, temporary, repeat, until, CalcFields, CalcSums.

Then resolve layer precedence: custom > community > microsoft. Suppressed
files go into the output's `suppressed[]` with reason="layer-precedence".

## Action
Per worklist entry, evaluate the diff or file against the file's Best Practice
and Anti Pattern sections. Severity rules:
- blocker only when the file states a platform-level guarantee.
- major for clear anti-pattern matches.
- minor for Best-Practice contradictions that aren't full anti-patterns.
- info when the file is clearly applicable but no violation is detected.

## Output
A single JSON document conforming to the DO output contract. Render the
JSON in chat as a fenced code block AND, for each finding with a
location, attempt to expose it as a Cursor diagnostic for the file.
```

### 8.4 Sync strategy

Two viable shapes:

1. **Vendored snapshot** (simplest, reproducible): bundle `content/microsoft/` and `content/community/` directly in the plugin. Ship a `bcq-update` command that runs `git fetch` against `microsoft/BCQuality` at a pinned commit and refreshes the cache. Cache SHA goes into the user's status line so they know what version they are running against.
2. **Live sparse-checkout**: on plugin install, sparse-clone `microsoft/BCQuality` into `content/`. Pro: always current. Con: requires network at install + occasional refresh; subject to upstream breaking changes (README says "Large and potentially breaking changes are expected").

Recommendation: **start with vendored snapshot pinned to a known-good commit**, expose `bcq-update [--commit SHA | --latest]`. This matches how Microsoft says agents should consume the repo — pinned to a SHA so findings carry stable references (the DO contract's optional `references[].sha` field is *designed* for exactly this).

### 8.5 Custom layer

This is the killer feature for the user's customer-facing plugin. Because READ defines `/custom/` as the highest-precedence layer, partner/customer-specific guidance "just works" without changing any skill. Concrete shape:

- Plugin ships an empty `content/custom/knowledge/<domain>/` skeleton.
- `bcq-write-knowledge` slash command guides the user (using the WRITE contract rule) through authoring a custom knowledge file, runs the vendored validator on save, and places it in the right layer/domain.
- The skills already source from `*/knowledge/<domain>/`, so the new file is picked up automatically on the next review run.
- Any conflict with a Microsoft or Community file gets resolved in favour of the custom file, and the suppressed file gets surfaced via `suppressed[]` — the user sees exactly what they overrode.

### 8.6 Output rendering

Translate the JSON `findings-report` to:

- **Chat:** structured summary table (severity, file:line, message, link to knowledge file), with a collapsed JSON for power users.
- **Editor diagnostics:** for each finding with a `location`, write a Cursor diagnostic at `file:line` with severity = info|warning|error from `severity ∈ {info, minor, major, blocker}`. Include the `references[0].path` as a clickable link in the diagnostic's related-info.
- **Hover help on AL code:** as a stretch, hovering over an AL identifier in the recent worklist could surface the matching knowledge article — this turns BCQuality into a live API reference.

### 8.7 Status-line / observability

Surface in the status line: `BCQuality v<repo-SHA[0:7]> · <layers enabled> · <last review: X findings>`. This makes the system legible to the user and trivially debuggable when they ask "why didn't this get flagged?".

### 8.8 What NOT to do

- **Do not invent your own JSON output shape.** The whole point of DO is that any orchestrator can consume any skill's output. If you deviate, your output stops being interchangeable with the AL-Go view.
- **Do not embed knowledge content in your skill prompts.** Source it from the cache so updates flow through.
- **Do not pre-filter sub-skills by task content in the super-skill.** The contract is explicit: "the super-skill MUST NOT filter sub-skills by task content". Let each leaf decide.
- **Do not hardcode the BC version.** Read `app.json` from the workspace if present; otherwise treat as `unknown` and cap confidence at `medium`.
- **Do not silently match a missing dimension.** READ requires `unknown` treatment + medium-confidence cap.

---

## 9. Open questions / risks

These are areas where the docs are still evolving or ambiguous — worth tracking before betting heavily on a contract.

1. **Public preview not yet announced.** README states the project is in active development with "large and potentially breaking changes expected." Schema v1 is "locked — changes require a PR approved by both maintainers", but the broader corpus and skill set is still landing. Pin a commit; surface the pinned SHA in your plugin so users can see drift.
2. **No release tags or versions yet.** The validator declares `version: 1` on every skill, but the repo has "No releases published" (per the README sidebar). Versioning expectations beyond skill frontmatter are not documented.
3. **`sub-skills` is flat-only in v1.** Nesting super-skills is explicitly disallowed today. If you build the plugin assuming a single super-skill (`al-code-review`) you are fine; if you imagine composing super-skills of super-skills later, that contract may evolve.
4. **`outputs` is currently a single value (`findings-report`).** The DO doc says "today only `findings-report` is defined", which implies other output kinds (`skeleton-report`?, `audit-report`?) may arrive later.
5. **`technologies` for `kql`, `azure-devops`, `github-actions`** are explicitly mentioned in WRITE/READ but no knowledge files for them exist yet — the entire corpus today is `[al]` (with `al-ui-review` declaring `[al, javascript]`). When non-AL skills land, you may need to add UI for non-AL technologies.
6. **Domain enumeration is open.** The README and READ both say "Consumers MUST treat unknown domains as valid." This is good for extensibility, but a UI for picking domains in the WRITE flow needs a sensible default list. Start with the present 7 (`performance`, `security`, `privacy`, `style`, `ui`, `upgrade`, `testing`) plus the ones called out in scope (`telemetry`, `api`, `pipelines`, `finance`, `supply-chain`, `manufacturing`, `jobs`).
7. **Agent self-review pass is intentionally fuzzy.** The super-skill's agent self-review is *the* place where the underlying LLM's BC knowledge is allowed to leak in, validated against BCQuality content. Quality depends entirely on the host model. Capping at `medium` confidence and tagging with `from-sub-skill: "agent"` is the only safety; users will need to know the agent-tagged findings deserve a closer look.
8. **CodeOwners is one person.** `@jeschulz` owns `/microsoft/`, `/skills/`, and `/.github/`. PR throughput on schema-breaking changes is rate-limited by one reviewer; expect the contract to evolve slowly and predictably (a plus for a plugin builder).
9. **No formal SDK or JSON schema file.** The DO output contract is documented in prose and exemplified, but there is no machine-readable JSON Schema file in the repo to validate output against. You may want to write one yourself (and contribute it back) — start from the example blocks in `do.md` and the al-code-review.md example.
10. **Source semantics for skill discovery.** Entry's Source is "all action skills under `*/skills/**/*.md` across the layers named in `enabled-layers`". A plugin that fetches knowledge incrementally (rather than vendoring) needs to know how to enumerate this — neither README nor agent-consumption.md specifies an index file, so the convention is "enumerate by path glob". You'll need to keep your local index in sync with the cache.
11. **References include optional `sha` but no canonical clock.** The DO contract says consumers SHOULD include `sha` "when the skill was invoked with a specific repo state." If your plugin always pins to a commit, *always include the sha* in every reference. This makes findings reproducible and is the right default.
12. **The `kind: entry-point` / `kind: meta-skill` / `kind: action-skill` distinction is enforced by the validator (R25)** but not surfaced in the README's high-level explanation. Authors of skills outside `/skills/` and `*/skills/` will get confused. Your `bcq-write-skill` flow (if you build one) should warn explicitly.
13. **Empty-corpus is a real state.** The `no-knowledge` outcome is a first-class signal — the al-code-review.md "empty-corpus example" is shown in the docs. Plugins should render `no-knowledge` as "BCQuality has no rules for this kind of change yet" rather than "nothing wrong" — there is a difference, and the DO contract warns: "Orchestrators MUST NOT conflate this with `not-applicable` or `no-knowledge`."

---

## Appendix A — citations of every file read

Pages and files fetched verbatim during this research:

- <https://github.com/microsoft/BCQuality>
- <https://github.com/microsoft/BCQuality/tree/main>
- <https://api.github.com/repos/microsoft/BCQuality/contents/skills>
- <https://api.github.com/repos/microsoft/BCQuality/git/trees/main?recursive=1>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/agent-consumption.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/skills/entry.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/skills/read.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/skills/do.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/skills/write.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/skills/README.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/microsoft/skills/review/al-code-review.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/microsoft/skills/review/al-performance-review.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/microsoft/skills/review/al-security-review.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/microsoft/skills/review/al-privacy-review.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/microsoft/skills/review/al-upgrade-review.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/microsoft/skills/review/al-style-review.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/microsoft/skills/review/al-ui-review.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/.github/workflows/validate-frontmatter.yml>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/.github/scripts/validate_frontmatter.py>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/CODEOWNERS>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/SECURITY.md>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/.gitignore>
- <https://raw.githubusercontent.com/microsoft/BCQuality/main/custom/README.md>

Knowledge articles fetched verbatim:
- `microsoft/knowledge/performance/use-setloadfields-for-partial-records.md` (+ `.good.al`, `.bad.al`)
- `microsoft/knowledge/performance/findset-true-applies-updlock-on-read.md`
- `microsoft/knowledge/performance/use-isempty-for-existence-check.md`
- `microsoft/knowledge/performance/apply-filters-before-iterating.md`
- `microsoft/knowledge/performance/avoid-commit-inside-loops.md`
- `microsoft/knowledge/performance/calcsums-instead-of-calcfields-in-loop.md`
- `microsoft/knowledge/performance/pair-findset-with-next-loop.md`
- `microsoft/knowledge/performance/prefer-modifyall-over-per-row-modify.md`
- `microsoft/knowledge/performance/avoid-recordref-in-hot-loop.md`
- `microsoft/knowledge/performance/setcurrentkey-aligns-key-with-filters.md`
- `microsoft/knowledge/performance/use-get-instead-of-findfirst-on-full-primary-key.md`
- `microsoft/knowledge/performance/maintainsqlindex-false-breaks-flowfield-sift.md`
- `microsoft/knowledge/performance/codeunit-run-requires-prior-commit-inside-transaction.md`
- `microsoft/knowledge/performance/temporary-tables-have-no-database-cost.md`
- `microsoft/knowledge/performance/admin-and-migration-pages-tolerate-lower-perf.md`
- `microsoft/knowledge/security/secrettext-for-credentials.md` (+ `.bad.al`)
- `microsoft/knowledge/security/inherent-permissions-minimal-grant.md`
- `microsoft/knowledge/security/integrationevent-must-not-expose-secrets.md`
- `microsoft/knowledge/security/integrationevent-var-parameter-bypasses-security-guards.md`
- `microsoft/knowledge/privacy/data-classification-required-on-pii-fields.md`
- `microsoft/knowledge/privacy/no-pii-in-telemetry-message-string.md`
- `microsoft/knowledge/privacy/data-classification-is-table-field-property.md`
- `microsoft/knowledge/privacy/in-memory-data-not-a-privacy-concern.md`
- `microsoft/knowledge/privacy/getlasterrortext-customer-content-in-errors.md`
- `microsoft/knowledge/privacy/featuretelemetry-customdimensions-no-pii.md`
- `microsoft/knowledge/style/label-suffix-approved-list.md`
- `microsoft/knowledge/style/api-page-camelcase-properties.md`
- `microsoft/knowledge/style/lowercase-reserved-keywords.md`
- `microsoft/knowledge/style/this-keyword-in-codeunits.md`
- `microsoft/knowledge/style/tooltip-required-on-page-fields.md`
- `microsoft/knowledge/style/error-passes-parameters-directly-not-strsubstno.md`
- `microsoft/knowledge/style/fieldcaption-not-fieldname-in-user-messages.md`
- `microsoft/knowledge/style/named-invocations-not-object-ids.md`
- `microsoft/knowledge/style/file-name-object-type-pattern.md`
- `microsoft/knowledge/upgrade/enum-values-additive-at-end.md`
- `microsoft/knowledge/upgrade/use-upgrade-tags-not-version-checks.md`
- `microsoft/knowledge/upgrade/datatransfer-skips-triggers-and-subscribers.md`
- `microsoft/knowledge/upgrade/obsoletion-requires-reason-and-tag.md`
- `microsoft/knowledge/upgrade/no-external-calls-in-upgrade.md`
- `microsoft/knowledge/upgrade/breaking-changes-only-on-tables-without-data.md`
- `microsoft/knowledge/upgrade/initvalue-does-not-update-existing-rows.md`
- `microsoft/knowledge/ui/show-caption-on-editable-fields.md`
- `microsoft/knowledge/ui/no-nested-grids.md`
- `microsoft/knowledge/ui/group-labeled-first-child-exception.md`
- `microsoft/knowledge/ui/tabular-intent-requires-data-table-conditions.md`
- `microsoft/knowledge/testing/transactionmodel-attribute-governs-test-transactions.md`
- `community/knowledge/performance/use-deleteall-for-filtered-bulk-deletion.md`
- `community/knowledge/performance/avoid-growing-globals-in-singleinstance-subscribers.md`
- `community/knowledge/security/classify-every-field-with-dataclassification.md`
- `community/knowledge/security/protect-sensitive-data-in-temporary-tables.md`

(Knowledge file URLs follow the pattern `https://raw.githubusercontent.com/microsoft/BCQuality/main/<path>`.)

---

*End of report.*
