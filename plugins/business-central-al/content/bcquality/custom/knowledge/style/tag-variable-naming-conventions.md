---
bc-version: [all]
domain: style
keywords: [variable, naming, record-prefix, vocabulary, tag]
technologies: [al]
countries: [w1]
application-area: [all]
---

# TAG record variables use the standard short-prefix vocabulary

## Description

TAG has an established vocabulary of record-variable short names so that any contributor reading any codeunit can tell at a glance what type a variable is. The canonical mapping is `EquipmentRec` or `Equipment` for `Record "TAG Equipment"`, `WOHeader` for `Record "TAG Work Order Header"`, `WOLine` for `Record "TAG Work Order Line"`, `TechRec` for technician records, `TAGSetup` for `Record "TAG Setup"`, `DMPolicy` or `DateMeterHeader` for DateMeter records, and `MaintHeader` or `TemplateRec` for maintenance templates. Variable declaration order in the var block is records, then codeunits, then pages and reports, then simple types (Integer, Decimal, Boolean), then Text and Code.

## Best Practice

When you add a new variable for one of the listed record types, use the established short prefix. When you introduce a brand-new record type, pick a short PascalCase prefix and apply it consistently across the codebase from day one.

## Anti Pattern

Inventing a new prefix per file (`Equip`, `Eq`, `TagEquip`, `EquipmentRecord`, `myEquipment`) for an already-named type, or putting Text or Code variables before Record variables in a var block. Both break the conventions that make TAG codeunits navigable.
