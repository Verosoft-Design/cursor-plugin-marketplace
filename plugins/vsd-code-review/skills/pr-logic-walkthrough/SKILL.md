---
name: pr-logic-walkthrough
description: Produces a report-only PR business-logic walkthrough and requirement traceability when a Linear issue is linked. Use when explicitly invoked by PR automation or manually to explain changed business processes from a PR diff, base, title, and body.
disable-model-invocation: true
user-invokable: true
---

# PR Logic Walkthrough

Produce a read-only explanation of the business behavior changed by a pull request. This is not a code-quality review and must not modify files, the PR, Linear, or any other system.

## Automation contract

PR automation must explicitly invoke this skill and provide:

- PR diff and base/ref (or an equivalent changed-file list and patch)
- PR title
- PR body

Never write to Linear. A missing, inaccessible, or unlinked Linear issue must not fail the review; state that traceability is unavailable and continue.

## Workflow

1. Read the supplied diff and base, then inspect each changed unit in context.
2. From the title and body metadata, extract only the first Linear identifier or URL. If one exists, use the available Linear MCP `get_issue` tool read-only, passing only its issue ID or key. If it is unavailable or the lookup fails, continue and mark traceability unavailable.
3. Follow the direct business path for the changed behavior as applicable:
   - callers, routes, server actions, and services
   - data model reads and writes
   - authorization, validation, and other input boundaries
   - jobs, events, queues, and integrations
   - focused tests that demonstrate the path
4. Consult `packages/knowledge-base/bc/business-logic/INDEX.md` and `PROCESS-FLOWS.md` only when they add relevant TAG/Business Central domain context. Source code is authoritative. Call out any documentation contradiction without resolving it by assumption.
5. Cite evidence for every material claim using file paths and line ranges (and relevant diff hunks when useful). Separate evidence from inference.

## Walkthrough method

For each meaningful scenario, describe the process in business language:

`actor or trigger → authorization/input → reads and writes → rules and branches → side effects → observable result`

Include both successful and material alternate or failure paths exposed by the change. Identify unchanged dependencies only when they are necessary to understand the changed outcome. Do not speculate about paths that the diff and direct call chain do not support.

## Required report

Use exactly these sections, in this order:

## Business intent

State the likely business outcome, evidence, and any uncertainty.

## Changed process map

Map each changed end-to-end process with the walkthrough method. Cite the units that implement each stage.

## Scenario walkthroughs

Explain representative success, branch, validation, authorization, and asynchronous/integration scenarios affected by the PR.

## Rules and invariants

List business rules, data constraints, permissions, validation conditions, idempotency or state-transition expectations, and observable side effects. Mark inferred rules as inference.

## Requirement traceability (implemented/partial/absent/unverifiable)

When Linear was found and read, begin with `Linear issue: <key> — <title>`. Map every stated requirement to its status and source evidence. Give each requirement one status:

- **implemented** — direct evidence satisfies it
- **partial** — evidence covers only part of it
- **absent** — changed path does not implement it
- **unverifiable** — evidence is insufficient

If no issue is linked, or lookup is unavailable, say `Traceability unavailable: no readable Linear issue was provided.` Do not infer requirements from the PR title alone.

## Reviewer decisions

State the business decisions a reviewer should confirm, including deliberately retained branches, ownership/permission assumptions, data effects, and integration outcomes. These are questions for product or domain review, not quality verdicts.

## Out of scope pointing to VSD

State that code style, security, maintainability, architecture, dead code, duplication, and test-quality judgments are out of scope and belong to VSD review.

## Boundaries

- Do not give style, security, structural, maintainability, or test-quality verdicts.
- Do not run or modify VSD, add scripts, install dependencies, write comments, update Linear, or alter the PR.
- Do not turn missing tests into a quality finding; use focused tests only as behavioral evidence.
- Do not claim a requirement is implemented without source evidence.

## Self-check

Before returning the report, verify:

- Every material business claim has code evidence or is explicitly labeled inference.
- The direct path covers applicable entry point, authorization/input, data effects, rules, side effects, and result.
- Linear was read only through `get_issue` with an ID/key, or traceability is clearly unavailable.
- Documentation context did not override source code, and contradictions are flagged.
- No mutation, VSD concern, or quality verdict appears in the report.
