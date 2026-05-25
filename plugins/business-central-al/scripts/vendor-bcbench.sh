#!/usr/bin/env bash
# Vendor the BC-Bench ALTest.agent.md domain-agent prompt into content/altest-prompt/
# at a pinned commit SHA.
#
# BC-Bench measured this prompt at +10.7 pt mean and ~2x pass^5 on AL test-generation
# tasks (Opus 4.6 / Copilot, 5 runs, 101 tasks). It is the single highest-ROI
# test-generation lever in the benchmark.
#
# Usage:
#   scripts/vendor-bcbench.sh                # Refresh at the SHA currently in PINNED.json
#   scripts/vendor-bcbench.sh --latest       # Bump to latest main HEAD
#   scripts/vendor-bcbench.sh --ref <sha>    # Pin to a specific SHA / branch / tag
#
# Requires: bash, curl, python3.

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PINNED_FILE="$PLUGIN_ROOT/content/PINNED.json"
REPO="microsoft/BC-Bench"
SRC_PATH="src/bcbench/agent/shared/instructions/microsoftInternal-NAV/agents/ALTest.agent.md"
DEST="$PLUGIN_ROOT/content/altest-prompt/ALTest.agent.md"

MODE="pinned"
REF=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --latest) MODE="latest"; shift ;;
    --ref)    MODE="explicit"; REF="${2:-}"; shift 2 ;;
    -h|--help)
      sed -n '2,12p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

resolve_ref() {
  case "$MODE" in
    pinned)
      python3 -c "import json; print(json.load(open('$PINNED_FILE'))['bcbench']['ref'])"
      ;;
    latest)
      curl -sf "https://api.github.com/repos/$REPO/commits/main" \
        | python3 -c "import sys, json; print(json.load(sys.stdin)['sha'])"
      ;;
    explicit)
      if [ -z "$REF" ]; then echo "--ref requires a value" >&2; exit 2; fi
      echo "$REF"
      ;;
  esac
}

REF_RESOLVED="$(resolve_ref)"
BASE="https://raw.githubusercontent.com/${REPO}/${REF_RESOLVED}"

echo "Vendoring ${REPO}@${REF_RESOLVED} → content/altest-prompt/"

mkdir -p "$(dirname "$DEST")"
curl -sf "${BASE}/${SRC_PATH}" -o "${DEST}" \
  || { echo "  FAIL ${SRC_PATH}" >&2; exit 1; }

LINES="$(wc -l < "${DEST}" | tr -d ' ')"
echo "  OK content/altest-prompt/ALTest.agent.md (${LINES} lines)"

# Update PINNED.json
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - "$PINNED_FILE" "$REF_RESOLVED" "$NOW" <<'PY'
import json, sys
path, ref, fetched_at = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    pinned = json.load(f)
pinned['bcbench']['ref'] = ref
pinned['bcbench']['fetched_at'] = fetched_at
pinned['bcbench']['license_url'] = f"https://github.com/microsoft/BC-Bench/blob/{ref}/LICENSE"
with open(path, 'w') as f:
    json.dump(pinned, f, indent=2)
    f.write('\n')
PY

echo
echo "Done. Pinned to ${REF_RESOLVED} at ${NOW}."
