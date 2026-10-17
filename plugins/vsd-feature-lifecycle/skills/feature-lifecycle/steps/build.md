# Step 5: Build

Repo rules (commit style, PRs to `main`, worktrees, never stash) come from the repo's `AGENTS.md`.

## By size

- **Bug and feature:** one branch and **one PR per repo**, from `templates/pr-description.md`.
- **Major:** one integration branch, with each phase built on its own branch and merged into it.
  - One large draft PR stays open for review, testing and comments until it's ready.
  - **No side hotfix PRs:** every fix goes into the main PR.
  - Merging to `main` isn't a release.

## In AL repos

Use the business-central-al skills if they're installed:
- `al-conventions`
- `business-central-al-tdd`
- `al-build-and-publish`
- `al-upgrade-review` for upgrade code
- the `bc-explorer` agent for base-app facts

## Work across BC and Mobi

- The spec lives in mobi and reached mobi `main` at G2 (see `spec.md`).
- **Order:** BC and its API first, then Mobi. Mobi detects whether the new API exists, so it keeps working against older BC versions.
- **Two code PRs,** one per repo. Each links the spec and the other PR.
- **One Linear issue** carries both repos' work and the resume state. A docs-only mobi PR for a BC feature continues the same issue.
- The business-central-al skills only load in AL repos, so the BC part and the Mobi part run as two sessions.

## Status

Set the status block to `Step: 5 Build` and `Waiting on: nothing`. The size can still go up here (check `sizes.md`). If it does, stop at G1.

Next: step 6.
