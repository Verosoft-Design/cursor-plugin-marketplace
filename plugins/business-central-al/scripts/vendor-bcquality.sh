#!/usr/bin/env bash
# Vendor microsoft/BCQuality into content/bcquality/ at a pinned commit SHA, mirroring
# the upstream repository layout so upstream's repo-relative paths resolve unchanged:
#
#   skills/{entry,read,do,write,README}.md   Entry point + READ/DO/WRITE contracts
#   microsoft/{knowledge,skills}/            Microsoft layer (super-skill + review leaves)
#   community/{knowledge,skills}/            Community layer (e.g. al-agents-review)
#   schemas/                                 findings-report + skill-index JSON schemas
#   tools/                                   knowledge/skill index + retrieval helpers (pwsh)
#   docs/                                    contributor / consumer docs the contracts link to
#   LICENSE                                  upstream MIT license
# plus the upstream validator at scripts/validate-bcquality-frontmatter.py.
#
# Usage:
#   scripts/vendor-bcquality.sh                # Refresh at the SHA currently in PINNED.json
#   scripts/vendor-bcquality.sh --latest       # Bump to latest main HEAD
#   scripts/vendor-bcquality.sh --ref <sha>    # Pin to a specific SHA / branch / tag
#
# Does NOT touch content/bcquality/custom/ — that is local plugin content.
#
# Requires: bash, curl, tar, python3 (validator needs PyYAML). Set PYTHON to use a
# different interpreter, e.g. PYTHON=.venv/bin/python scripts/vendor-bcquality.sh

set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PINNED_FILE="$PLUGIN_ROOT/content/PINNED.json"
REPO="microsoft/BCQuality"
DEST="$PLUGIN_ROOT/content/bcquality"
PYTHON="${PYTHON:-python3}"

MODE="pinned"
REF=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --latest) MODE="latest"; shift ;;
    --ref)    MODE="explicit"; REF="${2:-}"; shift 2 ;;
    -h|--help)
      sed -n '2,22p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

resolve_ref() {
  case "$MODE" in
    pinned)
      "$PYTHON" -c "import json,sys; print(json.load(open(sys.argv[1]))['bcquality']['ref'])" "$PINNED_FILE"
      ;;
    latest)
      curl -sf "https://api.github.com/repos/$REPO/commits/main" \
        | "$PYTHON" -c "import sys, json; print(json.load(sys.stdin)['sha'])"
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

mkdir -p "${TMPDIR}/src"
tar -xzf "${TMPDIR}/bcq.tar.gz" -C "${TMPDIR}/src"
SRC="$(ls -d "${TMPDIR}"/src/microsoft-BCQuality-* 2>/dev/null | head -1)"
if [ -z "$SRC" ]; then
  echo "Could not find extracted source dir" >&2
  exit 1
fi

# Fail early if the upstream layout moved again, before wiping anything.
for required in skills/entry.md skills/read.md skills/do.md skills/write.md \
                microsoft/knowledge microsoft/skills community/knowledge \
                .github/scripts/validate_frontmatter.py; do
  if [ ! -e "${SRC}/${required}" ]; then
    echo "Upstream layout changed: ${required} not found at ${REF_RESOLVED}. Update this script." >&2
    exit 1
  fi
done

# Wipe upstream-managed paths (NEVER touches custom/). The root-level *.md files are
# the pre-2026-10 layout, where the meta-skills were flattened into content/bcquality/.
rm -rf "${DEST}/microsoft" "${DEST}/community" "${DEST}/skills" \
       "${DEST}/schemas" "${DEST}/tools" "${DEST}/docs"
rm -f  "${DEST}/LICENSE" "${DEST}/entry.md" "${DEST}/read.md" "${DEST}/do.md" "${DEST}/write.md" \
       "${DEST}/knowledge-index.json" "${DEST}/skill-index.json"
mkdir -p "${DEST}/microsoft" "${DEST}/community" "${DEST}/skills" \
         "${DEST}/custom/knowledge" "${DEST}/custom/skills"

# Layers
cp -r "${SRC}/microsoft/knowledge" "${DEST}/microsoft/"
cp -r "${SRC}/microsoft/skills"    "${DEST}/microsoft/"
cp -r "${SRC}/community/knowledge" "${DEST}/community/"
[ -d "${SRC}/community/skills" ] && cp -r "${SRC}/community/skills" "${DEST}/community/"
find "${DEST}/microsoft" "${DEST}/community" -name '.gitkeep' -delete

# Entry point + meta-skill contracts (upstream's host adapter skills/al-code-review/ is
# not vendored: the plugin ships its own adapters under skills/).
for f in entry.md read.md do.md write.md README.md; do
  [ -f "${SRC}/skills/${f}" ] && cp "${SRC}/skills/${f}" "${DEST}/skills/"
done

# Schemas, runtime tools (Test-* harnesses need upstream's evaluation/ and are skipped), docs
[ -d "${SRC}/schemas" ] && cp -r "${SRC}/schemas" "${DEST}/"
if [ -d "${SRC}/tools" ]; then
  mkdir -p "${DEST}/tools"
  find "${SRC}/tools" -maxdepth 1 -type f ! -name 'Test-*' -exec cp {} "${DEST}/tools/" \;
fi
[ -d "${SRC}/docs" ] && cp -r "${SRC}/docs" "${DEST}/"
cp "${SRC}/LICENSE" "${DEST}/LICENSE"

# Generated at runtime by tools/Build-*Index.ps1; never committed.
printf 'knowledge-index.json\nskill-index.json\n' > "${DEST}/.gitignore"

# Validator
cp "${SRC}/.github/scripts/validate_frontmatter.py" \
   "${PLUGIN_ROOT}/scripts/validate-bcquality-frontmatter.py"

count() { find "$1" -name "$2" 2>/dev/null | wc -l | tr -d ' '; }
echo "  Microsoft knowledge files: $(count "${DEST}/microsoft/knowledge" '*.md')"
echo "  Microsoft samples:         $(find "${DEST}/microsoft/knowledge" -type f ! -name '*.md' | wc -l | tr -d ' ')"
echo "  Microsoft action skills:   $(count "${DEST}/microsoft/skills" '*.md')"
echo "  Community knowledge:       $(count "${DEST}/community/knowledge" '*.md')"
echo "  Community samples:         $(find "${DEST}/community/knowledge" -type f ! -name '*.md' | wc -l | tr -d ' ')"
echo "  Community action skills:   $(count "${DEST}/community/skills" '*.md')"
echo "  Knowledge domains:         $(for d in "${DEST}"/microsoft/knowledge/*/ "${DEST}"/community/knowledge/*/; do [ -d "$d" ] && basename "$d"; done | sort -u | tr '\n' ' ')"
echo "  Entry + contracts:         $(ls "${DEST}"/skills/*.md 2>/dev/null | wc -l | tr -d ' ') files in skills/"
echo "  Tools / schemas / docs:    $(find "${DEST}/tools" -type f | wc -l | tr -d ' ') / $(count "${DEST}/schemas" '*.json') / $(count "${DEST}/docs" '*.md')"
echo "  Validator:                 $(wc -l < "${PLUGIN_ROOT}/scripts/validate-bcquality-frontmatter.py" | tr -d ' ') lines"

# Validate the full tree (microsoft + community + custom + entry/meta-skills)
echo
echo "Running upstream validator on the full tree (${PYTHON})..."
set +e
VALIDATOR_OUT="$("$PYTHON" "${PLUGIN_ROOT}/scripts/validate-bcquality-frontmatter.py" --root "${DEST}" 2>&1)"
VALIDATOR_RC=$?
set -e
printf '%s\n' "$VALIDATOR_OUT" | tail -5
if [ "$VALIDATOR_RC" -eq 0 ]; then
  echo "  PASS"
else
  echo "  FAIL (exit ${VALIDATOR_RC}) — upstream validator reported errors or could not run." >&2
  echo "  PINNED.json was NOT updated. Fix the errors, or revert via --ref <previous-sha>." >&2
  exit 1
fi

# Update PINNED.json
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
"$PYTHON" - "$PINNED_FILE" "$REF_RESOLVED" "$NOW" <<'PY'
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
