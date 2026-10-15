---
name: bcq-review-agents
description: Run only the BCQuality Agents (Agent SDK) review (al-agents-review) on AL code, covering agent interfaces, setup and creation, tasks, capability registration, profiles, access controls, instructions, and session-bound subscribers. It is not part of `/bcq-review`. Use when the user specifically wants Business Central agent (Agent SDK) feedback on a diff, a file, or an app folder.
disable-model-invocation: true
---

# Targeted: Agents (Agent SDK) review

Runs the `al-entry` skill with a goal that names Business Central agent (Agent SDK) explicitly. `al-agents-review` is a community-layer, top-level peer: Entry dispatches it directly and `al-code-review` never composes it. It is not part of `/bcq-review`.

## Inputs

Pass whatever the user supplies: a PR or working-tree diff (`pr-diff`), one file (`file-path`), or an app folder (`folder-path`). Every relevant file under the folder is reviewed.

## What runs

- The `al-agents-review` adapter skill, which follows `<plugin>/content/bcquality/community/skills/review/al-agents-review.md` (authoritative).
- Knowledge under `<plugin>/content/bcquality/{microsoft,community,custom}/knowledge/agents/`.

## Output

One findings-report JSON per the DO contract, with `skill.id: "al-agents-review"`. Every finding carries `domain: "Agents"`. `completed` with no findings means nothing was flagged; `partial` or `failed` is not a clean result. Render with `bash <plugin>/scripts/render-findings.sh` and give each `location.file:line` as a clickable reference.

## When to prefer this over `/bcq-review`

- The app implements or calls Business Central agents (Agent SDK).
- Agent setup, capabilities, profiles, or instructions changed.
- Agent tasks behave unexpectedly and the AL side needs a review.

`/bcq-review` does not run this leaf; run this command alongside it when the app uses agents.
