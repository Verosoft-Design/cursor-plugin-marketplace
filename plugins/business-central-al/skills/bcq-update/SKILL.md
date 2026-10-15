---
name: bcq-update
description: Refresh the plugin's vendored upstream content (BCApps rulesets, BCApps review prompts, and the BCQuality knowledge, skills, contracts, schemas and tools) and re-pin to a new commit SHA. Updates content/PINNED.json with the new SHAs and fetched-at dates. Use periodically to pick up new upstream guidance, or to catch up after a long pause.
disable-model-invocation: true
---

# Refresh vendored upstream content

Wraps the per-source vendor scripts. By default it refreshes ALL sources to the latest `main`.

## What this command does

1. Read `<plugin>/content/PINNED.json` to see what is currently pinned.
2. Run each vendor script with `--latest`, or with `--ref <sha>` if the user asks for one.
3. `vendor-bcquality.sh` runs the upstream BCQuality validator over the whole tree, including the custom layer. It updates `PINNED.json` (`bcquality.ref`, `fetched_at`, `license_url`) only when validation passes.
4. Summarize what changed: files added, modified and removed, new or removed knowledge domains and review leaves, articles that moved between layers, and any changes to `skills/{entry,read,do,write}.md` or `schemas/findings-report.schema.json`.

## Where to run it

Run the vendor scripts in a checkout of the `Verosoft-Design/cursor-plugin-marketplace` repo, against `plugins/business-central-al/`, then commit. The installed copy under `~/.cursor/plugins/` is replaced on every plugin update, so refreshing it in place is lost.

## Granular invocation

```bash
# All sources, latest main of each
<plugin>/scripts/vendor-bcapps.sh --latest
<plugin>/scripts/vendor-bcquality.sh --latest

# Pin to a specific SHA / branch / tag
<plugin>/scripts/vendor-bcapps.sh --ref dc1242e3
<plugin>/scripts/vendor-bcquality.sh --ref <sha>

# Use a Python that has PyYAML for the validator step
PYTHON=/path/to/venv/bin/python <plugin>/scripts/vendor-bcquality.sh --latest
```

## What vendor-bcquality.sh mirrors

`content/bcquality/` mirrors the microsoft/BCQuality repository layout, so upstream's repo-relative paths resolve unchanged:

| Path under `content/bcquality/`        | Upstream source                            |
| -------------------------------------- | ------------------------------------------ |
| `skills/{entry,read,do,write}.md`      | `skills/` (Entry + READ/DO/WRITE)          |
| `microsoft/{knowledge,skills}/`        | `microsoft/`                               |
| `community/{knowledge,skills}/`        | `community/`                               |
| `schemas/`, `docs/`, `LICENSE`         | same paths                                 |
| `tools/*.ps1`                          | `tools/` (the upstream `Test-*` harnesses are skipped) |
| `scripts/validate-bcquality-frontmatter.py` (plugin root, not under content/) | `.github/scripts/validate_frontmatter.py` |

Upstream's own Copilot/Claude host adapter (`skills/al-code-review/SKILL.md`) is not vendored, because this plugin ships its own adapters under `skills/`. `knowledge-index.json` and `skill-index.json` are generated at review time and git-ignored.

## Validation after update

```bash
python3 <plugin>/scripts/validate-bcquality-frontmatter.py --root <plugin>/content/bcquality
```

The validator needs PyYAML (`pip install pyyaml`, or set `PYTHON`). The upstream validator comes down with each update, so new rules apply to the custom layer too. If validation FAILS, the script leaves `PINNED.json` untouched. Fix the custom article it names, or go back to the prior SHA with `--ref <previous-sha>`.

## After a BCQuality update: check the adapters

The plugin wraps each upstream action skill with a thin adapter:

- `al-<domain>-review`: model-invocable.
- `bcq-review-<domain>`: user command.
- `al-code-review`, `al-entry`, and `bcq-review`.

When upstream adds, renames or removes a leaf (compare `microsoft/skills/review/` and `community/skills/review/`, and `al-code-review.md`'s `sub-skills`), add, rename or remove the matching adapters. Then update the lists in `al-entry`, `al-code-review`, `bcq-review` and the `bcquality-entry-contract` rule. Also re-check the `bcquality-do-contract` rule and `scripts/render-findings.py` against `skills/do.md` and `schemas/findings-report.schema.json`.

## Custom layer is never overwritten

The vendor script replaces only upstream-managed paths: `microsoft/`, `community/`, `skills/`, `schemas/`, `tools/`, `docs/` and `LICENSE`. Content under `content/bcquality/custom/knowledge/` and `content/bcquality/custom/skills/` is preserved. If an updated upstream article now CONFLICTS with a custom article, the next review surfaces it in the leaf's `suppressed[]` (layer precedence).

## Re-pinning cautiously

- For production workflows, stay on the SHA that is known to work.
- To stay current, run `/bcq-update` monthly (BCQuality cuts monthly content releases) or once per BC wave.
- Before relying on BCQuality output in automation, diff `skills/do.md` and `schemas/findings-report.schema.json` between the old and new SHA.

## When to invoke

- It has been more than a few weeks since the last refresh.
- A new BC version has shipped.
- A review cites an article the user knows is out of date, or misses a known domain.
