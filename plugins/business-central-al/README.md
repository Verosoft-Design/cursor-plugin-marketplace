# business-central-al

`business-central-al` is a reusable Cursor plugin for Microsoft Dynamics 365 Business Central AL projects.

It provides:

- a primary skill for Business Central AL development with a TDD-first workflow
- lightweight AL rules that activate contextually in AL repositories
- helper commands for common test scaffolding and TDD prompts

## Repository Location

In this marketplace repo, the plugin lives at:

`plugins/business-central-al/`

The same plugin can also be copied into:

`~/.cursor/plugins/local/business-central-al/`

for direct local use without a marketplace repo.

## Included Components

- `skills/business-central-al-tdd/SKILL.md`
- `skills/business-central-al-tdd/reference.md`
- `rules/al-workflow.mdc`
- `rules/al-testing.mdc`
- `commands/scaffold-test-codeunit.md`
- `commands/scaffold-handler-methods.md`
- `commands/tdd-checklist.md`

## Behavior

The plugin is intentionally generic to Business Central AL. It does not enforce repo-specific prefixes, object ranges, or domain conventions.

The main skill teaches the agent to:

- identify the AL object type involved
- prefer tests before production changes when meaningful
- use Business Central test codeunits and handler methods correctly
- keep test and production code separate
- be explicit when test execution cannot be verified in the current session

The rules provide lightweight reinforcement for:

- AL naming and focused edits
- Business Central testing patterns such as `SubType = Test`, `[Test]`, `HandlerFunctions`, positive tests, and negative tests

## Commands

The commands are template-style helpers, not executable automation:

- `scaffold-test-codeunit`
- `scaffold-handler-methods`
- `tdd-checklist`

## Extending This Plugin

Keep project-specific guidance in repo-level rules. This plugin should remain a reusable baseline for Business Central AL work across multiple repositories.
