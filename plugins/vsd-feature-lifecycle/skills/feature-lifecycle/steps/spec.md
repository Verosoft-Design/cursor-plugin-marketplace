# Step 2: Spec and decisions (feature and major)

The spec lives in its home repo (BC only: the BC repo; Mobi only, or BC and Mobi together: mobi). Linear issues, Linear documents and the other repo only **link** to it. Never copy a spec or a decision list anywhere else.

## Feature

**A small feature with a settled scope goes straight to the build.** That's a change in one app, a few files, nothing on the "When the size goes up" list, and no open question. Its scope is settled when the request says what to do, an approver decided it, or your own earlier answer on the issue described it and nobody disputed it. Then don't stop at G2. Put the short decision list in the PR description instead of a spec file, build, and open the PR; G5 is where a person reviews it. Say so in your comment ("small, scope settled: building"). Stop at G2 only when there's an open question or the feature is bigger than that.

The assignee decides this feature (`gates.md`): the questions go to them, and their answers approve the spec.

1. **Decide what you can.** Read the code, the issue and the repo's rules first. Every question they answer, settle yourself and record it in the decision list as your call, with where the answer came from (`agent call, from <file or comment>`). Don't ask the assignee what the code already says.
2. **Grill the assignee on the rest:** the questions only a person can answer, such as what users expect, a trade-off between two behaviors, or what's out of scope. Use mattpocock-skills `grilling` (or superpowers `brainstorming`) if it's installed; otherwise ask the whole round yourself, numbered, each with your recommendation.
   - **The assignee is in the session:** ask in the chat, a round at a time, until nothing is open.
   - **Anyone else, or an agent from Linear:** the questions go in the G2 comment.
   - **No open question left:** don't invent one. The spec still stops at G2, unless the feature is small with a settled scope (above).
3. **Write the spec** from `templates/feature-spec.md` to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`. Every question goes into its `## Decisions` list, numbered (D1, D2…), with who decided: the assignee, the team lead, Alexis, or `agent call`. Questions still open are marked open, with your recommendation.
4. **A Mobi screen is added or changed? Make the mockup now** (step 4), before you stop, so the assignee approves the spec and the design in one stop.
5. **G2 Spec approval** (see `gates.md`), in one comment: the spec, the open questions, the mockup if there is one, and every later approval you can foresee. Set the status block to `Step: 2 Spec` and `Waiting on: G2 Spec approval (@<the issue's assignee, or the team lead when nobody is assigned>)`; with a mockup, `Waiting on: G2 Spec and G3 Design approval (@…)`.
6. **The answers approve it.** When the assignee answers the questions and asks for no other change, write their answers into the decisions and carry on: that passes G2, and G3 too when the mockup was in the same comment. Don't ask them to approve again. Stop again only when an answer opens a question you can't settle.
7. **After G2:**
   - Write a plan with superpowers `writing-plans` if it's installed, to `docs/superpowers/plans/YYYY-MM-DD-<topic>.md`.
   - Link the spec from the Linear issue.

## Major

1. **Create the folder** `docs/superpowers/specs/YYYY-MM-DD-<topic>/` from `templates/major/`:
   - `README.md`
   - `design.md`
   - `data-model.md` (if there's data)
   - `migration.md` (if there's a migration or conversion)
   - `delivery-plan.md`
   - `open-questions.md`
   - `decisions.md`
   - `decision-log.md`
   - `team-faq.md`
2. **Grill the assignee in rounds.** Settle what the code and the existing spec answer yourself first, and log it as an agent call. Use mattpocock-skills `grilling` if it's installed; otherwise ask the whole round of numbered questions yourself, each with your recommendation.
   - Append each round to `decision-log.md`: a `## Round N: <topic> (<date>)` heading, then a table with the columns `#`, `Question`, `Recommendation` and `Answer`.
   - IDs are stable (Q1, Q2…). Series letters are allowed for themed rounds (U, C, E…).
   - Each entry's status is Decided, Pending or Info. A decision made during implementation and reported afterwards is marked "controller call".
3. **Copy every binding outcome into `decisions.md`.** Where `decisions.md` and the rest of the spec disagree, `decisions.md` wins.
4. **G2 Spec approval after each round,** by the assignee. Their answers to a round approve it, as for a feature.
5. **After the last round:**
   - Write a plan per phase (superpowers `writing-plans`).
   - Link the folder from the Linear project and its issues. Never paste decisions into Linear documents.

## Work across BC and Mobi

The spec is in mobi. Once G2 approves it, the spec goes into mobi `main` through its **own small docs PR**, before any code, so the tag-bc side (or an agent that only has tag-bc) reads it from `main` and every link stays valid.

## Never

- **Customer names:** never write one in a spec. Use "Customer A", "Customer B".
- **Copies:** never keep a second copy of the spec or of the decisions.

Next: step 3 for major work that involves BC; otherwise step 4 if a Mobi screen changes and its mockup isn't approved yet; otherwise step 5.
