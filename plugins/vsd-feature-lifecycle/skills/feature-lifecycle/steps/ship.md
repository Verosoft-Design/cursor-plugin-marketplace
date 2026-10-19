# Step 9: Ship

1. **G5 Merge:** a person (the team lead or Alexis) merges the PR. **Agents never merge.**
   - **On the agent server, feedback comes back to you.** Review comments (from people and the Verovia Review code and security reviews) and a failed CI run start you again, with the job in your reply file. Read the feedback with `gh`, address each point, and push. Then reply on GitHub to each comment, saying what you changed or why not, and post the G5 Merge comment again. CI gets one automatic fix; after that a person looks.
   - Mark the PR ready.
   - Set `Waiting on: G5 Merge (@<team lead>)`: `@frederick.cleroux` on Verovia, `@stephane.levert` otherwise.
   - Stop.
2. **Merging to `main` isn't a release.**
3. **G6 Release (Alexis)** runs the `lifecycle-release` skill. It gathers the product's unreleased entries into that version's notes for Hub, then follows the product's own release process: AppSource for TAG, and the Vercel promotion for Mobi and Hub.
4. **Once merged,** set the status block to `Step: 9 Ship` and `Waiting on: nothing`. The work is done.
