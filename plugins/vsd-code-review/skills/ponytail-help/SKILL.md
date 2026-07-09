---
name: ponytail-help
description: Quick reference for ponytail levels, skills, and commands
disable-model-invocation: true
---

Show the ponytail quick reference. One shot, change nothing: do not switch mode, write flag files, or persist anything.

**Levels**

- `/ponytail lite` — build what's asked, name the lazier alternative in one line
- `/ponytail` — full (default ladder: YAGNI → stdlib → native → one line → minimum)
- `/ponytail ultra` — deletion before addition, challenges the requirement before building

**Commands**

- `/ponytail-review` — over-engineering review of the current changes (KISS/YAGNI tags only)
- `/vsd-code-review` — VSD pre-merge gate: thermo-nuclear structure + KISS/YAGNI + Fallow + deslop + test bar (report only)
- `/vsd-code-review rerun` — same review with a prior-blockers scorecard vs the last review in thread
- `/deslop` — remove AI slop from branch diff vs main (comments, defensive noise, any-casts; edits allowed)
- `/ponytail-audit` — whole-repo over-engineering audit
- `/ponytail-debt` — harvest `ponytail:` comments into a tracked ledger
- `/ponytail-gain` — measured-impact scoreboard from the benchmark
- `/ponytail-help` — this card

**In this plugin**

- Baseline rule: this plugin's `rules/ponytail.mdc` (lazy senior dev mode, loaded on demand)
- Deactivate for a session by saying "stop ponytail" or "normal mode", or run `/ponytail off`
- Resume anytime with `/ponytail`

Source: [ponytail/commands](https://github.com/DietrichGebert/ponytail/tree/main/commands)
