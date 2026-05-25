---
name: bcq-write-knowledge
description: Author a new BCQuality knowledge article in the plugin's custom layer. Invokes the bcq-write-knowledge skill which walks through the admission test, frontmatter authoring, body sections, optional sample files, and the upstream R01-R25 validator. Use when codifying a repo-specific or partner-specific BC convention so that future reviews automatically respect it.
---

# Author a custom BCQuality knowledge article

Invokes the `bcq-write-knowledge` skill. That skill is responsible for the actual authoring workflow.

## What this command does

1. Apply the `bcquality-write-contract` rule and read `<plugin>/content/bcquality/write.md`.
2. Walk through:
   - Admission test (does the LLM actually need this?)
   - Frontmatter authoring (6 required fields)
   - Path selection (`content/bcquality/custom/knowledge/<domain>/<slug>.md`)
   - Body composition (`## Description` required; `## Best Practice` and `## Anti Pattern` recommended)
   - Optional `.good.al` / `.bad.al` sample siblings
3. Write the file(s).
4. Run the vendored upstream validator:
   ```bash
   python3 <plugin>/scripts/validate-bcquality-frontmatter.py --root <plugin>/content/bcquality
   ```
5. Fix any reported errors.

## When to invoke

- The agent flagged the same repo-specific concern in multiple `/bcq-review` runs and the user wants to codify it.
- The user is migrating an existing `.cursor/rules/` rule into a structured, layer-precedence-aware BCQuality article.
- A partner is onboarding a new TAG-style codebase and the agent identifies conventions that need to be captured.

## When NOT to invoke

When the convention is:

- Generic software engineering (use HTTPS, don't hardcode secrets, etc.) — these belong nowhere; the LLM already knows them.
- A one-off code style choice with no obvious "wrong" alternative — put it in a `.cursor/rules/` rule, not a knowledge article.
- Already covered by an upstream microsoft or community article — don't duplicate; consider a custom article ONLY if you genuinely need to contradict the upstream guidance.

## After authoring

The article is immediately picked up by the next review run. No skill changes needed — the leaf skills source from `<layer>/knowledge/<domain>/` automatically.

If the new article contradicts an upstream article, the loser will appear in the next review's `suppressed[]` with `reason: "layer-precedence"`.
