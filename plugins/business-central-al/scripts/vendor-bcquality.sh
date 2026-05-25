#!/usr/bin/env bash
# Vendor microsoft/BCQuality content (meta-skills, microsoft & community knowledge + skills,
# the upstream R01-R25 validator) into content/bcquality/ at a pinned commit SHA.
#
# Usage:
#   scripts/vendor-bcquality.sh                # Refresh at the SHA currently in PINNED.json
#   scripts/vendor-bcquality.sh --latest       # Bump to latest main HEAD
#   scripts/vendor-bcquality.sh --ref <sha>    # Pin to a specific SHA / branch / tag
#
# Does NOT touch content/bcquality/custom/ — that is local plugin content.
#
# Requires: bash, curl, tar, python3.

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PINNED_FILE="$PLUGIN_ROOT/content/PINNED.json"
REPO="microsoft/BCQuality"
DEST="$PLUGIN_ROOT/content/bcquality"

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
      python3 -c "import json; print(json.load(open('$PINNED_FILE'))['bcquality']['ref'])"
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
echo "Vendoring ${REPO}@${REF_RESOLVED} into content/bcquality/"

# Download tarball
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

curl -sfL "https://api.github.com/repos/${REPO}/tarball/${REF_RESOLVED}" \
     -o "${TMPDIR}/bcq.tar.gz" \
  || { echo "Failed to download tarball" >&2; exit 1; }

tar -xzf "${TMPDIR}/bcq.tar.gz" -C "${TMPDIR}"
SRC="$(ls -d ${TMPDIR}/microsoft-BCQuality-* 2>/dev/null | head -1)"
if [ -z "$SRC" ]; then
  echo "Could not find extracted source dir" >&2
  exit 1
fi

# Wipe and replace upstream-managed dirs (NEVER touches custom/)
rm -rf "${DEST}/microsoft" "${DEST}/community"
mkdir -p "${DEST}/microsoft" "${DEST}/community" "${DEST}/custom/knowledge" "${DEST}/custom/skills"

cp -r "${SRC}/microsoft/knowledge" "${DEST}/microsoft/"
cp -r "${SRC}/microsoft/skills"    "${DEST}/microsoft/"
cp -r "${SRC}/community/knowledge" "${DEST}/community/"

# Meta-skills at content/bcquality/ root
cp "${SRC}/skills/entry.md" "${DEST}/"
cp "${SRC}/skills/read.md"  "${DEST}/"
cp "${SRC}/skills/do.md"    "${DEST}/"
cp "${SRC}/skills/write.md" "${DEST}/"

# Validator
cp "${SRC}/.github/scripts/validate_frontmatter.py" \
   "${PLUGIN_ROOT}/scripts/validate-bcquality-frontmatter.py"

echo "  Microsoft knowledge files: $(find ${DEST}/microsoft/knowledge -name '*.md' | wc -l | tr -d ' ')"
echo "  Microsoft AL samples:      $(find ${DEST}/microsoft/knowledge -name '*.al' | wc -l | tr -d ' ')"
echo "  Microsoft skills:          $(find ${DEST}/microsoft/skills -name '*.md' | wc -l | tr -d ' ')"
echo "  Community knowledge:       $(find ${DEST}/community/knowledge -name '*.md' | wc -l | tr -d ' ')"
echo "  Community AL samples:      $(find ${DEST}/community/knowledge -name '*.al' | wc -l | tr -d ' ')"
echo "  Meta-skills at root:       $(ls ${DEST}/*.md 2>/dev/null | wc -l | tr -d ' ')"
echo "  Validator:                 $(wc -l < ${PLUGIN_ROOT}/scripts/validate-bcquality-frontmatter.py | tr -d ' ') lines"

# Validate the full tree (microsoft + community + custom + meta-skills)
echo
echo "Running upstream validator on the full tree..."
if python3 "${PLUGIN_ROOT}/scripts/validate-bcquality-frontmatter.py" --root "${DEST}" 2>&1 | tail -5; then
  echo "  PASS"
else
  echo "  FAIL — upstream validator reported errors. Consider reverting via --ref <previous-sha>." >&2
  exit 1
fi

# Update PINNED.json
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
python3 - "$PINNED_FILE" "$REF_RESOLVED" "$NOW" <<'PY'
import json, sys
path, ref, fetched_at = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as f:
    pinned = json.load(f)
pinned['bcquality']['ref'] = ref
pinned['bcquality']['fetched_at'] = fetched_at
pinned['bcquality']['license_url'] = f"https://github.com/microsoft/BCQuality/blob/{ref}/LICENSE"
with open(path, 'w') as f:
    json.dump(pinned, f, indent=2)
    f.write('\n')
PY

echo
echo "Done. Pinned to ${REF_RESOLVED} at ${NOW}."
echo "Custom layer (content/bcquality/custom/) preserved."
