# Step 8: Docs and release notes

## The release-notes entry (every PR: TAG, Mobi, Trax and Verovia)

1. Write `docs/release-notes/unreleased/<ISSUE-ID>.md` in the PR's repo from `templates/release-note.md`. The repo's `docs/release-notes/unreleased/README.md` has the format. Read it, and where it differs from this step, it wins.
   - **tag-bc:** every TAG PR adds one, with `product: tag`.
   - **mobi:** every PR that changes what people see in Mobi, Trax or Verovia adds one file, `<ISSUE-ID>.md`, so parallel PRs never edit the same file. That includes Trax (`apps/trax`), Verovia (`apps/verovia`) and shared `packages/ai`.
   - `product` names every app the change reaches: `mobi`, `tag`, `trax` or `verovia`, separated by commas. A change in `packages/ai` usually reaches all three apps.
   - The body is one to three plain sentences, written for a customer, and never names a customer.
   - Hub and IoT have no release notes yet.
2. **Highlights (Trax and Verovia),** from mobi's README:

   An entry is a **line** by default: one to three plain sentences, at most 500 characters. One or two read best. Lines fill the New (`feature`), Improvements (`change`) and Fixes (`fix`) groups of What's new.

   Give an entry a `title` when people should notice the feature. It becomes a **highlight**: the person menu lists the two latest, and each opens with its title, an image and a few paragraphs.

   ```markdown
   ---
   product: mobi, trax, verovia
   type: feature
   issue: VERO-867
   audience: users
   title: Choose how each agent sounds
   image: VERO-867.webp
   image-dark: VERO-867-dark.webp
   ---
   You can now pick each agent's voice and talking pace for voice calls, and play a short sample before you save.

   In [Agents](/ai/agents), open **Edit agent** and go to **Voice**. …

   Learn more in [Work in an agent conversation](help:agents/conversations#choose-how-the-agent-sounds-in-voice-calls).
   ```

   - **The first paragraph is the line,** with a line's limits, so Mobi and any short list can still use it. Up to three more paragraphs follow: what it does, how to use it, what it needs or costs, and where to find it. The whole highlight is at most 1,200 characters, and the title at most 32.
   - **Only `**bold**` (for names in the app) and links,** of three kinds:
     - an app page such as `/ai/agents`, which must exist in every app the entry names;
     - a Help page such as `help:agents/check-ins#teams-mentions`, which must exist in `wiki/verovia`. Verovia opens its own Help; Trax opens Hub's Verovia documentation;
     - a web address starting with `https://`.
   - **The image is optional:** `.webp` or `.png`, at most 400 KB, 1600 × 900 recommended, next to the entry. `image-dark` is its dark-mode twin. Images are public, so crop to the feature: no customer, no person's data, no app shell.
   - At release, Alexis can turn a highlight back into a line by removing its `title`.
3. Check it:

   ```bash
   python3 "<skill folder>/../lifecycle-release/release_notes.py" validate docs/release-notes/unreleased/<ISSUE-ID>.md
   ```

   Fix every problem it lists. When the entry names `trax` or `verovia`, also run `bun run test:shared packages/ai/src/lib/release-notes` from mobi's root: it checks the rest, links and images included, as CI does.

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
