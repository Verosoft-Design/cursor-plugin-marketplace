#!/usr/bin/env python3
"""
Cursor userPromptSubmit hook — best-effort AL workspace detection.

Walks up from the current working directory looking for app.json and/or
.AL-Go/settings.json (or .github/AL-Go-Settings.json). When found, emits a
JSON additional_context blob with BC project metadata (publisher, version,
runtime, platform, target, AL-Go type/country/templateUrl).

Emits empty {} when no AL workspace is detected, so the hook is always
safe to run even in non-AL projects.
"""

import json
import os
import sys
from pathlib import Path

# Drain stdin — Cursor pipes the prompt context in but we don't consume it.
sys.stdin.read()

# Walk up from CWD looking for app.json and AL-Go settings.
# os.getcwd() is cross-platform; on Windows it reads the correct drive-rooted path.
start = Path(os.getcwd()).resolve()
app_json_path: Path | None = None
algo_settings_path: Path | None = None
current = start
max_depth = 8

for _ in range(max_depth):
    if app_json_path is None and (current / "app.json").is_file():
        app_json_path = current / "app.json"
    if algo_settings_path is None and (current / ".AL-Go" / "settings.json").is_file():
        algo_settings_path = current / ".AL-Go" / "settings.json"
    if algo_settings_path is None and (current / ".github" / "AL-Go-Settings.json").is_file():
        algo_settings_path = current / ".github" / "AL-Go-Settings.json"
    if app_json_path and algo_settings_path:
        break
    parent = current.parent
    if parent == current:
        break
    current = parent

if not app_json_path and not algo_settings_path:
    print("{}")
    sys.exit(0)

bits: list[str] = []

if app_json_path and app_json_path.is_file():
    try:
        with open(app_json_path, encoding="utf-8") as f:
            app = json.load(f)
        name = app.get("name", "(unnamed)")
        publisher = app.get("publisher", "(unknown)")
        version = app.get("version", "")
        runtime = app.get("runtime", "")
        platform = app.get("platform", "")
        target = app.get("target", "")
        bits.append(
            f"AL app detected: {name} by {publisher} "
            f"(version {version}, runtime {runtime}, platform {platform}, target {target})."
        )
        bits.append(f"  app.json: {app_json_path}")
    except Exception:
        pass

if algo_settings_path and algo_settings_path.is_file():
    try:
        with open(algo_settings_path, encoding="utf-8") as f:
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
