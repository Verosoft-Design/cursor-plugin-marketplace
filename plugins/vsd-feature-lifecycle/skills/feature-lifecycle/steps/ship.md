# Step 9: Ship

1. **G5 Merge:** a person merges the PR once the reviews and CI are green: the issue's assignee, or the team lead when nobody is assigned (Alexis can too). **Agents never merge.**
   - **On the agent server, feedback comes back to you.** Review comments (from people and the Verovia Review code and security reviews) and a failed CI run start you again, with the job in your reply file. Read the feedback with `gh`, address each point, and push. Then reply on GitHub to each comment, saying what you changed or why not, and post the G5 Merge comment again. CI gets one automatic fix; after that a person looks.
   - Mark the PR ready.
   - **A preview for the person who merges (mobi):** a PR branch gets a Vercel preview only when its PR gets the app's deploy label, `deploy-mobi` for Mobi. When the PR changes Mobi (`apps/mobi`, or a package it uses), add it once the PR is ready: `gh pr edit <PR> --add-label deploy-mobi`.
     - A workflow deploys the head commit once, comments the preview URL on the PR (after a few minutes) and removes the label. Put that link in the G5 comment.
     - After you push fixes, add the label again so the preview matches the PR.
     - Other apps get their own `deploy-<app>` label as they're set up: `gh label list --search deploy` shows which exist.
   - **The G5 comment shows the proof,** top-level on the issue, never in Linear's agent-session thread: the test result (red before the fix, green after) in the Ready line and, when the run has screenshots, the before/after images uploaded to Linear (`steps/prove.md`, step 5). The person who merges and the product owner read Linear, not only the PR.
   - **A QA test card, for the QA agent:** with the G5 comment, post a second top-level comment on the issue headed exactly `## QA test card`. A Verovia QA agent reads it later and checks the change in the live app the way a person would, with QA test accounts, after the release. Write it for that person, not for a developer:
     - **Where:** the app and the page or screen.
     - **Steps:** numbered, short: what to click, type or ask an agent.
     - **Expected:** what you should see on screen when it works, specific enough to tell a pass from a fail.
     - **Needs:** the test account role, test data, connector or setting. Never real customer data: name anything to create `QA <issue> <date>`.
     - **Leave to a person:** any step that needs money, a real device, outside people, customer data or a judgment call. Leave this line out when there's none.
     - When nothing can be seen in the app (backend, CI, logging, a fix proven only by tests), skip the card and say so in the G5 comment: `QA: auto, the tests are the check`.
     - On Verovia (VERO) issues, also add the QA tier label: `QA: agent` with a card, `QA: auto` without one, or `QA: human` when every check needs a person.
   - Set `Waiting on: G5 Merge (@<the assignee>)`. When nobody is assigned, mention the team lead: `@alexisturgeon` on Verovia, `@stephane.levert` otherwise.
   - Stop.
2. **Merging to `main` isn't a release.**
3. **G6 Release (Stéphane; Alexis on Verovia)** runs the `lifecycle-release` skill. It gathers the product's unreleased entries into that version's notes for Hub, then follows the product's own release process: AppSource for TAG, and the Vercel promotion for Mobi and Hub. Trax and Verovia have their own release instead, `bun run release:trax-verovia <version>` in mobi, as mobi's `docs/release-notes/unreleased/README.md` says.
4. **Once merged,** set the status block to `Step: 9 Ship` and `Waiting on: nothing`. The work is done.
