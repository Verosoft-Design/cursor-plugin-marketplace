# Step 9: Ship

1. **G5 Merge:** a person (Stéphane or Alexis) merges the PR. **Agents never merge.**
   - Mark the PR ready.
   - Set `Waiting on: G5 Merge (@stephane.levert)`.
   - Stop.
2. **Merging to `main` isn't a release.**
3. **G6 Release (Alexis)** runs the `lifecycle-release` skill. It gathers the product's unreleased entries into that version's notes for Hub, then follows the product's own release process: AppSource for TAG, and the Vercel promotion for Mobi and Hub.
4. **Once merged,** set the status block to `Step: 9 Ship` and `Waiting on: nothing`. The work is done.
