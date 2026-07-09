# vsd-code-review

Cursor plugin for the Verosoft Design (VSD) pre-merge quality gate — a one-shot, report-only review that combines a thermo-nuclear structural audit, a KISS/YAGNI pass, Fallow dead-code hygiene, an AI-slop (deslop) audit, and a TDD test bar.

## What it provides

- **Skills** — slash-invokable review workflows (`/vsd-code-review`, `/deslop`, `/ponytail*`) plus the vendored thermo-nuclear review rubric
- **Agent** — `thermo-nuclear-code-quality-review`, a Task subagent the review skill launches for the structural audit
- **Rules** — soft (non-always-on) versions of the ponytail (KISS/YAGNI), Fallow hygiene, and test-driven-development guidance the review skill loads on demand

Everything is repo-agnostic. Fallow steps run only when Fallow tooling is present in the workspace; otherwise the report notes that they were skipped.

## Skills

| Skill | Purpose |
| --- | --- |
| `vsd-code-review` | Pre-merge gate: thermo-nuclear structure + KISS/YAGNI + Fallow + deslop + test bar (report only). `rerun` argument adds a prior-blockers scorecard. |
| `deslop` | Remove AI-generated slop from the branch diff vs main (edits allowed). |
| `thermo-nuclear-code-quality-review` | The strict maintainability rubric used by the structural audit subagent. |
| `ponytail` | Switch ponytail intensity level (lite/full/ultra/off). |
| `ponytail-review` | Over-engineering review of the current changes (KISS/YAGNI tags only). |
| `ponytail-audit` | Whole-repo over-engineering audit. |
| `ponytail-debt` | Harvest `ponytail:` comments into a tracked debt ledger. |
| `ponytail-gain` | Ponytail's measured-impact scoreboard (benchmark medians). |
| `ponytail-help` | Quick reference card for levels, skills, and commands. |

## Usage

- `/vsd-code-review` — review uncommitted + staged changes (or say "branch" / name a base for a branch diff)
- `/vsd-code-review rerun` — same review with a Fixed/Partial/Remaining scorecard against the previous review in the thread
- `/deslop` — auto-remove AI slop from the branch diff vs main
- `/ponytail-review` — quick KISS/YAGNI-only pass on current changes

## Install

Install from this marketplace repository (import the repo URL in Cursor, then install `vsd-code-review`). The skills, agent, and rules register automatically.

## Notes

- The review is report-only: it never edits code, commits, or fixes findings unless explicitly asked afterwards. `/deslop` is the edit-allowed companion.
- The bundled rules ship with `alwaysApply: false`; they inform the review without injecting themselves into every conversation. Repos that want the always-on behavior can copy them into their own `.cursor/rules/` with `alwaysApply: true`.
