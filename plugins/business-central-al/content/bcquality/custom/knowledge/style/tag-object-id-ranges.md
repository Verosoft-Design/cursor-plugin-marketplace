---
bc-version: [all]
domain: style
keywords: [object-id, id-range, verosoft, tag, appsource, as0084]
technologies: [al]
countries: [w1]
application-area: [all]
---

# TAG object IDs must fall in the Verosoft-allocated ranges

## Description

Verosoft Design has two allocated object ID ranges for The Asset Guardian (TAG) app: `70015000..70016999` for primary objects (tables, codeunits, pages, reports, enums, queries, XMLports) and `23085634..23085783` for API pages and their related objects. Every new TAG object MUST land inside one of these ranges; objects outside the range collide with AppSource neighbors and trip AS0084 on AppSourceCop.

## Best Practice

For a new TAG table, codeunit, page (non-API), report, enum, query, or XMLport, pick the next free ID in `70015000..70016999`. For a new TAG API page (and its supporting page or codeunit if any), pick from `23085634..23085783`. Document the allocation in the project's running ID registry.

## Anti Pattern

Reusing IDs outside the two allocated ranges, or sampling from Microsoft's system range (anything below `70000000`). Such IDs collide with other AppSource apps and will be rejected by AppSourceCop on the next release build.
