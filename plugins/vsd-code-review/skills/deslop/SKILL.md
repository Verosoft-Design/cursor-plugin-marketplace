---
name: deslop
description: Remove AI-generated slop from branch changes (comments, defensive noise, any-casts). Edits allowed.
disable-model-invocation: true
---

# Remove AI code slop

Check the diff against **main** and remove AI-generated slop introduced in the branch.

## Scope

`git diff main...HEAD` (or `git diff main` if no merge base). Include staged changes if present.

## Focus

- Extra comments that are unnecessary or inconsistent with local style
- Defensive checks or try/catch blocks abnormal for trusted code paths
- Casts to `any` used only to bypass type issues
- Deeply nested code that should be simplified with early returns
- Verbose naming, redundant wrappers, or patterns inconsistent with the file and surrounding codebase

## Guardrails

- Keep behavior unchanged unless fixing a clear bug
- Prefer minimal, focused edits over broad rewrites
- Match existing naming, imports, and comment density in each file

## Workflow

1. `git diff main...HEAD --stat` then read changed hunks
2. Compare each addition to surrounding file style (comment density, error handling, typing)
3. Remove slop with the smallest diff that preserves behavior
4. Run targeted tests or lint on touched files if the change is non-trivial

End with a **1–3 sentence** summary of what was removed. If the branch is already clean: `No slop. Ship.`
