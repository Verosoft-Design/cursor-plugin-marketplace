---
name: al-apply-rulesets
description: Drop Microsoft's official BCApps analyzer rulesets into the current AL workspace and wire AL-Go and VS Code to point at them. Use to align a project with Microsoft's own quality bar — every analyzer rule is an Error unless explicitly silenced for a documented reason.
disable-model-invocation: true
---

# Apply Microsoft canonical analyzer rulesets

Copies the 9 BCApps ruleset files vendored in `<plugin>/content/bcapps-rulesets/` into the user's repo, then wires AL-Go and VS Code to consume them.

The pinned source SHA is in `<plugin>/content/PINNED.json` → `bcapps.ref`. Re-pin with `/bcq-update` (Phase 4 command) or by re-running `<plugin>/scripts/vendor-bcapps.sh --latest`.

## What gets copied

| File                           | Lines  | Purpose                                                                              |
| ------------------------------ | ------ | ------------------------------------------------------------------------------------ |
| `ruleset.json`                 | 83     | Master ruleset for shipped apps. Composes the other 6. Has 10 documented exceptions. |
| `Analyzer.ruleset.json`        | 4 000  | Every analyzer rule set to `Error` (zero exceptions).                                |
| `AppSourceCop.ruleset.json`    | 4 015  | All AppSourceCop rules to `Error`, with 14 documented exceptions.                    |
| `CodeCop.ruleset.json`         | 4 004  | All CodeCop rules to `Error`, with 3 documented exceptions.                          |
| `PTECop.ruleset.json`          | 4 010  | All PTECop rules to `Error`, with 9 documented exceptions.                           |
| `UICop.ruleset.json`           | 4 003  | All UICop rules to `Error`, with 2 documented exceptions.                            |
| `Compiler.ruleset.json`        | 40 002 | Every compiler diagnostic to `Error`, with 2 documented exceptions.                  |
| `internal.module.ruleset.json` | 33     | Variant for unshipped, internal modules (silences AppSource manifest rules).         |
| `minorrelease.ruleset.json`    | 25     | Variant for minor releases (re-promotes 3 runtime-breaking-change rules).            |

## Preflight

1. Confirm the cwd is an AL workspace (`app.json` exists somewhere in the tree, or `.AL-Go/settings.json`).
2. Decide the destination — typical:
   - Single-project repo → `rulesets/` at the project root.
   - Multi-project AL-Go repo → `rulesets/` at the repo root (referenced by every `.AL-Go/settings.json` via relative path).
3. Confirm with the user whether to use:
   - `ruleset.json` (default — for AppSource-shipping or PTE-shipping apps)
   - `internal.module.ruleset.json` (for modules bundled into a larger app, not shipped separately)
   - `minorrelease.ruleset.json` (for minor-release branches with stricter event/procedure rules)

## Step 1 — Copy files

```bash
# From plugin content dir to user workspace
DEST="<workspace>/rulesets"
mkdir -p "$DEST"
cp <plugin>/content/bcapps-rulesets/*.json "$DEST/"
```

(The agent should resolve `<plugin>` from the plugin's installed location and `<workspace>` from the user's repo root.)

## Step 2 — Wire AL-Go to use the rulesets

Edit `.AL-Go/settings.json` (or for multi-project repos, each project's settings):

```json
{
  "enableCodeCop": true,
  "enableAppSourceCop": true,
  "enablePerTenantExtensionCop": true,
  "enableUICop": true,
  "enableCodeAnalyzersOnTestApps": true,
  "rulesetFile": "../rulesets/ruleset.json"
}
```

For internal-module mode, point at `internal.module.ruleset.json` instead. The path is RELATIVE from the project's `.AL-Go/settings.json` to the ruleset file — adjust depth as needed.

For multi-project BCApps-style repos (e.g. one project per module), the BCApps pattern uses a single rulesets folder at the repo root and each project points at it relatively:

```json
"rulesetFile": "../../../rulesets/ruleset.json"
```

## Step 3 — Wire VS Code to use the rulesets

Edit `.vscode/settings.json`:

```json
{
  "al.ruleSetPath": "./rulesets/ruleset.json",
  "al.codeAnalyzers": [
    "${CodeCop}",
    "${AppSourceCop}",
    "${PerTenantExtensionCop}",
    "${UICop}"
  ],
  "al.enableCodeAnalysis": true,
  "al.enableCodeActions": false
}
```

(The full BCApps `DefaultSettings.json` is available via `/al-apply-vscode-defaults`.)

## Step 4 — Verify

Run `/al-compile` with the analyzers enabled:

```json
{
  "enableCodeAnalysis": true,
  "codeAnalyzers": [
    "${CodeCop}",
    "${AppSourceCop}",
    "${PerTenantExtensionCop}",
    "${UICop}"
  ]
}
```

A clean compile means the rulesets are wired. A flood of new errors means the project was not previously held to Microsoft's bar — walk through the diagnostics and either fix them, suppress them with documented justifications (mirror BCApps' format), or pin to `internal.module.ruleset.json` if appropriate.

## What the exceptions look like (BCApps' own justifications)

Reproduced verbatim from `content/bcapps-rulesets/ruleset.json`:

```json
"rules": [
  { "id": "AS0023", "action": "Warning", "justification": "Needed to allow for BigInteger entry nos." },
  { "id": "AS0077", "action": "None",    "justification": "Adding a var modifier in events should be allowed in main, as it only will break the runtime behavior of extensions subscribing to it when used in hotfix scenarios." },
  { "id": "AS0138", "action": "None",    "justification": "TODO(#572306) - This will require a multi-release effort." },
  { "id": "AS0146", "action": "Warning", "justification": "Needed to allow for BigInteger entry nos." },
  ...
]
```

When suppressing a rule for the consuming repo, mirror this format: an explicit `"justification"` field is required for every override.

## Customization

For repo-specific exceptions, do NOT edit the Microsoft rulesets in `rulesets/` directly (they get overwritten by `/bcq-update` and `vendor-bcapps.sh --latest`). Instead, create a `custom.ruleset.json` next to them that INCLUDES `ruleset.json` and adds the local overrides:

```json
{
  "name": "Custom ruleset for <PublisherName>",
  "description": "Inherits BCApps canonical ruleset, adds local overrides.",
  "generalAction": "Error",
  "includedRuleSets": [{ "action": "Error", "path": "./ruleset.json" }],
  "rules": [
    {
      "id": "AA0234",
      "action": "None",
      "justification": "This repo is opt-in for missing tooltips; codefix incoming."
    }
  ]
}
```

Then point AL-Go and VS Code at `custom.ruleset.json`.

## Source

Vendored from `microsoft/BCApps` at the SHA pinned in `<plugin>/content/PINNED.json`. License: MIT. The 9 files together form the de-facto Microsoft AL quality bar — every Microsoft module in the System Application is built with `ruleset.json` and the `internal.module.ruleset.json` overlay.
