#!/bin/sh
set -eu

cat >/dev/null

printf '%s\n' '{"additional_context":"This session may involve Microsoft Dynamics 365 Business Central AL work.\n\nGuidance for this session:\n- Identify the AL object type before editing.\n- For behavior changes, prefer a failing test before production code when meaningful.\n- Keep test code separate from production code.\n- Use Business Central test primitives correctly: SubType = Test, [Test], handler methods, HandlerFunctions, and AssertError only in test code.\n- Be explicit when tests cannot be executed in the current session.\n- Use the business-central-al-tdd skill when the task touches .al files or Business Central test structure."}'
