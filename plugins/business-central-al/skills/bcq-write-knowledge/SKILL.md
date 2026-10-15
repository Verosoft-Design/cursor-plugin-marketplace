---
name: bcq-write-knowledge
description: Author a new BCQuality knowledge article for the plugin's custom layer. Guides the user through the "is this a knowledge file?" and admission tests, frontmatter authoring, sample-file links, and the pre-PR checklist, then runs the vendored upstream validator. Use when codifying a repo-specific or partner-specific BC convention, or a false-positive guard, that the agent should respect on future reviews.
---

# BCQuality: author a custom-layer knowledge file

This skill walks the user through writing a new knowledge article at `<plugin>/content/bcquality/custom/knowledge/<domain>/<slug>.md`.

## Authoritative spec

Read `<plugin>/content/bcquality/skills/write.md` in full. It defines:

- *Is this a knowledge file?*: BC facts go in knowledge files, never in skill prose. Negative knowledge (false-positive guards) is first-class.
- The admission test: "would a capable LLM get this wrong without the file?" See also `<plugin>/content/bcquality/docs/contributing.md#what-belongs-here`.
- Atomicity (one concern per file), the target length (under 100 lines, ideally under 50), and sources for platform claims.
- Choosing `bc-version`, including the open-ended `[N..]` range.
- Choosing a layer, and the fork precondition for `/custom/`.
- The pre-PR checklist.

Apply the `bcquality-write-contract` rule and the `bcquality-read-contract` rule.

## Step 1: Confirm intent and apply the tests

Ask the user to state the concern in one sentence, then check:

1. **Is it a BC fact, not skill mechanics?** If the user wants a review to stop flagging something, or to start flagging it, the remedy is a knowledge file, not a skill edit.
2. **Admission test:** if this file did not exist, would a capable LLM reviewing or generating BC code make a mistake the file would have prevented? A false positive the reviewer keeps raising counts as such a mistake.

If both answers are not "yes" (for example, generic engineering advice, or a BC mechanic the model already knows), do NOT author the file. Explain why, and suggest putting the convention in the repo's CLAUDE.md instead.

Good candidates:

- "TAG object IDs must fall in `70015000..70016999`": publisher-specific, so an LLM cannot guess it.
- "TAG procedure parameters are prefixed with `p`": a repo convention that contradicts the BCApps default.
- "Pattern X in our framework is not a defect, because codeunit Y already guards it": a negative clarification that suppresses a recurring false positive.

Poor candidates (do NOT author): "Use HTTPS instead of HTTP." "Don't hardcode secrets." "Keep transactions short."

**Fork precondition.** The plugin's custom layer is the right home for partner and customer rules. It is local content that the vendor script never overwrites, and nothing in it is ever sent to `microsoft/BCQuality`. Never propose custom content as an upstream PR; upstream auto-closes those. If the guidance is genuinely shareable, contribute it upstream to the layer that owns its domain instead (see write.md *Choosing a layer*).

## Step 2: Gather frontmatter

All 6 fields are required, and no others are allowed:

- **`bc-version`**: default `[all]`. Use `[26, 27, 28]` or `[26..28]` only for genuinely version-gated guidance. For a feature introduced in version N that is not expected to go away, use the open-ended `[N..]`.
- **`domain`**: MUST equal the folder name (validator R27). Use a domain that a review leaf sources, or no review will load the article: `performance`, `security`, `privacy`, `upgrade`, `style`, `ui`, `error-handling`, `events`, `interfaces`, `breaking-changes`, `web-services`, `testing`, `data-modeling`, `query`, `reporting`, `appsource`, `telemetry`, `scm`, `finance`, `agents`. API page conventions belong in `web-services`.
- **`keywords`**: 3 to 10 lowercase kebab-case tags that engineers and agents would search for. Leaves match these against diff tokens.
- **`technologies`**: usually `[al]`. Add `javascript` for control add-ins. `all` is not allowed.
- **`countries`**: `[w1]` for worldwide; otherwise lowercase ISO 3166 alpha-2 codes.
- **`application-area`**: `[all]` is the usual default; otherwise list specific areas (`finance`, `manufacturing`, `jobs`, `warehousing`, `service`).

## Step 3: Pick a path

`<plugin>/content/bcquality/custom/knowledge/<domain>/<slug>.md`, where `<slug>` is descriptive kebab-case (for example `tag-object-id-ranges`, not `obj-ids`).

Under layer precedence, an article here OVERRIDES a contradicting microsoft or community article. The displaced article appears in the leaf's `suppressed[]` with `reason: "layer-precedence"`. Non-conflicting guidance is additive.

## Step 4: Write the body

- `## Description` (mandatory): 2 to 5 sentences. This is the primary retrieval target and feeds the knowledge index's one-line description, so write it as if a skill decides whether to load the file from this text alone.
- `## Best Practice` and `## Anti Pattern` (recommended, normative). For a negative clarification, Best Practice says what NOT to flag and why, and Anti Pattern describes the mistaken review finding.
- Optional non-normative sections such as `## References` (link authoritative sources for platform claims) and `## See also`.

Hard rules (validator-enforced): `## Description` is required, there are NO fenced code blocks in the article body, and the file is at most 100 lines.

## Step 5: Optional sample files

Ship AL code as sibling files: `<slug>.good.al` and/or `<slug>.bad.al`, or `.js` for control add-in samples. Fenced code is allowed there. Link each sample from the body with a relative Markdown link that keeps the backticked filename, for example `` [`<slug>.good.al`](<slug>.good.al) ``. Every linked sample must exist.

## Step 6: Validate

Run the vendored upstream validator. It needs PyYAML; set `PYTHON` if the default `python3` lacks it.

```bash
python3 <plugin>/scripts/validate-bcquality-frontmatter.py --root <plugin>/content/bcquality
```

The summary line must read `Validator: 0 error(s), …`. Warnings, such as more than 10 keywords, do not fail. Fix every error before relying on the article.

## Step 7: Record it

If this is a brand-new custom article rather than a port of an existing convention, note it in the plugin's `CHANGELOG.md` so future maintainers know about it (the design history of the TAG layer is in `docs/business-central-al-rebuild/TAG_CUSTOM_LAYER.md` of the Cursor repo).

## After authoring

The article is consumable immediately. The matching leaf (for example `al-style-review` for `domain: style`) sources `custom/knowledge/<domain>/` automatically, and `al-entry` rebuilds the knowledge index on the next run when `pwsh` is available. No skill changes are needed. If the article contradicts an upstream article, the upstream one appears in that leaf's `suppressed[]`.
