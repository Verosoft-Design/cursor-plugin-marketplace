# Step 4: Design (only when a Mobi screen is added or changed)

BC pages never get a design step, because BC dictates its own UI.

1. **Make the mockup** in Open Design (the `open-design` MCP server) or Claude Design, whichever is reachable.
   - Open Design is a desktop app and only connects while it runs, so a headless agent usually can't reach it.
   - **If neither tool is reachable, make a quick mockup yourself.** Write one static HTML page per screen, in the spec folder at `mockups/<screen>.html`.
     - Give it the app's own look: copy the Tailwind classes, component markup, colors and spacing of the screen it changes, or of the closest existing screen.
     - Screenshot each page at desktop and phone width with a headless browser (`agent-browser`, or Playwright).
     - Attach the screenshots to the Linear issue and commit the HTML with the spec.
     - It's a picture for approval, not screen code: nothing in the app's source changes.
   - **Only if you can't render a screenshot** either, use the **"needs a mockup" hand-off** (see `gates.md`). Ask for a person to attach the mockup to the issue, set `Waiting on: needs a mockup`, and stop. The work resumes at G3 once the mockup is on the issue.
   - **The waiver:** the team lead or Alexis can say that no mockup is needed, in the agent's Linear thread or on the issue. That approves G3 without a mockup. Build the screens like the existing ones, and put screenshots of the built screens in the PR.
   - **Never write screen code before G3 is approved,** by an approved mockup or by that waiver.
2. **Record the design in the spec:** the design link, and a numbered list of design decisions (DD1, DD2…) for the reviewer to accept or change.
3. **Major only: publish a review site** so the team can weigh in.
   1. Copy `templates/review-site/` into the spec folder at `review-site/`, so its source is committed with the spec.
   2. Fill in `site.config.json` and add one HTML page per screen, each with a `<details class="review">` "What to review" note.
   3. Run `node scripts/build-knowledge.mjs`. It refuses to build if a customer name or a secret is found.
   4. Deploy with `vercel deploy --prod --scope verosoft-design`. Its Q&A bot answers from the spec folder, the guide and `team-faq.md`.
4. **G3 Design approval:** the team lead or Alexis. For major work the team weighs in first. Set `Waiting on: G3 Design approval (@<team lead>)`: `@frederick.cleroux` on Verovia, `@stephane.levert` otherwise.

Next: step 5.
