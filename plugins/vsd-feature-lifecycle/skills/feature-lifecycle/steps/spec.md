# Step 2: Spec and decisions (feature and major)

The spec lives in its home repo (BC only: the BC repo; Mobi only, or BC and Mobi together: mobi). Linear issues, Linear documents and the other repo only **link** to it. Never copy a spec or a decision list anywhere else.

## Feature

1. **Brainstorm briefly.** Use superpowers `brainstorming` if it's installed; otherwise ask a few focused questions yourself. Keep it short: a feature is a change inside an existing process.
2. **Write the spec** from `templates/feature-spec.md` to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`. Every question asked and answered goes into its `## Decisions` list, numbered (D1, D2…), with who answered.
3. **G2 Spec approval** (see `gates.md`). Set the status block to `Step: 2 Spec` and `Waiting on: G2 Spec approval (@stephane.levert)`.
4. **After G2:**
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
2. **Grill in rounds.** Use mattpocock-skills `grilling` if it's installed; otherwise ask the whole round of numbered questions yourself, each with your recommendation.
   - Append each round to `decision-log.md`: a `## Round N: <topic> (<date>)` heading, then a table with the columns `#`, `Question`, `Recommendation` and `Answer`.
   - IDs are stable (Q1, Q2…). Series letters are allowed for themed rounds (U, C, E…).
   - Each entry's status is Decided, Pending or Info. A decision made during implementation and reported afterwards is marked "controller call".
3. **Copy every binding outcome into `decisions.md`.** Where `decisions.md` and the rest of the spec disagree, `decisions.md` wins.
4. **G2 Spec approval after each round.**
5. **After the last round:**
   - Write a plan per phase (superpowers `writing-plans`).
   - Link the folder from the Linear project and its issues. Never paste decisions into Linear documents.

## Work across BC and Mobi

The spec is in mobi. Once G2 approves it, the spec goes into mobi `main` through its **own small docs PR**, before any code, so the tag-bc side (or an agent that only has tag-bc) reads it from `main` and every link stays valid.

## Never

- **Customer names:** never write one in a spec. Use "Customer A", "Customer B".
- **Copies:** never keep a second copy of the spec or of the decisions.

Next: step 3 for major work that involves BC; otherwise step 4 if a Mobi screen changes; otherwise step 5.
