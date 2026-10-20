# Step 4: Design (only when a Mobi screen is added or changed)

A small feature that only tweaks an existing screen (spacing, sizes, wording, a setting on an existing page) skips the mockup: screenshots of the built screen in the PR show it.

BC pages never get a design step, because BC dictates its own UI.

**For a feature, this step runs inside step 2:** make the mockup before the G2 stop, so the assignee approves the spec and the design in one comment. It runs on its own only when the spec was approved without a mockup, and for major work.

1. **Make the mockup** in Open Design (the `open-design` MCP server) or Claude Design, whichever is reachable.
   - Open Design only connects while its app or service runs. When its MCP server doesn't answer, use the next option.
   - **If neither tool is reachable, make a quick mockup yourself.** Write one static HTML page per screen, in the spec folder at `mockups/<screen>.html`. Design it with the impeccable skill when it's installed: it reads the app's `PRODUCT.md` and `DESIGN.md`.
     - Give it the app's own look: copy the Tailwind classes, component markup, colors and spacing of the screen it changes, or of the closest existing screen.
     - Screenshot each page at desktop and phone width with a headless browser (`agent-browser`, or Playwright).
     - Attach the screenshots to the Linear issue and commit the HTML with the spec.
     - It's a picture for approval, not screen code: nothing in the app's source changes.
   - **Only if you can't render a screenshot** either, ask for the mockup in the same G2 comment (or use the **"needs a mockup" hand-off**, see `gates.md`, when the spec is already approved): ask for a person to attach the mockup to the issue. The work resumes at G3 once it's there.
   - **Don't ask whether to make one.** When the change needs a mockup, make it; when it's only a tweak (above), skip it and say so. Never put "mockup or waiver?" to the approver.
   - **The waiver:** the assignee, the team lead or Alexis can say on their own that no mockup is needed, in the agent's Linear thread or on the issue. That approves G3 without a mockup. Build the screens like the existing ones, and put screenshots of the built screens in the PR.
   - **Never write screen code before G3 is approved,** by an approved mockup or by that waiver.
2. **Record the design in the spec:** the design link, and a numbered list of design decisions (DD1, DD2…) for the assignee to accept or change. Settle what the existing screens already answer yourself (`agent call`).
3. **Major only: publish a review site** so the team can weigh in.
   1. Copy `templates/review-site/` into the spec folder at `review-site/`, so its source is committed with the spec.
   2. Fill in `site.config.json` and add one HTML page per screen, each with a `<details class="review">` "What to review" note.
   3. Run `node scripts/build-knowledge.mjs`. It refuses to build if a customer name or a secret is found.
   4. Deploy with `vercel deploy --prod --scope verosoft-design`. Its Q&A bot answers from the spec folder, the guide and `team-faq.md`.
4. **G3 Design approval:** the issue's assignee, or the team lead when nobody is assigned (`@frederick.cleroux` on Verovia, `@stephane.levert` otherwise). For a feature it comes with G2. For major work the team weighs in first. Set `Waiting on: G3 Design approval (@<the assignee>)`.

Next: step 5.
