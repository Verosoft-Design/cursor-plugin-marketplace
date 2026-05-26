---
name: al-setup
description: Diagnose and (with explicit user permission) install the AL MCP prerequisites. Use when the session-start context reports AL MCP is missing, when an AL MCP tool call fails because altool/al is not on PATH, or before any /al-* command is used for the first time on a fresh machine.
disable-model-invocation: true
---

# AL MCP setup

Guide the user through diagnosing and (with explicit confirmation) installing the prerequisites for the AL MCP server.

## Step 1 — Diagnose

Run the probe script at `<plugin-root>/scripts/check-altool.py` using `python3`. To find the plugin root:

- Look at this command file's path. The plugin root is the folder containing `.cursor-plugin/plugin.json`, `mcp.json`, and the `scripts/` folder. Typical locations are `~/.cursor/plugins/local/business-central-al/`, `~/.cursor/plugins/<marketplace>/business-central-al/`, or inside the user's cursor-plugin-marketplace repo.
- If you cannot resolve the path, ask the user where the plugin is installed.

The probe writes one of three values to stdout:

- `altool:<version>` — `altool` is on PATH. The plugin's `mcp.json` is already configured for this. **Skip to Step 4** to confirm.
- `al:<version>` — the NuGet `al` binary is on PATH but `altool` is not. The plugin's `mcp.json` expects `altool`. **Go to Step 3** (mismatch fix).
- `missing` — neither is on PATH. **Go to Step 2** (install).

Report the probe result to the user before continuing.

## Step 2 — Install (when neither altool nor al is present)

Ask the user which install method they prefer. Present both options clearly and wait for an explicit choice.

### Option A — VS Code AL Language extension (recommended)

Provides `altool` — matches the plugin's default `mcp.json` exactly. Best when the user already has VS Code installed.

Prerequisite check: `command -v code` must succeed (the VS Code CLI must be on PATH).

If `code` is on PATH, ask the user explicitly:

> About to run: `code --install-extension ms-dynamics-smb.al`
>
> This installs the Microsoft AL Language extension into VS Code. Proceed?

Only run the command after the user replies "yes" (or an equivalent affirmation).

After install, the `altool` binary lives at:

- macOS/Linux: `~/.vscode/extensions/ms-dynamics-smb.al-<version>/bin/<os>/altool`
- Windows: `%USERPROFILE%\.vscode\extensions\ms-dynamics-smb.al-<version>\bin\win64\altool.exe`

The user MUST add that `bin/<os>/` folder to PATH. Show them the exact line to add to `~/.zshrc` (zsh) or `~/.bashrc` (bash):

```sh
export PATH="$HOME/.vscode/extensions/ms-dynamics-smb.al-<version>/bin/darwin:$PATH"
```

(Resolve `<version>` and `<os>` by listing `~/.vscode/extensions/` and finding the actual folder name.)

On Windows, instruct them to add the path through System Properties → Environment Variables → User PATH.

With explicit confirmation, offer to append the export line to their shell rc file. After the path change, ask them to restart Cursor (or open a new shell session) and re-run `/al-setup` to verify.

If `code` is not on PATH, tell the user to either install VS Code first or pick Option B.

### Option B — AL Development Tools NuGet package

Provides `al` (not `altool`) — requires the Step 3 mismatch fix. Best for headless agents or users who don't want VS Code.

Prerequisite check: `dotnet --list-sdks` must list a `8.x` SDK.

If .NET 8 is present, ask the user explicitly:

> About to run: `dotnet tool install --global Microsoft.Dynamics.BusinessCentral.Development.Tools`
>
> This installs the AL Development Tools as a global dotnet tool, placing the `al` binary in `~/.dotnet/tools`. Proceed?

Only run after explicit confirmation.

After install, the `al` binary lands in `~/.dotnet/tools/` (which `dotnet tool install --global` adds to PATH automatically). Proceed to **Step 3** to fix the `altool`/`al` mismatch.

If `dotnet --list-sdks` shows no 8.x SDK, tell the user to install .NET 8 SDK from <https://dotnet.microsoft.com/download/dotnet/8.0> first, then re-run `/al-setup`.

## Step 3 — Fix the altool/al mismatch (when only `al` is present)

The plugin's `mcp.json` runs `altool launchmcpserver`, but the user has `al`. Present both fixes and let the user choose.

### Fix A — Create an `altool` shim (recommended)

Survives plugin updates. Does not touch the plugin files.

On macOS/Linux, with explicit confirmation:

> About to run:
>
> ```sh
> mkdir -p ~/.local/bin
> ln -sf "$(command -v al)" ~/.local/bin/altool
> ```
>
> This creates a symlink so `altool` resolves to the NuGet `al` binary. You will also need `~/.local/bin` on your PATH. Proceed?

After the symlink is created, check whether `~/.local/bin` is on PATH (`echo "$PATH" | tr ':' '\n' | grep -Fx "$HOME/.local/bin"`). If not, offer to append the export line to the user's shell rc.

On Windows, instruct the user to create a `.cmd` shim at a folder already on PATH (e.g. `%USERPROFILE%\bin\altool.cmd`) containing:

```cmd
@echo off
al %*
```

### Fix B — Edit mcp.json

Faster but gets overwritten when the plugin is updated from the marketplace. Warn the user before suggesting this.

With explicit confirmation, edit `<plugin-root>/mcp.json` and change `"command": "altool"` to `"command": "al"`. Print the change diff so the user sees exactly what was modified.

## Step 4 — Workspace project-path injection (highly recommended)

By default the plugin's `mcp.json` runs `altool launchmcpserver --transport stdio` with **no positional `<projects>` argument**, so every new Cursor session starts the AL MCP with zero loaded projects. The agent then has to call `al_addproject` before any tool that operates on AL code (`al_build`, `al_compile`, `al_symbolsearch`, etc.) will work. That's an extra round-trip every single session.

The fix is a tiny workspace-level `mcp.json` that re-declares the `al` server with `${workspaceFolder}` passed in as a positional argument. Cursor expands `${workspaceFolder}` to the folder that **contains** the `.cursor/mcp.json`, so the AL MCP launches with the current AL project already loaded.

### When to offer this

Only when **all** of these are true:

1. The current workspace has an `app.json` at its root (it's an AL project — run `test -f "$PWD/app.json"`).
2. There's no existing `.cursor/mcp.json` in the workspace (`test -f .cursor/mcp.json` returns false), OR the existing file does not define an `al` server.
3. The probe from Step 1 reported `altool:<version>` (the AL MCP is actually working).

If any check fails, skip this step entirely.

### What to ask

> About to write `<workspace>/.cursor/mcp.json` with this content:
>
> ```json
> {
>   "mcpServers": {
>     "al": {
>       "command": "altool",
>       "args": [
>         "launchmcpserver",
>         "--transport",
>         "stdio",
>         "${workspaceFolder}"
>       ]
>     }
>   }
> }
> ```
>
> This overrides the plugin's default `al` server for this workspace only, so every new Cursor session starts with the project already loaded. No more manual `al_addproject` calls. Proceed?

Only write the file after explicit confirmation.

### Edge cases

- If `.cursor/mcp.json` already exists in the workspace but defines a different server (e.g. a project-specific MCP), **merge** the `al` entry in rather than overwriting — read the existing JSON, add the `al` key under `mcpServers`, write it back. Print the diff before writing.
- If `.cursor/mcp.json` already defines an `al` server, leave it alone and tell the user it's already wired up.
- If the user declines, suggest they re-run `/al-setup` later when they're ready to make sessions less chatty.

### After writing

Tell the user:

- The new `.cursor/mcp.json` takes effect **after the next full Cursor restart** (Cmd+Q + reopen, not just window reload — MCP servers are launched at process start). A window reload usually picks up MCP config changes but not always; full restart is the reliable signal.
- They can verify it worked by running `/al-symbols` (or any AL MCP tool) in the first turn of a new session — it should succeed without an `al_addproject` round-trip first.

## Step 5 — Verify

After any install or fix, re-run the probe from Step 1. Expect `altool:<version>`. Tell the user the AL MCP is now ready and they can use:

- `/al-symbols` — download symbol packages
- `/al-symbol-search` — search AL symbols
- `/al-compile` — fast validation
- `/al-build` — build the `.app`
- `/al-publish-sandbox` — deploy to a BC environment

If the probe still reports `missing` or `al:*` after a fix, the most common cause is that the new PATH is not visible to the already-running Cursor process. Ask the user to fully restart Cursor (not just reload the window) and try again.

## Safety rules

- NEVER run an install command, alias creation, symlink, or file edit without first showing the exact command, then getting explicit user confirmation in the current turn.
- NEVER invoke `sudo` automatically. If a step needs elevated permissions, surface that requirement and let the user decide.
- If the user declines an install or fix, print the manual instructions for that option and stop. Do not push or retry with different framing.
- After every action (install, alias, file edit), report back exactly what was changed and where, so the user has an audit trail.
