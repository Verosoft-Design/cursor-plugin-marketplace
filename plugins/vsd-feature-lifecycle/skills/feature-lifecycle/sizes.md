# Sizes

Every piece of work is a **Bug**, a **Feature** or a **Major** change. Use this table to pick the size and to see what each size needs.


| | Bug | Feature | Major change |
| --- | --- | --- | --- |
| **What it is** | Behavior that's wrong against what was already agreed | New or changed behavior inside an existing process | A core process redesigned, a data migration or a customer conversion, a new module |
| **Spec** | None. The Linear issue is the spec. | One spec file with a short numbered decision list inside it | A spec folder like PM's, with `decisions.md` and `decision-log.md` |
| **Decisions** | None | A short brainstorm; questions and answers go into the spec's decision list | Grilling rounds; every question and answer goes into `decision-log.md`, binding rules into `decisions.md` |
| **Design** | None | A quick mockup if it adds or changes a Mobi screen | Mobi mockups on a shareable review site with a Q&A bot |
| **Environment** | What the repo already has | What the repo already has | Dedicated BC test servers when BC is involved |
| **Build** | One PR | One PR (per repo) | One integration branch, phase branches merged into it, one large PR |
| **Prove** | A test that fails before the fix | Tests, plus a code review | Test campaigns, UI tests and walkthroughs, a real-data run, CI on the PR |
| **Docs** | A release-notes entry | A release-notes entry, plus the manual page if users see the change | A release-notes entry and a full guide section with screenshots |
| **Stakeholders** | No | No | The team reviews the design and the decision log |

## When the size goes up

The size can go up, never down. An agent applies this list mechanically. Hitting any item means it stops, says which item it hit, and waits for approval of the new size (gate G1).

- **Bug becomes a feature** when the fix needs any of these:
  - a new table, field, API page, API entity or enum value;
  - a change to what a screen shows or how it behaves, beyond restoring agreed behavior;
  - new user-facing text, other than fixing existing wording;
  - a new permission, or a change to a permission set;
  - a change in two repos.
- **Feature becomes a major change** when it needs any of these:
  - an upgrade codeunit that changes existing data, or any data migration;
  - a conversion customers have to run;
  - a change to a core process: PM scheduling, work order posting, inventory, purchasing, costing, or meter handling;
  - more than about two weeks of work, or more than one phase.

