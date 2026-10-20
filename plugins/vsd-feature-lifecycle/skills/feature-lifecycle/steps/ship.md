# Step 9: Ship

1. **G5 Merge:** a person merges the PR once the reviews and CI are green: the issue's assignee, or the team lead when nobody is assigned (Alexis can too). **Agents never merge.**
   - **On the agent server, feedback comes back to you.** Review comments (from people and the Verovia Review code and security reviews) and a failed CI run start you again, with the job in your reply file. Read the feedback with `gh`, address each point, and push. Then reply on GitHub to each comment, saying what you changed or why not, and post the G5 Merge comment again. CI gets one automatic fix; after that a person looks.
   - Mark the PR ready.
   - **A preview for the person who merges (mobi):** a PR branch gets a Vercel preview only when its PR gets the app's deploy label, `deploy-mobi` for Mobi. When the PR changes Mobi (`apps/mobi`, or a package it uses), add it once the PR is ready: `gh pr edit <PR> --add-label deploy-mobi`.
     - A workflow deploys the head commit once, comments the preview URL on the PR (after a few minutes) and removes the label. Put that link in the G5 comment.
     - After you push fixes, add the label again so the preview matches the PR.
     - Other apps get their own `deploy-<app>` label as they're set up: `gh label list --search deploy` shows which exist.
   - Set `Waiting on: G5 Merge (@<the assignee>)`. When nobody is assigned, mention the team lead: `@frederick.cleroux` on Verovia, `@stephane.levert` otherwise.
   - Stop.
2. **Merging to `main` isn't a release.**
3. **G6 Release (Alexis)** runs the `lifecycle-release` skill. It gathers the product's unreleased entries into that version's notes for Hub, then follows the product's own release process: AppSource for TAG, and the Vercel promotion for Mobi and Hub.
4. **Once merged,** set the status block to `Step: 9 Ship` and `Waiting on: nothing`. The work is done.
