#!/bin/sh
set -eu

# Cursor pipes the session context into stdin for sessionStart hooks. We don't
# consume it, but we must drain stdin or the hook can hang on some platforms.
cat >/dev/null

# Locate the plugin's scripts/ folder relative to this script so we can run the
# AL MCP probe. The probe is best-effort — if we can't locate or execute it,
# fall back to "missing" without erroring out.
SCRIPT_DIR="$(cd "$(dirname "$0")" 2>/dev/null && pwd 2>/dev/null || true)"
CHECK_SCRIPT="${SCRIPT_DIR}/check-altool.sh"

if [ -n "${SCRIPT_DIR}" ] && [ -x "${CHECK_SCRIPT}" ]; then
    AL_MCP_STATUS="$("${CHECK_SCRIPT}" 2>/dev/null || echo missing)"
else
    AL_MCP_STATUS="missing"
fi

# Translate the probe result into a one-line session-context hint.
case "${AL_MCP_STATUS}" in
    altool:*)
        AL_MCP_LINE="AL MCP is wired (altool detected). Commands /al-symbols, /al-symbol-search, /al-compile, /al-build, /al-publish-sandbox are available."
        ;;
    al:*)
        AL_MCP_LINE="The al binary (NuGet AL Development Tools) is on PATH but the plugin mcp.json expects altool. Run /al-setup to alias altool to al, or fix mcp.json manually."
        ;;
    *)
        AL_MCP_LINE="AL MCP cannot start: neither altool nor al is on PATH. Run /al-setup for guided installation."
        ;;
esac

# Model recommendation backed by microsoft/BC-Bench measurements (101 tasks, 5 runs each):
#   bug-fix winners:        claude-opus-4-7 67.9%, claude-sonnet-4-6 67.3%, claude-opus-4-6 + AL MCP 71.3%
#   test-generation winner: claude-opus-4-7 54.3%, with ALTest agent: claude-opus-4-6 62.4% (+10.7 pt)
#   speed pick:             gpt-5-3-codex 55.8% bug-fix at ~107s/task (~3x faster than Claude Opus)
#   AVOID for AL:           gpt-4-1 16.6% — effectively unusable on AL
MODEL_LINE="Per microsoft/BC-Bench measurements, the recommended models for AL are Claude Opus 4.7 (highest accuracy) or Claude Sonnet 4.6 (best cost/quality tradeoff). gpt-5.3-codex is the fast option (~3x faster, ~56% bug-fix). Avoid gpt-4.1 for AL — measured at 16.6% on AL tasks."

# Emit the session-start context as a single JSON object. Newlines inside the
# additional_context value are encoded as the literal two-character escape \n
# so the printf format compiles to valid JSON.
printf '{"additional_context":"This session may involve Microsoft Dynamics 365 Business Central AL work.\\n\\nGuidance for this session:\\n- Identify the AL object type before editing.\\n- For behavior changes, prefer a failing test before production code when meaningful.\\n- Keep test code separate from production code.\\n- Use BCApps test conventions (Library Assert codeunit 130002, EventSubscriberInstance = Manual, [TransactionModel] matching Commit behavior, Given/When/Then comments).\\n- For full review, invoke /bcq-review (composes 6 BCQuality leaf reviews + agent self-review).\\n- For test generation, invoke /al-write-test (wraps the BC-Bench ALTest domain-agent prompt, measured +10.7 pt on test-gen).\\n- Be explicit when tests cannot be executed in the current session.\\n\\nAL MCP status: %s\\n\\nModel recommendation: %s"}\n' "${AL_MCP_LINE}" "${MODEL_LINE}"
