---
name: al-apply-vscode-defaults
description: Apply Microsoft's BCApps VS Code defaults to the current AL workspace by merging into .vscode/settings.json. Enables CodeCop / AppSourceCop / PerTenantExtensionCop / UICop, semantic highlighting, formatOnSave, and the BCApps defaults that Microsoft uses internally.
disable-model-invocation: true
---

# Apply BCApps VS Code defaults

Merges Microsoft's BCApps `DefaultSettings.json` into the user's workspace `.vscode/settings.json`. Sourced from `build/scripts/DevEnv/DefaultSettings.json` in `microsoft/BCApps`, pinned via `<plugin>/content/PINNED.json`.

## What gets applied

Verbatim from the vendored snapshot (`<plugin>/content/bcapps-defaults/DefaultSettings.json`):

```json
{
  "chat.useCustomizationsInParentRepositories": true,
  "al.codeAnalyzers": [
    "${CodeCop}",
    "${AppSourceCop}",
    "${PerTenantExtensionCop}",
    "${UICop}"
  ],
  "al.enableCodeActions": false,
  "al.enableCodeAnalysis": true,
  "al.incrementalBuild": true,
  "[al]": { "editor.semanticHighlighting.enabled": true },
  "editor.codeLens": false,
  "editor.formatOnSave": true
}
```

Setting-by-setting:

| Key                                          | Value           | Why                                                                                   |
| -------------------------------------------- | --------------- | ------------------------------------------------------------------------------------- |
| `chat.useCustomizationsInParentRepositories` | `true`          | Enables chat (Copilot/Cursor) to pick up rules and skills from parent repos.          |
| `al.codeAnalyzers`                           | the 4 analyzers | Every analyzer Microsoft runs on BCApps.                                              |
| `al.enableCodeActions`                       | `false`         | Microsoft disables AL code actions in BCApps to avoid AI-driven refactors during dev. |
| `al.enableCodeAnalysis`                      | `true`          | Analyzer runs on save.                                                                |
| `al.incrementalBuild`                        | `true`          | Speeds up `Ctrl+Shift+B` for large projects.                                          |
| `[al]` `editor.semanticHighlighting.enabled` | `true`          | Better identifier coloring in AL.                                                     |
| `editor.codeLens`                            | `false`         | Reduces visual noise in AL files.                                                     |
| `editor.formatOnSave`                        | `true`          | The AL formatter applies on save.                                                     |

## Preflight

1. Confirm cwd contains an AL workspace.
2. If `.vscode/settings.json` already exists, READ IT before merging. Preserve existing keys that don't conflict; surface conflicts to the user.

## Apply

The agent should MERGE these settings into `.vscode/settings.json` (creating the file and `.vscode/` directory if needed). Do NOT replace the whole file — preserve any keys the user has already set.

For keys in the BCApps defaults that the user has explicitly overridden (e.g. `editor.formatOnSave: false`), ask before overwriting.

## Recommended follow-up

After applying, recommend `/al-apply-rulesets` to drop in the matching analyzer rulesets and add `al.ruleSetPath` to `.vscode/settings.json`.

For VS Code AL extension version pinning, also consider setting `al.vsixFile` in `.AL-Go/settings.json` to `"default"`, `"latest"`, `"preview"`, or a specific URL — this lets the build container use a different AL Language extension version than the developer's local install.

## Source

Vendored from `microsoft/BCApps/build/scripts/DevEnv/DefaultSettings.json` at the SHA pinned in `<plugin>/content/PINNED.json`. License: MIT.
