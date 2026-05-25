---
bc-version: [all]
domain: api
keywords: [api-page, apipublisher, apigroup, apiversion, odata, verosoft, tag]
technologies: [al]
countries: [w1]
application-area: [all]
---

# TAG API pages use the verosoftdesign/tag/v1.0 OData triplet

## Description

Every TAG API page declares the same publisher, group, and version triplet: `APIPublisher = 'verosoftdesign'`, `APIGroup = 'tag'`, and `APIVersion = 'v1.0'`. Entity names are camelCase singular (`keySafe`, `workOrder`); entity-set names are PascalCase plural (`KeySafes`, `WorkOrders`); field names exposed via the page are camelCase (`serialNo`, `masterLock`). Every API page declares `ODataKeyFields = SystemId`, `DelayedInsert = true`, and the four standard system fields first in the repeater (`id` mapped to `Rec.SystemId`, `systemCreatedAt`, `systemModifiedAt`, plus `lastModifiedDateTime` where applicable). The resulting OData URL is `/api/verosoftdesign/tag/v1.0/companies({companyId})/<EntitySetName>`.

## Best Practice

When adding a new TAG API page, copy the template from an existing one (for example `Page 23085760 - TAG API Key Safes.al`) and change only the entity name, object ID (must be in `23085634..23085783`), and field list. Keep the triplet, key fields, permission flags (`InsertAllowed`, `ModifyAllowed`, `DeleteAllowed`), and the four system fields exactly as shown.

## Anti Pattern

Bumping `APIVersion` to `v2.0` without coordinating across the entire TAG API surface (consumers break), changing the publisher or group string per page (the OData URL becomes inconsistent), or omitting the system fields from the repeater (consumers lose the standard BC entity identifier).
