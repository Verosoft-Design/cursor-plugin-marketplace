#!/usr/bin/env bash
# Thin wrapper that calls render-findings.py.
# Usage:
#   <al-code-review JSON output> | scripts/render-findings.sh
#   scripts/render-findings.sh path/to/findings.json
set -euo pipefail
PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
exec python3 "${PLUGIN_ROOT}/scripts/render-findings.py" "$@"
