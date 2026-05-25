#!/bin/sh
# Probes for the AL MCP binary on PATH. Writes a single-line status to stdout.
# Always exits 0 — the probe is a hint, never a hard failure.
#
# Output formats:
#   altool:<version>   altool is on PATH (typically from the VS Code AL Language extension)
#   al:<version>       al is on PATH but altool is not (typically from the NuGet
#                      Microsoft.Dynamics.BusinessCentral.Development.Tools package)
#   missing            neither binary is on PATH
#
# The plugin's mcp.json is configured to invoke `altool launchmcpserver`. When
# the probe reports `al:*`, the user has the NuGet variant and either needs an
# `altool` shim/alias or an mcp.json edit. The /al-setup command handles both.

set -eu

if command -v altool >/dev/null 2>&1; then
    VERSION="$(altool --version 2>/dev/null | head -n1 || echo unknown)"
    printf 'altool:%s\n' "$VERSION"
elif command -v al >/dev/null 2>&1; then
    VERSION="$(al --version 2>/dev/null | head -n1 || echo unknown)"
    printf 'al:%s\n' "$VERSION"
else
    printf 'missing\n'
fi
