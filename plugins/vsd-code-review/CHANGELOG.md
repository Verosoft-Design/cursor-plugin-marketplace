# Changelog

## [1.1.0] — 2026-07-13

### Added

- Skill: `pr-logic-walkthrough` — report-only PR business-logic walkthrough with optional Linear requirement traceability (invokable via PR automation or `/pr-logic-walkthrough`).

## [1.0.0] — 2026-07-09

### Added

- Initial release, migrated from the Mobi repo's `.cursor/commands/vsd-code-review.md` and its dependency graph.
- Skills: `vsd-code-review`, `deslop`, `thermo-nuclear-code-quality-review`, `ponytail`, `ponytail-review`, `ponytail-audit`, `ponytail-debt`, `ponytail-gain`, `ponytail-help` (all slash-invokable via `disable-model-invocation: true`, except the thermo-nuclear rubric which is loaded by the subagent).
- Agent: `thermo-nuclear-code-quality-review` (vendored from cursor-team-kit; rubric pointer updated to this plugin's skill).
- Rules (soft, `alwaysApply: false`): `ponytail`, `fallow`, `test-driven-development` — loaded by the review skill on demand, repo-agnostic.
- Fallow phases degrade gracefully: when Fallow tooling is absent, the report notes `Fallow not available in this workspace — skipped.`
