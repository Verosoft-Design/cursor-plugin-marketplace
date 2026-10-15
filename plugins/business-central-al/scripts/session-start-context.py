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

# Model recommendation backed by microsoft/BC-Bench (101 tasks x 5 runs; leaderboard at 7c98b750, Oct 2026):
#   bug-fix:   gpt-5-6-sol 71.7% (Sep), claude-opus-4-6 + AL MCP 71.3% (Apr), claude-opus-4-8 68.3% (Jun);
#              the AL MCP is the only tooling lever with a measured bug-fix gain.
#   test-gen:  claude-opus-4-6 + ALTest 62.4% (Apr), claude-opus-4-8 without ALTest 60.8% (Jun).
#   code review: BCApps review instructions add ~+20 F1 for every model measured.
#   failure analysis: ~48% of failed bug fixes edited the wrong file/region; only ~6% failed to build.
model_line = (
    "Per microsoft/BC-Bench (Oct 2026), top AL models are within a few points of each other "
    "(gpt-5.6 and Claude Opus 4.x around 68-72% on bug-fix); the measured levers are the AL MCP "
    "(bug-fix), the ALTest prompt via /al-write-test (test generation) and the BCApps review "
    "instructions via /bcq-review (~+20 F1 on code review). About half of failed fixes edit the "
    "wrong place: trace the call path (al_symbolsearch, /al-call-graph) and write a failing test first."
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
    "- For full review, invoke /bcq-review (composes 19 BCQuality domain reviews + "
    "agent self-review).",
    "- New object IDs: al_getnextobjectid. Tests on a real server: /al-run-tests (al runtests). "
    "Live failures: /al-snapshot-debug. Slowness: /al-profile.",
    "- For test generation, invoke /al-write-test (wraps the BC-Bench ALTest "
    "domain-agent prompt, measured +10.7 pt on test-gen).",
    "- Be explicit when tests cannot be executed in the current session.",
    "",
    f"AL MCP status: {al_mcp_line}",
    "",
    f"Model recommendation: {model_line}",
])

print(json.dumps({"additional_context": context}))
