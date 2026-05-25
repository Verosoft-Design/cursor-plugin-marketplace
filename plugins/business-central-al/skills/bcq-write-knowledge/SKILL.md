---
name: bcq-write-knowledge
description: Author a new BCQuality knowledge article for the plugin's custom layer. Guides the user through frontmatter authoring, the remedial-knowledge admission test, the pre-PR checklist, and runs the vendored upstream validator. Use when codifying a repo-specific or partner-specific BC convention that the agent should respect on future reviews.
---

# BCQuality — author a custom-layer knowledge file

This skill walks the user through writing a new knowledge article in `<plugin>/content/bcquality/custom/knowledge/<domain>/<slug>.md`.

## Authoritative spec

Read `<plugin>/content/bcquality/write.md` in full. It defines:

- The admission test ("would a modern LLM otherwise get this wrong?")
- Atomicity — one concern per file.
- The target length (under 100 lines, ideal under 50).
- Choosing `bc-version`.
- The pre-PR checklist.

Apply the `bcquality-write-contract` and `bcquality-read-contract` rules.

## Step 1 — Confirm intent and apply the admission test

Before writing anything, ask the user to articulate the concern as a single sentence. Then apply the BCQuality admission test:

> If this file did not exist, would a modern LLM reviewing or generating BC code make a mistake this file would have prevented?

If the answer is "no" — the advice is generic software-engineering guidance, or the LLM already knows the BC mechanic in question — DO NOT author the file. Surface the reasoning to the user and suggest they put the convention in a Cursor rule instead.

Good examples of remedial knowledge:

- "`SetLoadFields` must be called before filters, not after" (non-obvious ordering rule).
- "TAG object IDs must fall in `70015000..70016999`" (publisher-specific, LLM cannot guess).
- "TAG procedure parameters are prefixed with `p`" (repo convention contradicting BCApps default).

Poor examples (do NOT author):

- "Use HTTPS instead of HTTP."
- "Don't hardcode secrets."
- "Keep transactions short."

## Step 2 — Gather frontmatter

All 6 fields are required:

- **`bc-version`**: default `[all]` unless the concern is genuinely version-gated. Use `[26, 27, 28]` or `[26..28]` only with a concrete reason.
- **`domain`**: choose a standard value (`performance`, `security`, `privacy`, `style`, `ui`, `upgrade`, `testing`) or a documented additional value (`api`, `telemetry`, `pipelines`, `finance`, `supply-chain`, `manufacturing`, `jobs`).
- **`keywords`**: 3–10 lowercase-kebab-case tags engineers and agents would search for.
- **`technologies`**: usually `[al]`. Add `[javascript]` for control add-ins.
- **`countries`**: `[w1]` for worldwide; otherwise lowercase ISO-3166 alpha-2 codes.
- **`application-area`**: `[all]` is the common default; otherwise specific areas (`finance`, `manufacturing`, `jobs`, `warehousing`, `service`).

## Step 3 — Pick a path

`<plugin>/content/bcquality/custom/knowledge/<domain>/<slug>.md` where:

- `<domain>` is the chosen domain.
- `<slug>` is kebab-case, descriptive (e.g. `tag-object-id-ranges`, not `obj-ids`).

Per the layer precedence: an article here OVERRIDES same-id microsoft and community articles on conflict.

## Step 4 — Write the body

Mandatory section:

- `## Description` — 2–5 sentences. Primary retrieval target. Write it as if a skill is deciding whether to load this file based on this text alone.

Recommended normative sections:

- `## Best Practice` — the recommended approach.
- `## Anti Pattern` — what to avoid and the reasoning.

Optional non-normative sections (any `##` is permitted): `## See also`, `## Applies to`, etc. Consumers must not treat these as binding.

**Hard rules** (CI-enforced by R09–R11):

- `## Description` is required.
- NO fenced code blocks anywhere in the body. Inline `code` with single backticks is fine.
- File ≤ 100 lines.

## Step 5 — Optional sample files

If the article references AL code, ship it as sibling files:

- `<plugin>/content/bcquality/custom/knowledge/<domain>/<slug>.good.al`
- `<plugin>/content/bcquality/custom/knowledge/<domain>/<slug>.bad.al`

Sample files CAN contain AL code (no fenced-code rule there). Reference them from the article body using their relative filename in inline backticks.

## Step 6 — Validate

Run the vendored upstream validator BEFORE committing:

```bash
python3 <plugin>/scripts/validate-bcquality-frontmatter.py --root <plugin>/content/bcquality
```

The validator implements 25 rules (R01–R25). Exit 0 with no errors means the article is well-formed. Any error must be fixed before the file is useful.

## Step 7 — Update PROGRESS if applicable

If this is a fresh-from-scratch custom article (not a port of an existing convention), add a note in the plugin's `docs/business-central-al-rebuild/TAG_CUSTOM_LAYER.md` so future maintainers know about it.

## After authoring

The article is immediately consumable by `al-style-review`, `al-performance-review`, etc. — they Source from `custom/knowledge/<domain>/` automatically. No skill changes needed.

The next review run will surface findings citing the new article. If the article contradicts an upstream microsoft or community article, the loser will appear in the output's `suppressed[]` with `reason: "layer-precedence"`.
