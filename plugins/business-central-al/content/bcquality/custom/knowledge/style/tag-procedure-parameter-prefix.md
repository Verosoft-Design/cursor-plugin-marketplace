---
bc-version: [all]
domain: style
keywords: [procedure, parameter, naming, prefix, tag]
technologies: [al]
countries: [w1]
application-area: [all]
---

# TAG procedure parameters are prefixed with p

## Description

TAG codeunits prefix every procedure parameter with the lowercase letter `p`. Examples include `procedure ProcessEquipment(pEquipmentID: Code[20]; pProcessDate: Date)`. The prefix disambiguates parameters from local variables at every call site and at every use within the procedure body. This overrides the BCApps convention (which uses no prefix and disambiguates via type-name suffixes instead).

## Best Practice

Name every parameter `p` followed by `PascalCaseName` regardless of type. Examples are `pCode`, `pEquipmentRec`, and `pIsActive`. The matching local variable, if any, drops the `p` (`EquipmentRec` as a local versus `pEquipmentRec` as a parameter). Boolean parameters still read as a question (`pIsActive`, `pHasPermission`).

## Anti Pattern

Naming a parameter with no prefix in a TAG codeunit (BCApps style). Readers cannot tell from the usage site whether a name is a parameter or a local. Mixing prefixed and unprefixed parameters in the same codeunit is even worse. It signals no convention and degrades to noise.
