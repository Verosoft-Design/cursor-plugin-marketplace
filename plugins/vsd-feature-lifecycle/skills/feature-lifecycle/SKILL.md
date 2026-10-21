---
name: feature-lifecycle
description: "Start, size and run Verosoft dev work in Business Central (AL) and Mobi: a bug, a feature or a major change, from a Linear issue or a request. Decides the size, the steps, where the spec lives and when to stop for an approval. Use when picking up an issue, starting a fix or feature, or resuming one."
---

# Feature lifecycle

Every piece of Verosoft dev work (Business Central/AL in tag-bc or other AL repos, and the mobi monorepo) goes through the same lifecycle, scaled to its size. This skill sizes the work, runs the steps that size needs, and stops at the gates. The files next to this one hold the detail. Read each one only when you reach it.

**Paths:** every path in this skill's files (`steps/…`, `templates/…`, `scripts/…`, `gates.md`, `../lifecycle-release/…`) is relative to this skill's folder, the base directory shown when the skill loads. Commands written with `<skill folder>` run from the repo root, with that folder's full path filled in.

## 1. Who's here and what's installed

- **Is the person an approver?** The Linear issue's assignee owns the work's decisions: they approve the size, the spec and the design and merge the PR (G1, G2, G3, G5), also on their own work and in their own session. When nobody is assigned, the team lead does. The team lead (Frederick Cleroux on Verovia, Stéphane Levert on every other team) and Alexis Turgeon can also approve any gate, but G4 and G6 go to Stéphane Levert on every team but Verovia, and to Alexis on Verovia; Alexis can approve them on any team (`gates.md`).
  - **Who is in the session** comes from `git config user.name` or the `gh` login. A name stated in the chat ("I'm …") counts only when it matches that identity, or when there's no identity to check. If they don't match, don't treat the person as an approver: say so and ask them to confirm, or use the Linear path in `gates.md`.
  - **Who is assigned** is the issue's Assignee field in Linear (never its delegate, the agent). Without a Linear tool, a person's "it's assigned to me" counts when their name matches the session identity.
  - **On a Linear issue,** an approval counts only when the comment's author is the gate's approver: the assignee (the team lead when nobody is assigned), the team lead (`@frederick.cleroux` on Verovia, `@stephane.levert` otherwise) or `@alexisturgeon`. For G4 and G6, only `@stephane.levert` or `@alexisturgeon`, and only `@alexisturgeon` on Verovia. A comment "on behalf of" an approver doesn't count.
- **Companion plugins.** Steps call these skills when they're installed:
  - superpowers (brainstorming, writing-plans, test-driven-development, systematic-debugging, verification-before-completion);
  - mattpocock-skills (grilling);
  - impeccable, for screens in the mobi apps (mockups and UI);
  - business-central-al, in AL repos.

  If one is missing, name it with its install line and carry on with the step's plain instructions:
  - `claude plugin install superpowers@claude-plugins-official`
  - `claude plugin install mattpocock-skills@claude-plugins-official`
  - `npx impeccable install -y --providers=claude,codex --global --no-hooks`
  - `claude plugin install business-central-al@verosoft-design --scope local`

## 2. Resume first

Look for the status at the end of the spec, or in the issue's latest lifecycle comment. In the spec it's a block (GitHub hides the HTML comment):

```text
<!-- lifecycle-status -->
Size: <Bug|Feature|Major>
Step: <number> <name>
Waiting on: <gate or hand-off, with who> | nothing
```

In a Linear comment it's one line, because Linear prints HTML comments as text: `**Status:** <Bug|Feature|Major> · Step <number> <name> · Waiting on <gate or hand-off, with who> | nothing`. Older comments may still have the block; read either.

- **If a status exists, continue from it.** If its "Waiting on" gate now has an approval from that gate's approver (see section 1), mark it passed and go to the next step. Don't restart intake, and don't ask again.
- **When the issue's latest lifecycle comment and the spec disagree,** the latest comment wins. It's what a fresh run, which may not have the branch, can see.
- **Keep the status current** at every step change: the block in the spec, the line in Linear comments. A bug keeps it in a Linear comment.

## 3. Intake and size

1. **Read the issue:** title, description, labels (`Bug`, `Feature`, `Improvement`), comments, and which repo.
   - **A question, not work?** When the person asks about the code base or the issue rather than for a change, answer it: read the code as needed, but don't size it, branch, change code or open a PR. On Linear, post the answer as a comment whose first line is `**Lifecycle: answered**`, then stop. If the code doesn't settle it, say what you looked at, still as `answered`; if only the person can tell you more, use `needs info` instead.
2. **Too little to size?** If you can't tell what's wrong, where, or what's expected, don't size it and don't start. Say what's missing and ask, or propose marking the issue `needs-info`.
3. **Propose a size** with `sizes.md`.
   - A label is a hint, not the size: check the escalation list in `sizes.md`.
   - If you hit an item, say which one. A bug that becomes a feature carries on as a feature: step 2 decides whether it needs a spec stop.
   - Work that becomes or starts as major waits for G1.
4. **Pick the spec's home:**
   - BC only: the BC repo.
   - Mobi only: mobi.
   - BC and Mobi together: mobi.

   Linear and the other repo only link to the spec, never copy it.

   The spec's path in that repo:
   - **Feature:** one file, `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`.
   - **Major:** a folder, `docs/superpowers/specs/YYYY-MM-DD-<topic>/`.
   - **Bug:** none. The Linear issue is the spec.

   **When the work touches BC and Mobi,** the plan states from the start:
   - the spec lives in mobi and goes into mobi `main` through its own small docs PR once G2 approves it, before any code;
   - BC and its API are built first, then Mobi, which detects whether the new API exists;
   - one Linear issue carries both, with two code PRs that each link the spec.

   Details are in `steps/build.md`.
5. **Read the repo's rules:** `AGENTS.md` and `docs/agents/*`. Repo rules (commits, PRs to `main`, worktrees) come from there.

## 4. Steps by size

| Step | Bug | Feature | Major | Read |
| --- | --- | --- | --- | --- |
| 2 Spec and decisions | — | yes | yes | `steps/spec.md` |
| 3 Environment | — | — | yes, when BC is involved | `steps/environment.md` |
| 4 Design | — | if a Mobi screen is added or changed | if a Mobi screen is added or changed | `steps/design.md` |
| 5 Build | yes | yes | yes | `steps/build.md` |
| 6 Prove | yes | yes | yes | `steps/prove.md` |
| 7 Stakeholders | — | — | yes | `steps/stakeholders.md` |
| 8 Docs and release notes | yes | yes | yes | `steps/docs.md` |
| 9 Ship | yes | yes | yes | `steps/ship.md` |

When you say what comes next (a plan, or after resuming), name what the rest of the path involves for the size:

- **Bug:** a test that fails before the fix, the fix, one PR, and a release-notes entry at `docs/release-notes/unreleased/<ISSUE-ID>.md`. A bug with UI steps in a mobi app is also reproduced in the running app before and after the fix, with screenshots in the PR (`steps/prove.md`).
- **Feature:** one PR per repo, then tests plus your own code review and, when a screen changes, a walkthrough of the flow in the running app with screenshots (`steps/prove.md`), then the release-notes entry, plus the manual page if users see the change.
- **Major:** one integration branch and one large PR, test campaigns, UI walkthroughs, a real-data run and CI, then release notes and a guide section with screenshots.

- **A bug goes straight from intake to step 5.**
- **BC pages never get a design step,** because BC dictates its own UI.
- **The size can go up at any step, never down.** When it becomes major, stop at G1. A bug that becomes a feature carries on as one.
- **You review the work yourself,** your subagents' included. Never another agent reviewing it, apart from one pass of `bcq-review` or of impeccable's finish review, and never review rounds between agents (`steps/build.md`, `steps/prove.md`).

## 5. Gates

Gates G1 to G6 and the two hand-offs ("needs a mockup", "needs a BC test run") are in `gates.md`. Read it the first time you reach a gate. In short:

- The issue's assignee passes G1, G2, G3 and G5, also on their own work; the team lead does when nobody is assigned. The team lead (Frederick Cleroux on Verovia, Stéphane on every other team) or Alexis can pass any gate. G4 and G6 are Stéphane's (`@stephane.levert`) on every team but Verovia, and Alexis's (`@alexisturgeon`) on Verovia; Alexis can pass them anywhere.
- **Decide what you can, ask the rest once.** Settle what the code, the issue and the repo's rules answer yourself. The G2 comment carries the spec, the open questions with your recommendations, the mockup when a screen changes, and every later approval you can foresee, so a run stops as rarely as possible. The answers approve it (`gates.md`).
- **An approver's own request counts.** When an approver asks for the work and their request already sets the size, says to implement it or says no design is needed, those gates are passed: don't stop to ask them again (`gates.md`).
- Anyone else, or an agent, posts the lifecycle comment on the issue, mentioning the gate's approver, and stops.
- Agents never merge.
