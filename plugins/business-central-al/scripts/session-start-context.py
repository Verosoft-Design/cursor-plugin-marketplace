#!/usr/bin/env python3
"""
Cursor sessionStart hook — injects AL-focused context at the start of every
agent session.

Probes for the AL MCP binary via check-altool.py (located next to this script),
then emits a JSON additional_context blob with:
  - TDD / object-type guidance
  - Live AL MCP status (altool ready / needs fix / missing)
  - BC-Bench model recommendation
"""

import json
import subprocess
import sys
from pathlib import Path

# Drain stdin — Cursor pipes the session context in but we don't consume it.
sys.stdin.read()

# Locate check-altool.py relative to this script so we don't depend on CWD.
script_dir = Path(__file__).parent
check_script = script_dir / "check-altool.py"

try:
    result = subprocess.run(
        [sys.executable, str(check_script)],
        capture_output=True,
        text=True,
        timeout=10,
    )
    al_mcp_status = result.stdout.strip() if result.returncode == 0 else "missing"
except Exception:
    al_mcp_status = "missing"

if al_mcp_status.startswith("altool:"):
    al_mcp_line = (
        "AL MCP is wired (altool detected). Commands /al-symbols, "
        "/al-symbol-search, /al-compile, /al-build, /al-publish-sandbox are available."
    )
elif al_mcp_status.startswith("al:"):
    al_mcp_line = (
        "The al binary (NuGet AL Development Tools) is on PATH but the plugin "
        "mcp.json expects altool. Run /al-setup to alias altool to al, or fix "
        "mcp.json manually."
    )
else:
    al_mcp_line = (
        "AL MCP cannot start: neither altool nor al is on PATH. "
        "Run /al-setup for guided installation."
    )

# Model recommendation backed by microsoft/BC-Bench measurements
# (101 tasks, 5 runs each):
#   bug-fix winners:        claude-opus-4-7 67.9%, claude-sonnet-4-6 67.3%,
#                           claude-opus-4-6 + AL MCP 71.3%
#   test-generation winner: claude-opus-4-7 54.3%, with ALTest agent:
#                           claude-opus-4-6 62.4% (+10.7 pt)
#   speed pick:             gpt-5-3-codex 55.8% bug-fix at ~107s/task (~3x faster)
#   AVOID for AL:           gpt-4-1 16.6% — effectively unusable on AL
model_line = (
    "Per microsoft/BC-Bench measurements, the recommended models for AL are "
    "Claude Opus 4.7 (highest accuracy) or Claude Sonnet 4.6 (best cost/quality "
    "tradeoff). gpt-5.3-codex is the fast option (~3x faster, ~56% bug-fix). "
    "Avoid gpt-4.1 for AL — measured at 16.6% on AL tasks."
)

context = "\n".join([
    "This session may involve Microsoft Dynamics 365 Business Central AL work.",
    "",
    "Guidance for this session:",
    "- Identify the AL object type before editing.",
    "- For behavior changes, prefer a failing test before production code when meaningful.",
    "- Keep test code separate from production code.",
    "- Use BCApps test conventions (Library Assert codeunit 130002, "
    "EventSubscriberInstance = Manual, [TransactionModel] matching Commit behavior, "
    "Given/When/Then comments).",
    "- For full review, invoke /bcq-review (composes 6 BCQuality leaf reviews + "
    "agent self-review).",
    "- For test generation, invoke /al-write-test (wraps the BC-Bench ALTest "
    "domain-agent prompt, measured +10.7 pt on test-gen).",
    "- Be explicit when tests cannot be executed in the current session.",
    "",
    f"AL MCP status: {al_mcp_line}",
    "",
    f"Model recommendation: {model_line}",
])

print(json.dumps({"additional_context": context}))
