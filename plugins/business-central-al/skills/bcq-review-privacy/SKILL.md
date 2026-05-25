---
name: bcq-review-privacy
description: Run only the AL privacy review (skip the other 5 leaves and the super-skill self-review). Use when the user specifically wants privacy feedback — typically when adding new PII-bearing fields, changing telemetry, or auditing DataClassification.
disable-model-invocation: true
---

# Targeted: privacy review

Dispatches `al-entry` with a goal explicitly naming "privacy". Entry's `narrower-sub-skill-selected` precedence selects `al-privacy-review`.

## Inputs

PR diff, file path, or object list. Note: the privacy leaf explicitly EXCLUDES test code, test libraries, and `Subtype = Test` objects (test data is synthetic).

## Output

A single JSON document per the DO contract from `al-privacy-review` only.

The leaf reads:

- `<plugin>/content/bcquality/microsoft/skills/review/al-privacy-review.md` (authoritative spec).
- Knowledge files under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/privacy/`.
- `<plugin>/content/bcapps-review-prompts/privacy.md`.

## When to prefer this

- Adding new fields to tables that might carry PII.
- Changing telemetry — `Session.LogMessage` and `FeatureTelemetry` calls.
- Reviewing error-handling code for `StrSubstNo`-wrapping that defeats PII stripping.
- Auditing `DataClassification` choices on a recently-added table.

## Important: anti-false-positive articles

The privacy domain has several articles specifically to PREVENT over-flagging:

- `data-classification-is-table-field-property.md` — page fields do NOT need DataClassification.
- `in-memory-data-not-a-privacy-concern.md` — temp tables, dictionaries, lists do not need classification.
- `page-display-is-not-a-privacy-concern.md` — displaying data on a page is NOT a privacy violation by itself.

When the diff appears to trigger one of these, the leaf should emit an `info`-severity reminder citing the relevant article rather than a spurious finding.
