#!/usr/bin/env bash
# Vendor the BC-Bench ALTest.agent.md domain-agent prompt into content/altest-prompt/
# at a pinned commit SHA.
#
# BC-Bench measured this prompt at 62.4% vs 51.7% mean, pass^5 39.6% vs 22.8%, on AL
# test generation (GitHub Copilot CLI + Claude Opus 4.6, 101 tasks x 5 runs, April-May 2026).
# As of BC-Bench 7c98b750 (2026-10-13) it is still the only custom agent with published
# results; bug-fix has no measured prompt/agent (its only tooling win is the AL MCP).
#
# Usage:
#   scripts/vendor-bcbench.sh                # Refresh at the SHA currently in PINNED.json
#   scripts/vendor-bcbench.sh --latest       # Bump to latest main HEAD
#   scripts/vendor-bcbench.sh --ref <sha>    # Pin to a specific SHA / branch / tag
#   scripts/vendor-bcbench.sh --check        # Compare vendored file with upstream at the pin; writes nothing
#
# Requires: bash, curl, python3.

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PINNED_FILE="$PLUGIN_ROOT/content/PINNED.json"
REPO="microsoft/BC-Bench"
SRC_PATH="src/bcbench/agent/shared/instructions/microsoftInternal-NAV/agents/ALTest.agent.md"
# BC-Bench keeps a second copy for the public BCApps profile; warn if the two ever diverge.
SIBLING_PATH="src/bcbench/agent/shared/instructions/microsoft-BCApps/agents/ALTest.agent.md"
DEST="$PLUGIN_ROOT/content/altest-prompt/ALTest.agent.md"

MODE="pinned"
REF=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --latest) MODE="latest"; shift ;;
    --ref)    MODE="explicit"; REF="${2:-}"; shift 2 ;;
    --check)  MODE="check"; shift ;;
    -h|--help)
      sed -n '2,16p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

resolve_ref() {
  case "$MODE" in
    pinned|check)
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

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -sf "${BASE}/${SRC_PATH}" -o "${TMP}/new.md" \
  || { echo "  FAIL ${SRC_PATH} @ ${REF_RESOLVED}" >&2; exit 1; }
if curl -sf "${BASE}/${SIBLING_PATH}" -o "${TMP}/sibling.md"; then
  cmp -s "${TMP}/new.md" "${TMP}/sibling.md" \
    || echo "  WARN NAV and BCApps copies of ALTest.agent.md differ at ${REF_RESOLVED}; vendoring the NAV copy" >&2
fi

if [ "$MODE" = "check" ]; then
  if cmp -s "${TMP}/new.md" "${DEST}"; then
    echo "OK content/altest-prompt/ALTest.agent.md matches ${REPO}@${REF_RESOLVED}"
    exit 0
  fi
  echo "DRIFT content/altest-prompt/ALTest.agent.md differs from ${REPO}@${REF_RESOLVED}:" >&2
  diff -u "${DEST}" "${TMP}/new.md" >&2 || true
  exit 1
fi

echo "Vendoring ${REPO}@${REF_RESOLVED} → content/altest-prompt/"

mkdir -p "$(dirname "$DEST")"
if [ -f "${DEST}" ] && cmp -s "${TMP}/new.md" "${DEST}"; then
  STATUS="unchanged"
else
  STATUS="updated"
fi
cp "${TMP}/new.md" "${DEST}"

LINES="$(wc -l < "${DEST}" | tr -d ' ')"
echo "  OK content/altest-prompt/ALTest.agent.md (${LINES} lines, ${STATUS})"

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
