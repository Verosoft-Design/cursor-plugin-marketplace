---
name: lifecycle-release
description: Gather a product's unreleased release-notes entries into the notes for one version, ready to paste into Hub.
argument-hint: "[tag|mobi] [version]"
disable-model-invocation: true
---

# Release notes for a version

Arguments: `$ARGUMENTS`, the product (`tag` or `mobi`) and the version. If either is missing, ask for it.

Run this in the product's repo: tag-bc for `tag`, mobi for `mobi`. The entries live in `docs/release-notes/unreleased/`, one file per PR. Mobi and TAG work both live in Linear's TAG team, so a `mobi` entry with a `TAG-` ID is normal.

1. **Draft the notes,** without moving anything:

   ```bash
   python3 "<skill folder>/release_notes.py" gather --dir docs/release-notes --product <product> --version <version> > /tmp/release-notes-<product>-<version>.md
   ```

   `<skill folder>` is this skill's folder, the base directory shown when it loads. Run the commands from the repo root. If it reports invalid entries, list them, fix them (or ask the PR author), and run it again. Show the drafted notes.
2. **Check them for customer names:**

   ```bash
   python3 "<skill folder>/../feature-lifecycle/scripts/check_customer_names.py" /tmp/release-notes-<product>-<version>.md
   ```

   - **Exit 1:** reword every line it lists, then check again.
   - **Exit 2:** there's no names list on this machine. Say so.
3. **G6 Release: Stéphane approves** the notes and the release (Alexis on Verovia; Alexis can approve any release). Ask in the chat if the approver is here. Otherwise, post the drafted notes as a comment for `@stephane.levert` (`@alexisturgeon` on Verovia) and stop. Never apply the notes before that approval.
4. **After approval,** move the entries and commit them in a PR (repo rules from `AGENTS.md`):

   ```bash
   python3 "<skill folder>/release_notes.py" gather --dir docs/release-notes --product <product> --version <version> --apply
   ```

   The files move to `docs/release-notes/<version>/`.
5. **Say where to paste the notes.** Until Hub has a write API, a person pastes them:
   - **Mobi:** Hub's Documentation Management, in the published document whose id is `MOBI_RELEASE_NOTES_DOCUMENT_ID`. That's the one Mobi's "new version" pop-up shows.
   - **TAG:** the "TAG release notes" document in Hub's Documentation Management, with one entry per version.

Trax, Verovia and `packages/ai` keep their release-please changelogs. Don't use this skill for them.
