---
bc-version: [all]
domain: style
keywords: [object-name, prefix, affix, tag, appsourcecop, as0011]
technologies: [al]
countries: [w1]
application-area: [all]
---

# TAG objects must use the TAG prefix in their internal name

## Description

AppSourceCop rule AS0011 (mandatory affixes) requires every object name in an AppSource extension to carry the publisher's affix. For TAG, the affix is the word `TAG` followed by a space, used as a prefix on every object name. Examples are `table 70016325 "TAG Key Safe"`, `page 23085760 "TAG Key Safe List"`, `codeunit 70015921 "TAG Evaluate AutoPlan"`, and `enum 70015900 "TAG Equipment Status"`. The `app.json` field `appSourceCopMandatoryAffixes` is set to `["TAG "]` (with trailing space) to enforce this at build time.

## Best Practice

Prefix every new object's internal name with `TAG ` (capital letters, single trailing space). The same applies to table extensions, page extensions, and enum extensions even though they extend Microsoft-owned objects. The extension object's name still carries the affix.

## Anti Pattern

Naming an object `"Key Safe"` (no prefix), `"TAG_KeySafe"` (no space), `"tag Key Safe"` (lowercase), or using a different affix like `"VSD Key Safe"`. All trip AS0011 and block the AppSource build.
