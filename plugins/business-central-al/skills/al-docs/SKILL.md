---
name: al-docs
description: Generate, refresh, or audit hierarchical documentation for a Business Central AL codebase. Wraps the BCApps al-docs-plugin (init / update / audit modes) to produce or maintain data-model, business-logic, extensibility, and patterns docs adapted to AL object types, table relationships, event-driven architecture, and extension patterns. Use when the user asks to document AL code, set up docs for an AL project, refresh docs after code changes, or run a gap analysis on existing documentation.
---

# AL Docs — hierarchical AL documentation generator

This skill wraps BCApps' `al-docs-plugin` for Cursor. It generates AL-aware documentation tailored to BC object types, table relationships, event architecture, and extension patterns.

## Authoritative spec

The complete authoritative content is vendored under `<plugin>/content/al-docs-references/`:

| File                | Purpose                                                              | Lines |
| ------------------- | -------------------------------------------------------------------- | ----- |
| `SKILL.md`          | The original BCApps skill manifest with mode routing.                | 103   |
| `al-docs-init.md`   | Bootstrap mode — generate docs from scratch for an AL app or folder. | 648   |
| `al-docs-update.md` | Refresh mode — incrementally update docs based on code changes.      | 255   |
| `al-docs-audit.md`  | Audit mode — read-only gap analysis without writing files.           | 188   |
| `al-scoring.md`     | Quality-scoring reference used by audit mode.                        | 56    |

Vendored from `microsoft/BCApps/tools/al-docs-plugin/skills/al-docs/` at the SHA pinned in `<plugin>/content/PINNED.json` → `bcapps.categories.al_docs`. License: MIT.

## Mode routing

Read the user's intent and dispatch to the right reference file. Always read the full reference file before executing — never run from memory.

| User intent                                                                               | Mode       | Reference file                                 |
| ----------------------------------------------------------------------------------------- | ---------- | ---------------------------------------------- |
| "document this AL app", "set up docs", "create docs for this extension", "bootstrap docs" | **init**   | `content/al-docs-references/al-docs-init.md`   |
| "refresh my docs", "update the docs after these changes", "regenerate"                    | **update** | `content/al-docs-references/al-docs-update.md` |
| "what documentation is missing", "audit the docs", "doc gap analysis"                     | **audit**  | `content/al-docs-references/al-docs-audit.md`  |

When the user does not specify a mode, default to **init** for a fresh project (no `CLAUDE.md` / `AGENTS.md` exists yet) or **audit** for a project that already has documentation.

## Output target

The BCApps source skill writes to `CLAUDE.md` (Anthropic Claude Code's convention). For Cursor users:

- **For Cursor compatibility**: write to `AGENTS.md` at the same locations the reference files name `CLAUDE.md`. Cursor consumes `AGENTS.md` the same way Claude Code consumes `CLAUDE.md`.
- **For both ecosystems**: write to both `CLAUDE.md` and `AGENTS.md` (symlink or mirror).
- **When the project already has one or the other**: keep using what's there.

The reference files reference `CLAUDE.md` throughout; treat that as "primary agent-context doc" and substitute accordingly.

Companion documents the reference files produce:

- `data-model.md` — tables, fields, relationships, FlowFields, primary keys.
- `business-logic.md` — codeunits, public procedures, integration events, validation flows.
- `extensibility.md` — interface implementations, event publishers, dependency contracts.
- `patterns.md` — recurring patterns observed in the codebase (facade+Impl, registry codeunits, etc.).

## Apply contract rules

The al-docs skill is not BCQuality-governed, so the BCQuality contract rules don't apply directly. But several Cursor-side rules SHOULD inform the generated docs:

- `al-naming-and-files` — when describing files / object naming.
- `al-labels-and-locked` — when documenting label conventions.
- `al-xmldoc-public-procedures` — the docs should reflect XML-doc-driven public surface.
- `al-testing` — when describing the test scaffold (if `init` includes test docs).

## When to invoke

- **init**: fresh AL project with no `CLAUDE.md` / `AGENTS.md`, OR after a major refactor that obsoletes prior docs.
- **update**: after a feature merge that added new tables / codeunits / events. Lightweight; only re-touches the sections affected by the diff.
- **audit**: before publishing the project to AppSource (or any external audience). Read-only; produces a gap report.

## Workflow

1. **Read the user's request** to determine init vs update vs audit.
2. **Read the corresponding reference file** in full from `<plugin>/content/al-docs-references/`.
3. **Execute the reference file's instructions** against the target directory (default: current AL project root; user can specify a sub-path).
4. **Write the resulting docs** to `AGENTS.md` (or `CLAUDE.md` if the user prefers Claude Code primary).
5. **Report a summary** to chat — what was generated/updated, what gaps were found (audit mode), what files changed.

## Safety

- The BCApps reference files explicitly say "read the full mode file before executing — never run from memory." Honor that.
- Init mode WRITES many files. Confirm with the user before bulk-writing.
- Update mode is incremental but can still touch many files. Surface the diff scope before applying.
- Audit mode is READ-ONLY — never writes files. Use this mode liberally as a quality check.

## Related

- `al-xmldoc-public-procedures` — the always-on rule for XML doc on public surface. The docs this skill generates are richer when XML docs already exist.
- `/al-deploy-docs` — the Phase 2 command that publishes the `aldoc`-generated REFERENCE docs (compiler-generated AL object reference) to GitHub Pages. The al-docs skill generates NARRATIVE docs, complementary to aldoc.
