#!/usr/bin/env python3
"""
Probes for the AL MCP binary on PATH. Writes a single-line status to stdout.
Always exits 0 — the probe is a hint, never a hard failure.

Output formats:
  altool:<version>   altool is on PATH (typically from the VS Code AL Language extension)
  al:<version>       al is on PATH but altool is not (typically from the NuGet
                     Microsoft.Dynamics.BusinessCentral.Development.Tools package)
  missing            neither binary is on PATH

The plugin's mcp.json is configured to invoke `altool launchmcpserver`. When
the probe reports `al:*`, the user has the NuGet variant and either needs an
`altool` shim/alias or an mcp.json edit. The /al-setup command handles both.
"""

import shutil
import subprocess
import sys


def get_version(binary: str) -> str:
    try:
        result = subprocess.run(
            [binary, "--version"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        first_line = (result.stdout or result.stderr or "").strip().split("\n")[0]
        return first_line or "unknown"
    except Exception:
        return "unknown"


def main() -> None:
    if shutil.which("altool"):
        version = get_version("altool")
        print(f"altool:{version}")
    elif shutil.which("al"):
        version = get_version("al")
        print(f"al:{version}")
    else:
        print("missing")


if __name__ == "__main__":
    main()
