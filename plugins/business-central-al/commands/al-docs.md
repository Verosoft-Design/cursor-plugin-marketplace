---
name: al-docs
description: Generate, refresh, or audit hierarchical AL documentation. Init mode bootstraps docs for a fresh project, update mode refreshes after code changes, audit mode is a read-only gap analysis. Use to document an AL app, set up agent-context docs (AGENTS.md / CLAUDE.md), or check what documentation is missing.
---

# AL Docs (init / update / audit)

Invokes the `al-docs` skill which wraps BCApps' MIT-licensed `al-docs-plugin`.

## Mode dispatch

Pass the mode as an argument; the skill reads the corresponding reference file from `<plugin>/content/al-docs-references/`:

| Mode     | What it does                                                                                                                                                                                      |
| -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `init`   | Bootstrap documentation for an AL app or folder. Writes `AGENTS.md` (or `CLAUDE.md`) plus `data-model.md`, `business-logic.md`, `extensibility.md`, `patterns.md`. ~648 lines of reference logic. |
| `update` | Incrementally refresh existing docs based on code changes since the last update. Only re-touches sections the diff affects.                                                                       |
| `audit`  | Read-only gap analysis. Produces a quality-scored report identifying missing or stale documentation. Writes no files.                                                                             |

If the user does not specify a mode:

- **No `AGENTS.md` / `CLAUDE.md` exists** → default to `init`.
- **Docs already exist** → default to `audit`.

## Common invocations

```
/al-docs                       # auto-detect mode based on existing docs
/al-docs init                  # bootstrap from scratch
/al-docs init "src/Email"      # bootstrap for a specific subfolder
/al-docs update                # refresh after recent changes
/al-docs audit                 # gap analysis only
```

## Safety

- `init` mode WRITES many files. The skill confirms with the user before bulk-writing.
- `update` mode is incremental but can still touch many files. Skill surfaces the diff scope before applying.
- `audit` mode is READ-ONLY — safe to run anytime as a quality check.

## Output target

- For Cursor projects: docs go to `AGENTS.md` (Cursor's convention) at the locations the reference files name `CLAUDE.md`.
- For dual Cursor + Claude Code projects: write to both (or symlink one to the other).
- For projects already using `CLAUDE.md`: keep using it.

## Related

- `/al-deploy-docs` — Phase 2 command that publishes `aldoc`-generated REFERENCE docs (compiler-extracted AL object reference) to GitHub Pages. The al-docs skill generates NARRATIVE docs, complementary to aldoc.
- `al-xmldoc-public-procedures` — the always-on rule that mandates XML doc on public procedures. al-docs benefits from rich XML docs in the source.
