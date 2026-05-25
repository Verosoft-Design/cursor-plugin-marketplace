---
name: al-privacy-review
description: Review AL code for privacy/GDPR issues using BCQuality's curated privacy knowledge plus BCApps' MIT-licensed privacy review prompt. Detects missing or wrong DataClassification on PII fields, PII leakage into Session.LogMessage text or FeatureTelemetry.CustomDimensions, StrSubstNo wrapping that defeats error-text PII stripping, and other BC-specific privacy footguns. Explicitly excludes test code (test data is synthetic).
---

# AL Privacy Review (leaf)

This skill is the Cursor adapter for BCQuality's `al-privacy-review` leaf skill.

## Authoritative spec

Read `<plugin>/content/bcquality/microsoft/skills/review/al-privacy-review.md` in full. It declares the canonical Source → Relevance → Worklist → Action pattern for the privacy domain.

Also read `<plugin>/content/bcapps-review-prompts/privacy.md` — the MIT-licensed BCApps AI review prompt for privacy (~21 KB). Both feed the worklist.

## Apply contract rules

Load `bcquality-do-contract`, `bcquality-read-contract`, and `al-mcp-usage`.

## Source

Read every knowledge file under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/privacy/*.md`. Today:

- 17+ files under `microsoft/knowledge/privacy/`. Includes important _anti-false-positive_ articles: `data-classification-is-table-field-property.md`, `in-memory-data-not-a-privacy-concern.md`, `page-display-is-not-a-privacy-concern.md` — these prevent the agent from over-flagging non-issues.
- Any community/custom files under the same domain.

## Relevance

Filter by frontmatter per the READ contract.

## Worklist signal tokens (from upstream skill, verbatim)

`DataClassification`, `CustomerContent`, `EndUserIdentifiableInformation`, `EndUserPseudonymousIdentifiers`, `SystemMetadata`, `ToBeClassified`, `PrivacyNotice`, `GetLastErrorText`, `TelemetryScope`, `FeatureTelemetry`, `CustomDimensions`, `LogUsage`, `LogUptake`, `LogError`, `HybridSL`, `HybridGP`, `HybridBC`.

Weight toward tables and tableextensions, codeunits calling `Error`, `Session.LogMessage`, `FeatureTelemetry`, outgoing HTTP requests, migration codeunits, IsolatedStorage I/O.

**EXCLUDE test code, test libraries, test helper code, files under `test/Test/Tests` paths, and objects with `Subtype = Test`** — test data is synthetic and does not ship to customers. This exclusion is mandated by the upstream skill.

Resolve layer precedence; suppressed files go into `suppressed[]`.

## Action

Same severity / confidence rules as al-performance-review.

`blocker` ONLY for documented telemetry-classification rules or GDPR-adjacent data-handling requirements.

Pay special attention to the anti-false-positive articles — flag `info`-severity reminders to the reviewer when the diff looks like it might trigger an over-flag (temp tables, in-memory data, page DataClassification).

## Output

Single JSON document conforming to the DO output contract.
