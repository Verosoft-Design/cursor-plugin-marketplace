# vsd-feature-lifecycle (Cursor mirror)

The Verosoft feature lifecycle: it sizes dev work as a bug, a feature or a major change, runs the steps that size needs, keeps one home for every spec, and stops at named gates for Stéphane Levert's or Alexis Turgeon's approval.

This is a mirror of the Claude Code plugin in [Verosoft-Design/claude-plugins](https://github.com/Verosoft-Design/claude-plugins/tree/main/plugins/vsd-feature-lifecycle), where the full README lives.

- **The skills are copied unchanged** from a tagged release; `SYNCED_FROM` names the tag.
- **To update,** run `scripts/sync-vsd-feature-lifecycle.sh <tag>` at the repo root, bump `version` in `.cursor-plugin/plugin.json` and `CHANGELOG.md`, and commit.
- **Never edit `skills/` here.** Change the Claude plugin and sync.
