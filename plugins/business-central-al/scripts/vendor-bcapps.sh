#!/usr/bin/env bash
# Vendor microsoft/BCApps content (analyzer rulesets, DevEnv defaults, AI review prompts)
# into content/bcapps-*/ at a pinned commit SHA.
#
# Usage:
#   scripts/vendor-bcapps.sh                # Refresh at the SHA currently in PINNED.json
#   scripts/vendor-bcapps.sh --latest       # Bump to latest main HEAD
#   scripts/vendor-bcapps.sh --ref <sha>    # Pin to a specific SHA / branch / tag
#
# Requires: bash, curl, python3.

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PINNED_FILE="$PLUGIN_ROOT/content/PINNED.json"
REPO="microsoft/BCApps"

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
      python3 -c "import json; print(json.load(open('$PINNED_FILE'))['bcapps']['ref'])"
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

echo "Vendoring ${REPO}@${REF_RESOLVED} into content/bcapps-*/"

fetch() {
  local src="$1" dest="$2"
  # URL-encode spaces in the source path
  local src_encoded="${src// /%20}"
  curl -sf "${BASE}/${src_encoded}" -o "${dest}" \
    && echo "  OK ${dest#$PLUGIN_ROOT/}" \
    || { echo "  FAIL ${src}" >&2; return 1; }
}

# Rulesets
mkdir -p "$PLUGIN_ROOT/content/bcapps-rulesets"
for f in ruleset.json Analyzer.ruleset.json AppSourceCop.ruleset.json \
         CodeCop.ruleset.json Compiler.ruleset.json PTECop.ruleset.json \
         UICop.ruleset.json internal.module.ruleset.json minorrelease.ruleset.json; do
  fetch "src/rulesets/${f}" "$PLUGIN_ROOT/content/bcapps-rulesets/${f}"
done

# Defaults
mkdir -p "$PLUGIN_ROOT/content/bcapps-defaults"
fetch "build/scripts/DevEnv/DefaultSettings.json" \
      "$PLUGIN_ROOT/content/bcapps-defaults/DefaultSettings.json"

# Review prompts
mkdir -p "$PLUGIN_ROOT/content/bcapps-review-prompts"
for f in security performance style accessibility upgrade privacy; do
  fetch "tools/Code Review/instructions/${f}.md" \
        "$PLUGIN_ROOT/content/bcapps-review-prompts/${f}.md"
done

# al-docs plugin reference content (BCApps' own MIT-licensed AL doc-gen skill)
mkdir -p "$PLUGIN_ROOT/content/al-docs-references"
for f in SKILL.md al-docs-init.md al-docs-update.md al-docs-audit.md; do
  fetch "tools/al-docs-plugin/skills/al-docs/${f}" \
        "$PLUGIN_ROOT/content/al-docs-references/${f}"
done
fetch "tools/al-docs-plugin/skills/al-docs/references/al-scoring.md" \
      "$PLUGIN_ROOT/content/al-docs-references/al-scoring.md"

# Validate every fetched JSON parses
for f in "$PLUGIN_ROOT"/content/bcapps-rulesets/*.json \
         "$PLUGIN_ROOT"/content/bcapps-defaults/*.json; do
  python3 -c "import json; json.load(open('$f'))" \
    || { echo "INVALID JSON: $f" >&2; exit 1; }
done

# Update PINNED.json
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - "$PINNED_FILE" "$REF_RESOLVED" "$NOW" <<'PY'
import json, sys
path, ref, fetched_at = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    pinned = json.load(f)
pinned['bcapps']['ref'] = ref
pinned['bcapps']['fetched_at'] = fetched_at
pinned['bcapps']['license_url'] = f"https://github.com/microsoft/BCApps/blob/{ref}/LICENSE"
with open(path, 'w') as f:
    json.dump(pinned, f, indent=2)
    f.write('\n')
PY

echo
echo "Done. Pinned to ${REF_RESOLVED} at ${NOW}."
