# Step 8: Docs and release notes

## The release-notes entry (every PR, TAG and Mobi)

1. Write `docs/release-notes/unreleased/<ISSUE-ID>.md` in the PR's repo from `templates/release-note.md`.
   - `product` is `tag` or `mobi`.
   - The body is one to three plain sentences, written for a customer, and never names a customer.
   - Trax, Verovia and `packages/ai` keep their release-please changelog, so their PRs don't add an entry. Hub and IoT have none.
2. Check it:

   ```bash
   python3 "<skill folder>/../lifecycle-release/release_notes.py" validate docs/release-notes/unreleased/<ISSUE-ID>.md
   ```

   Fix every problem it lists.

## The user manual

The books live in mobi's `wiki/` folder and are synced into Hub (`bun run docs:sync` in `apps/hub`):
- `wiki/mobi`: the Mobi User Manual
- `wiki/tag`: The Asset Guardian User Manual, for BC features
- `wiki/verovia`: Verovia

Requirements by size:
- **Feature:** if users see the change, update the right page in the same change. A BC feature gets a docs-only mobi PR on the same Linear issue.
- **Major:** a guide section with real screenshots taken from the final build.

Set the status block to `Step: 8 Docs`.

Next: step 9.
