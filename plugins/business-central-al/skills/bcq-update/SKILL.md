---
name: bcq-update
description: Refresh the plugin's vendored upstream content (BCApps rulesets, BCApps review prompts, BCQuality knowledge files and skills) and re-pin to a new commit SHA. Updates content/PINNED.json with the new SHAs and fetched-at dates. Use periodically to pick up new upstream guidance, or after a long pause to catch up.
disable-model-invocation: true
---

# Refresh vendored upstream content

Wraps the per-source vendor scripts. Default behavior: refresh ALL sources to the latest `main`.

## What this command does

1. Read `<plugin>/content/PINNED.json` to see what is currently pinned.
2. Run each vendor script with `--latest` (or `--ref <sha>` per user request).
3. Re-run the upstream BCQuality validator to confirm no schema violations slipped in with the upstream update.
4. Update `content/PINNED.json` with the new SHAs and fetched-at dates (the vendor scripts do this themselves).
5. Surface a diff summary of what changed (how many files added/modified/removed, which knowledge files moved between layers, etc.).

## Granular invocation

For targeted refreshes:

```bash
# All sources, latest main of each
<plugin>/scripts/vendor-bcapps.sh --latest
<plugin>/scripts/vendor-bcquality.sh --latest

# Pin to a specific SHA / branch / tag
<plugin>/scripts/vendor-bcapps.sh --ref dc1242e3
<plugin>/scripts/vendor-bcquality.sh --ref preview
```

## Validation after update

Always re-run:

```bash
python3 <plugin>/scripts/validate-bcquality-frontmatter.py --root <plugin>/content/bcquality
```

The upstream validator is part of the vendored content, so any breaking changes to it come down with the update. If validation FAILS after a refresh, the safe action is to revert PINNED.json to the prior SHA — the user can do this from git, or via `--ref <previous-sha>`.

## Custom layer is never overwritten

The vendor scripts touch only `content/bcquality/microsoft/` and `content/bcquality/community/`. Custom content under `content/bcquality/custom/knowledge/` and `content/bcquality/custom/skills/` is preserved across updates.

If an updated upstream article now CONFLICTS with a custom article, the next review run will surface the conflict via `suppressed[]` per layer precedence.

## BCQuality preview note

The BCQuality repo is in active development. The README warns of breaking changes. Re-pin cautiously:

- For production workflows, stay on the SHA that was working.
- For staying current, schedule a `/bcq-update --latest` weekly or per BC wave.
- Before any major refactor that consumes BCQuality output, verify the JSON output contract hasn't changed (read DO's diff between old and new SHA).

## When to invoke

- It has been more than a few weeks since the last refresh.
- A new BC version has shipped (new domain articles may have landed).
- Microsoft Learn or the BC blog announces a BCQuality update.
- A review run cites an article that the user knows is out of date.
