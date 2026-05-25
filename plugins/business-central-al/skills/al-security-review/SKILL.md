---
name: al-security-review
description: Review AL code for security issues using BCQuality's curated security knowledge plus BCApps' MIT-licensed security review prompt. Detects misuse of SecretText, NonDebuggable-missing on credential code, IsolatedStorage access scope errors, IntegrationEvent var-parameter bypass patterns, permission-set wildcarding, ValidateTableRelation=false on user input, and other BC-specific security footguns.
---

# AL Security Review (leaf)

This skill is the Cursor adapter for BCQuality's `al-security-review` leaf skill.

## Authoritative spec

Read `<plugin>/content/bcquality/microsoft/skills/review/al-security-review.md` in full. It declares the canonical Source → Relevance → Worklist → Action pattern for the security domain.

Also read `<plugin>/content/bcapps-review-prompts/security.md` — the MIT-licensed BCApps AI review prompt for security (~23 KB). It complements the BCQuality knowledge files with bad/good AL code examples. Both feed the worklist.

## Apply contract rules

Load `bcquality-do-contract`, `bcquality-read-contract`, and `al-mcp-usage`.

## Source

Read every knowledge file under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/security/*.md`. Today:

- 18+ files under `microsoft/knowledge/security/` (canonical examples: `secrettext-for-credentials.md`, `integrationevent-var-parameter-bypasses-security-guards.md`, `integrationevent-must-not-expose-secrets.md`, `inherent-permissions-minimal-grant.md`, `nondebuggable-required-when-unwrapping-secrettext.md`).
- Community files under `community/knowledge/security/`.
- Any custom-layer files under `custom/knowledge/security/`.

## Relevance

Filter by frontmatter per the READ contract (same dimensions as al-performance-review).

## Worklist signal tokens (from upstream skill, verbatim)

`IsolatedStorage`, `SetEncrypted`, `OAuth2`, `SecretText`, `Unwrap`, `NonDebuggable`, `Password`, `Token`, `HttpClient`, `Uri`, `AreURIsHaveSameHost`, `IsValidURIPattern`, `RecordRef`, `RecordId`, `Open`, `IntegrationEvent`, `SkipValidation`, `HasAccess`, `Permission`, `UserSecurityId`, `Commit`.

Weight toward permission sets, codeunits handling authentication/authorization, IsolatedStorage usage, OAuth2 flows, web service endpoints, API pages, event publishers, RecordRef helpers.

Resolve layer precedence; suppressed files go into `suppressed[]`.

## Action

Same severity / confidence rules as al-performance-review.

`blocker` ONLY when the knowledge file documents a platform-level guarantee — for example documented secret-handling rules, permission-model invariants, or data-protection requirements.

Flag any `var Boolean` parameter on an `[IntegrationEvent]` whose name reads like a security decision (`HasAccess`, `IsAllowed`, `SkipValidation`, `BypassCheck`, `IsAuthorized`) as a `major` finding citing `integrationevent-var-parameter-bypasses-security-guards.md`.

## Output

Single JSON document conforming to the DO output contract.
