# business-central-al plugin v0.2.0 — rebuild notes

Working notes for the multi-phase rebuild of `plugins/business-central-al/` into a full-lifecycle AL agent plugin. Authored by Cursor agent on 2026-05-25.

## Files in this folder

| File | Purpose |
|---|---|
| `README.md` | This index. |
| `PLAN.md` | The full master plan — every file to be created, in which phase. The agent's primary reference. |
| `DECISIONS.md` | User's answered decisions + any still-open questions. |
| `PROGRESS.md` | Checklist tracker — what's done, in-progress, pending. Update as work proceeds. |
| `TAG_CUSTOM_LAYER.md` | TAG-specific conventions distilled from the old tag-bc workspace, ready to become BCQuality `custom/` layer knowledge articles in Phase 4. |
| `GOTCHAS.md` | Cross-cutting "things I'd otherwise forget" — pinned upstream gotchas, deprecation calendars, MCP quirks. |
| `research/` | The four exhaustive research dossiers (BCQuality, AL-Go + MCP, BC-Bench, BCApps) copied from `/tmp/`. **These are the source of truth — re-read before any phase.** |
| `tag-source/` | The 8 original TAG-specific `.mdc` rules copied from `/Users/alexisturgeon/Source/tag-bc/.cursor/rules/`. **Preserved here because that workspace may close.** |

## How to resume in a future session

If you're a fresh agent picking this up:

1. Read `PLAN.md` first — that's the contract.
2. Read `PROGRESS.md` second — that tells you what phase to start.
3. Read `DECISIONS.md` — those are the rails you must stay on.
4. Read `GOTCHAS.md` — that's the small print that's easy to miss.
5. Only re-read the dossiers in `research/` for the *current* phase (no need to ingest all four at once).
