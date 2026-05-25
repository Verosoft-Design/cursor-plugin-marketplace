#!/bin/sh
# Best-effort AL workspace detection for the userPromptSubmit hook.
# Walks up from the invocation directory looking for app.json and/or .AL-Go/.
# Emits a JSON additional_context blob describing the BC project metadata
# (publisher, app version, runtime, project paths) when a workspace is found.
# Emits an empty no-op JSON when no AL workspace is detected.

set -eu

# Drain stdin; Cursor pipes the prompt context in but we don't consume it.
cat >/dev/null

# Try to find an AL project root by walking up from PWD.
DIR="${PWD:-$(pwd 2>/dev/null || echo /)}"
APP_JSON=""
ALGO_SETTINGS=""
DEPTH=0
MAX_DEPTH=8

while [ "$DIR" != "/" ] && [ "$DIR" != "" ] && [ "$DEPTH" -lt "$MAX_DEPTH" ]; do
    if [ -z "$APP_JSON" ] && [ -f "$DIR/app.json" ]; then
        APP_JSON="$DIR/app.json"
    fi
    if [ -z "$ALGO_SETTINGS" ] && [ -f "$DIR/.AL-Go/settings.json" ]; then
        ALGO_SETTINGS="$DIR/.AL-Go/settings.json"
    fi
    if [ -z "$ALGO_SETTINGS" ] && [ -f "$DIR/.github/AL-Go-Settings.json" ]; then
        ALGO_SETTINGS="$DIR/.github/AL-Go-Settings.json"
    fi
    if [ -n "$APP_JSON" ] && [ -n "$ALGO_SETTINGS" ]; then
        break
    fi
    DIR="$(dirname "$DIR")"
    DEPTH=$((DEPTH + 1))
done

# Nothing AL-shaped here? Emit empty JSON and exit.
if [ -z "$APP_JSON" ] && [ -z "$ALGO_SETTINGS" ]; then
    printf '{}'
    exit 0
fi

# Parse what we found via python3. Fall back to empty JSON on any parse error.
python3 - "$APP_JSON" "$ALGO_SETTINGS" <<'PY' 2>/dev/null || printf '{}'
import json
import sys
from pathlib import Path

app_json_path = sys.argv[1] if len(sys.argv) > 1 else ""
algo_settings_path = sys.argv[2] if len(sys.argv) > 2 else ""

bits = []

if app_json_path and Path(app_json_path).is_file():
    try:
        with open(app_json_path) as f:
            app = json.load(f)
        name = app.get("name", "(unnamed)")
        publisher = app.get("publisher", "(unknown)")
        version = app.get("version", "")
        runtime = app.get("runtime", "")
        platform = app.get("platform", "")
        target = app.get("target", "")
        bits.append(f"AL app detected: {name} by {publisher} (version {version}, runtime {runtime}, platform {platform}, target {target}).")
        bits.append(f"  app.json: {app_json_path}")
    except Exception:
        pass

if algo_settings_path and Path(algo_settings_path).is_file():
    try:
        with open(algo_settings_path) as f:
            algo = json.load(f)
        algo_type = algo.get("type", "")
        country = algo.get("country", "")
        template_url = algo.get("templateUrl", "")
        bits.append(f"AL-Go repo detected: type={algo_type}, country={country}.")
        if template_url:
            bits.append(f"  templateUrl: {template_url}")
        bits.append(f"  AL-Go settings: {algo_settings_path}")
    except Exception:
        pass

if bits:
    msg = "\n".join(bits)
    out = {"additional_context": f"BC project context:\n{msg}"}
    print(json.dumps(out, ensure_ascii=False))
else:
    print("{}")
PY
