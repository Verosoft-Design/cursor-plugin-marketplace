---
bc-version: [all]
domain: upgrade
keywords: [preprocessor, clean24, no-series, version-compatibility, tag]
technologies: [al]
countries: [w1]
application-area: [all]
---

# Use CLEAN preprocessor symbols to bridge old and new BC APIs in TAG

## Description

TAG supports multiple BC platform versions in a single source tree using the CLEAN preprocessor symbols (`CLEAN18`, `CLEAN19`, `CLEAN20`, `CLEAN22`, `CLEAN23`, `CLEAN24`). The canonical use is in `OnInsert` triggers that need the modern `Codeunit "No. Series"` (BC 24+) on new builds and the legacy `Codeunit NoSeriesManagement` on older builds. The build defines the symbol matching the target BC major version. Code branches on `#if CLEAN24` then `#else` then `#endif` so the same source compiles cleanly against either API.

## Best Practice

Whenever TAG calls a renamed or replaced platform codeunit (No. Series is the canonical example), wrap the import and call in `#if CLEAN<N>` then `#else` then `#endif`. Declare the symbol name in `app.json` `preprocessorSymbols` or in AL-Go's per-buildMode conditional settings. Resolve obsolete branches and remove the `#if` once TAG drops support for the older version.

## Anti Pattern

Calling the modern API directly without an `#if` guard (older builds break), or leaving stale `#if CLEAN18` branches in the codebase after support for BC 18 is dropped. The branches are never compiled and silently diverge.
