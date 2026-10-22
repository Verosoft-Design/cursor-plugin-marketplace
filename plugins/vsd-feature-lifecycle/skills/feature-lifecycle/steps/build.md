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
- **On the agent server,** the lead hands the BC part off with a lifecycle comment whose header is `**Lifecycle: BC hand-off**`, and the BC session hands back with `**Lifecycle: BC ready**` once its PR is open. The server starts the other session each time.

## Screens in the mobi apps

Build a new or changed screen with the impeccable skill when it's installed, from the approved mockup (or like the existing screens, after a waiver). It reads the app's `PRODUCT.md` and `DESIGN.md`. Its finish review is the one review pass it gets (`steps/prove.md`).

## Subagents

You can give a subagent a search, a piece of the build that doesn't depend on the others, or a UI test lane (`steps/prove.md`). **You review what it produces yourself:** read its diff against the spec and the repo's rules, and send it back only for a real defect. A tester only reports findings, which you triage.

- Never give a subagent's work to another agent to review, and never run review → fix → re-review rounds between agents.
- When a plan skill offers subagent-driven development, which adds a reviewer per task, skip its reviewers: you are the reviewer.

The code review at the end is in `steps/prove.md`.

## Status

Set the status block to `Step: 5 Build` and `Waiting on: nothing`. The size can still go up here (check `sizes.md`). If it becomes major, stop at G1. A bug that becomes a feature carries on as one, with its decisions in the PR, unless step 2 says it needs a spec stop.

Next: step 6.
