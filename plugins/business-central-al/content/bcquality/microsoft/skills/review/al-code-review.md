---
kind: action-skill
id: al-code-review
version: 1
title: AL code review
description: Reviews AL source changes by composing the AL review leaf skills (performance, security, privacy, upgrade, style, UI).
inputs: [pr-diff, file-path]
outputs: [findings-report]
bc-version: [all]
technologies: [al]
countries: [w1]
application-area: [all]
sub-skills:
  - microsoft/skills/review/al-performance-review.md
  - microsoft/skills/review/al-security-review.md
  - microsoft/skills/review/al-privacy-review.md
  - microsoft/skills/review/al-upgrade-review.md
  - microsoft/skills/review/al-style-review.md
  - microsoft/skills/review/al-ui-review.md
---

# AL code review

Reviews AL source changes by composing the leaf AL review skills. This is the canonical reference implementation of a **super-skill** — skill authors writing composed reviews should copy its structure.

`al-code-review` does not evaluate knowledge files directly. It invokes each of its sub-skills against the same task input, collects their findings-reports, and then performs its own **self-review pass** over the diff using the agent's built-in BC and AL knowledge. BCQuality knowledge is an additive layer: anything the sub-skills found is cited from BCQuality, and anything the agent finds on its own is validated against BCQuality (cited if matched, suppressed if contradicted, surfaced as an **agent finding** otherwise). The result is a single rolled-up findings-report that mixes knowledge-backed and agent findings, each clearly tagged via `from-sub-skill`.

An orchestrator invokes this skill with either a `pr-diff` (the standard PR-review entry point) or a `file-path` (single-file review). The skill produces a single JSON document conforming to the DO output contract, extended with `sub-results` and — when applicable — `skipped-sub-skills`.

## Source

The sub-skills invoked by this skill are those listed in frontmatter `sub-skills`:

- `microsoft/skills/review/al-performance-review.md`
- `microsoft/skills/review/al-security-review.md`
- `microsoft/skills/review/al-privacy-review.md`
- `microsoft/skills/review/al-upgrade-review.md`
- `microsoft/skills/review/al-style-review.md`
- `microsoft/skills/review/al-ui-review.md`

Additional leaf skills (for example, telemetry, testing) are added by updating the `sub-skills` list. The skill does not discover sub-skills implicitly.

## Relevance

A sub-skill is relevant when both of the following hold:

- The orchestrator has supplied inputs that satisfy the sub-skill's declared `inputs`.
- The orchestrator has not disabled the sub-skill via configuration.

Per the DO contract, the super-skill MUST NOT filter sub-skills by task content. `al-code-review` does not inspect the PR diff to predict whether, for example, there is anything for `al-security-review` to find. Each leaf is responsible for its own task-level applicability decision; leaves signal non-applicability by returning `outcome: "not-applicable"` or `outcome: "no-knowledge"`.

Sub-skills that fail either check are not invoked and are recorded in `skipped-sub-skills`:

- `reason: "configuration"` when the orchestrator disabled the sub-skill.
- `reason: "not-applicable"` when the orchestrator's inputs do not satisfy the sub-skill's declared `inputs`.

## Worklist

The worklist is the list of sub-skills judged relevant by the previous step. Every sub-skill in the worklist will be invoked in the Action step.

## Action

### Roll up sub-skill findings

For each sub-skill in the worklist:

1. Invoke the sub-skill with the orchestrator's inputs, passing only the subset each sub-skill declares in its `inputs`.
2. Capture the sub-skill's complete findings-report verbatim and append it to `sub-results`.
3. If the sub-skill's `outcome` is `failed`, stop here for this sub-skill: its findings are not reliable per the DO contract and MUST NOT be copied into the super-skill's top-level `findings[]` or counted in `summary.counts`.
4. Otherwise, append each entry from the sub-skill's `findings[]` to the super-skill's top-level `findings[]`, setting `from-sub-skill` to the sub-skill's `skill.id`. For non-citation findings (those whose `id` is a skill-defined slug rather than a reference path), prefix `id` with `<from-sub-skill>:` to prevent collisions across sub-skills. Other finding fields are preserved.

### Agent self-review pass

After the sub-skill rollup, perform a self-review pass against the same task input using the agent's built-in BC and AL knowledge. BCQuality is an **additive** knowledge layer: it augments the agent's review judgement, it does not replace it. The goal of this pass is to surface defects the agent recognises on its own — bugs, anti-patterns, error-handling gaps, AL idioms — that the leaf sub-skills did not catch because no BCQuality knowledge file covers them yet.

For every candidate the agent identifies in this pass:

1. **Validate against BCQuality knowledge.** Check the candidate against the knowledge files the sub-skills have already loaded for this task (visible via their `references` and `suppressed` lists in `sub-results`).
   - If a BCQuality knowledge file matches the candidate, upgrade it to a knowledge-backed finding: cite the file in `references`, set `id` to the file's path, set `from-sub-skill` to the sub-skill that owns that knowledge domain, and merge with or deduplicate against any sub-skill finding that already covers the same concern at the same location.
   - If a BCQuality knowledge file **explicitly contradicts** the candidate (its `## Best Practice` or `## Anti Pattern` says the opposite of what the agent flagged), suppress the candidate and do not surface it.
   - Otherwise the candidate has no BCQuality coverage; emit it as an agent finding.
2. **Emit agent finding.** Per DO's *Agent findings* rules:
   - `from-sub-skill: "agent"`
   - `references: []`
   - `id` is a skill-defined slug prefixed with `agent:` (for example, `agent:missing-error-handling-on-http-call`).
   - `confidence` capped at `medium`.
   - `message` is non-empty and self-contained, describing both the issue and a concrete recommendation. A consumer rendering the finding has no knowledge-file footer to fall back on.

Leaf sub-skills MUST NOT emit agent findings: their scope is bounded by the knowledge subset they evaluate. The self-review pass is a super-skill responsibility.

### Summary and rollup

Aggregate `summary.counts` and `summary.coverage` as the sums across invoked sub-skills whose `outcome` is not `failed`. Agent findings emitted by the super-skill itself contribute to `summary.counts` but not to `summary.coverage` (coverage is a sub-skill worklist metric and is undefined for self-review).

`suppressed[]` at the super-skill level remains empty. Knowledge-file-level suppression is reported by each sub-skill within its own entry in `sub-results`.

Derive `outcome` using the DO rollup rules. `outcome-reason` is populated for `partial` and `failed` and SHOULD summarize per-sub-skill state, for example: *"al-security-review failed (tool timeout); al-performance-review completed."*

## Output

Output conforms to the DO output contract, extended with `sub-results` and `skipped-sub-skills`. A populated example — both leaves ran, each produced findings:

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
    {
      "id": "community/knowledge/performance/call-setloadfields-before-filters.md",
      "severity": "minor",
      "message": "SetLoadFields is called after SetRange. Per the referenced guidance the call must come before filters to be folded into the query plan.",
      "location": {
        "file": "src/Sales/PostingRoutines.Codeunit.al",
        "line": 152
      },
      "references": [
        { "path": "community/knowledge/performance/call-setloadfields-before-filters.md" }
      ],
      "confidence": "high",
      "from-sub-skill": "al-performance-review"
    },
    {
      "id": "microsoft/knowledge/security/use-secrettext-for-credentials.md",
      "severity": "blocker",
      "message": "A bearer token is declared as a Text parameter and passed through the HTTP request path as plain text. The referenced guidance requires credentials to flow as SecretText end-to-end.",
      "location": {
        "file": "src/Integration/ApiClient.Codeunit.al",
        "line": 85,
        "range": { "start-line": 85, "end-line": 89 }
      },
      "references": [
        { "path": "microsoft/knowledge/security/use-secrettext-for-credentials.md" }
      ],
      "confidence": "high",
      "from-sub-skill": "al-security-review"
    },
    {
      "id": "microsoft/knowledge/security/never-hardcode-secrets-in-al.md",
      "severity": "minor",
      "message": "An API key is assigned from a string literal rather than retrieved from IsolatedStorage or Key Vault at runtime.",
      "location": {
        "file": "src/Integration/ApiClient.Codeunit.al",
        "line": 201
      },
      "references": [
        { "path": "microsoft/knowledge/security/never-hardcode-secrets-in-al.md" }
      ],
      "confidence": "medium",
      "from-sub-skill": "al-security-review"
    },
    {
      "id": "agent:missing-error-handling-on-http-client",
      "severity": "minor",
      "message": "HttpClient.Send is called without inspecting the response status or wrapping the call in a TryFunction. Network or remote-server failures will surface as runtime errors to the user. Recommendation: branch on the HttpResponseMessage.IsSuccessStatusCode and either retry, surface a controlled error, or fall back, depending on the integration's contract.",
      "location": {
        "file": "src/Integration/ApiClient.Codeunit.al",
        "line": 60,
        "range": { "start-line": 60, "end-line": 64 }
      },
      "references": [],
      "confidence": "medium",
      "from-sub-skill": "agent"
    }
  ],
  "suppressed": [],
  "sub-results": [
    {
      "skill": { "id": "al-performance-review", "version": 1 },
      "outcome": "completed",
      "summary": {
        "counts": { "blocker": 0, "major": 1, "minor": 1, "info": 0 },
        "coverage": { "worklist-size": 2, "items-evaluated": 2 }
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
          "confidence": "high"
        },
        {
          "id": "community/knowledge/performance/call-setloadfields-before-filters.md",
          "severity": "minor",
          "message": "SetLoadFields is called after SetRange. Per the referenced guidance the call must come before filters to be folded into the query plan.",
          "location": {
            "file": "src/Sales/PostingRoutines.Codeunit.al",
            "line": 152
          },
          "references": [
            { "path": "community/knowledge/performance/call-setloadfields-before-filters.md" }
          ],
          "confidence": "high"
        }
      ],
      "suppressed": []
    },
    {
      "skill": { "id": "al-security-review", "version": 1 },
      "outcome": "completed",
      "summary": {
        "counts": { "blocker": 1, "major": 0, "minor": 1, "info": 0 },
        "coverage": { "worklist-size": 2, "items-evaluated": 2 }
      },
      "findings": [
        {
          "id": "microsoft/knowledge/security/use-secrettext-for-credentials.md",
          "severity": "blocker",
          "message": "A bearer token is declared as a Text parameter and passed through the HTTP request path as plain text. The referenced guidance requires credentials to flow as SecretText end-to-end.",
          "location": {
            "file": "src/Integration/ApiClient.Codeunit.al",
            "line": 85,
            "range": { "start-line": 85, "end-line": 89 }
          },
          "references": [
            { "path": "microsoft/knowledge/security/use-secrettext-for-credentials.md" }
          ],
          "confidence": "high"
        },
        {
          "id": "microsoft/knowledge/security/never-hardcode-secrets-in-al.md",
          "severity": "minor",
          "message": "An API key is assigned from a string literal rather than retrieved from IsolatedStorage or Key Vault at runtime.",
          "location": {
            "file": "src/Integration/ApiClient.Codeunit.al",
            "line": 201
          },
          "references": [
            { "path": "microsoft/knowledge/security/never-hardcode-secrets-in-al.md" }
          ],
          "confidence": "medium"
        }
      ],
      "suppressed": []
    }
  ]
}
```

The empty-corpus case — BCQuality's state until knowledge files land — rolls up to `no-knowledge`:

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
    {
      "skill": { "id": "al-performance-review", "version": 1 },
      "outcome": "no-knowledge",
      "summary": { "counts": { "blocker": 0, "major": 0, "minor": 0, "info": 0 }, "coverage": { "worklist-size": 0, "items-evaluated": 0 } },
      "findings": [],
      "suppressed": []
    },
    {
      "skill": { "id": "al-security-review", "version": 1 },
      "outcome": "no-knowledge",
      "summary": { "counts": { "blocker": 0, "major": 0, "minor": 0, "info": 0 }, "coverage": { "worklist-size": 0, "items-evaluated": 0 } },
      "findings": [],
      "suppressed": []
    }
  ]
}
```
