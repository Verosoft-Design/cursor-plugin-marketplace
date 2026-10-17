#!/usr/bin/env bash
# Mirrors the vsd-feature-lifecycle skills from Verosoft-Design/claude-plugins at a tag.
# The Claude repo is canonical: never edit plugins/vsd-feature-lifecycle/skills/ here by hand.
# Usage: scripts/sync-vsd-feature-lifecycle.sh <claude-plugins tag, e.g. vsd-feature-lifecycle-v0.1.0>
set -euo pipefail
TAG="${1:?usage: $0 <claude-plugins tag>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$ROOT/plugins/vsd-feature-lifecycle"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
git -c advice.detachedHead=false clone -q --depth 1 --branch "$TAG" https://github.com/Verosoft-Design/claude-plugins.git "$TMP/claude-plugins"
SRC="$TMP/claude-plugins/plugins/vsd-feature-lifecycle"
mkdir -p "$DEST/skills"
rsync -a --delete "$SRC/skills/" "$DEST/skills/"
cp "$SRC/LICENSE" "$DEST/LICENSE"
echo "$TAG" > "$DEST/SYNCED_FROM"
echo "synced $(find "$DEST/skills" -type f | wc -l | tr -d ' ') files from claude-plugins $TAG"
