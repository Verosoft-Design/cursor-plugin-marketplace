# cursor-plugin-marketplace

This repository is a shareable Cursor plugin marketplace repo for custom plugins.

It currently contains:

- `business-central-al`
- `mobi-knowledge`

## Structure

```text
cursor-plugin-marketplace/
├── .cursor-plugin/
│   └── marketplace.json
└── plugins/
    ├── business-central-al/
    │   ├── .cursor-plugin/plugin.json
    │   ├── README.md
    │   ├── LICENSE
    │   ├── rules/
    │   ├── skills/
    │   └── commands/
    └── mobi-knowledge/
        ├── .cursor-plugin/plugin.json
        ├── README.md
        ├── rules/
        ├── skills/
        └── mcp/              ← deployable Node.js MCP server
```

## Current Plugins

### `business-central-al`

A reusable Cursor plugin for Microsoft Dynamics 365 Business Central AL work. It provides:

- a Business Central AL TDD skill
- AL workflow and testing rules
- command templates for test codeunits, handler methods, and TDD checklists

### `mobi-knowledge`

Semantic search over the Verosoft/Mobi knowledge base. It provides:

- rules telling agents when and how to call the search MCP tools
- skills for `search_knowledge`, `search_business_answers`, `search_documents`, and `search_connector_knowledge`
- a deployable MCP server (`mcp/`) that supports both stdio (local Cursor) and Streamable HTTP (Linear cloud agents)

## Publishing And Use

After this repository is pushed to GitHub, it can be used as a plugin marketplace repository by importing the repository URL in Cursor.

## Notes

- Keep each plugin self-contained inside `plugins/<plugin-name>/`.
- Keep plugin manifests, component paths, and frontmatter valid.
- Put plugin-specific usage docs inside the plugin folder README.
