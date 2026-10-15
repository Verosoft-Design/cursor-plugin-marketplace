---
name: al-call-graph
description: Build and query a static call graph of the project's AL apps (and optionally base-app source) with ALTool's `al graph` commands, to answer "who calls this procedure", "what can reach this internal code", "what does this change affect", including event and interface edges. Use before changing a procedure's signature or behaviour, when reviewing public API surface, or when tracing how code is reached. BC 2026 release wave 2 tooling.
argument-hint: "[object/procedure, e.g. Codeunit/TAG Order Mgt.#Release]"
---

# AL call graph

Source: Microsoft Learn, *ALTool: Graph commands* (2026). Requires AL Development Tools from BC 2026 release wave 2 (`al help graph`). Text search can't tell a call from a comment or two same-named procedures in different objects; the graph can, and it follows event subscriptions and interface implementations.

## Build (once per change set)

Keep outputs out of git, e.g. under `.algraph/` (add it to `.gitignore`).

```sh
# all apps in the repo together, so cross-app calls resolve, stitched in one step
al graph extract-whole --corpus . --out .algraph/whole --graph .algraph/graph.jsonl

# include base-app source (e.g. a shallow clone of StefanMaron/MSDyn365BC.Code.History at your version) to follow calls into Microsoft code
al graph extract-whole --corpus . --corpus ~/.cache/bc-base-app/<branch> --out .algraph/whole --graph .algraph/graph.jsonl
```

`extract-all` + `stitch` is the faster, incremental option but doesn't resolve direct calls between apps.

## Query

Selectors: `obj:<Type>/<Name>` (append `#<member>` for a procedure), `ns:<glob>`, `app:<guid>`, `access:public|internal|local|protected`, `kind:Method|Trigger|...`, `debuggable`, `elevation`; combine with `+` (and), `,` (or), `!` (not).

```sh
# who calls this procedure (impact of changing it)
al graph query --graph .algraph/graph.jsonl --to "obj:Codeunit/TAG Order Mgt.#Release" --direction callers

# concrete paths from our public API to internal code
al graph query --graph .algraph/graph.jsonl --from "access:public+app:<app id>" --to "access:internal+app:<app id>" --paths

# drop test code from the answer
... --exclude "ns:*Test*"
```

`--edge-kinds Direct,Event,Interface,Trigger` limits edge types, `--depth` bounds traversal, `--resolved-only` drops over-approximated edges. `--paths` is a capped sample: an empty path list doesn't prove unreachability; rerun without `--paths`.

## Report

List callers or paths as `Object.Procedure` with file:line, grouped by app, and say what the change would affect. For a visual, `al graph export ... --format graphml|dgml|sarif --out <file>`.
