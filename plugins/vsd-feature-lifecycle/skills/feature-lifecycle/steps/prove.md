# Step 6: Prove

## The bar by size

- **Bug:** a test that fails before the fix and passes after.
  - Use superpowers `test-driven-development`, or business-central-al `business-central-al-tdd` in AL repos.
  - For anything non-obvious, use systematic debugging (superpowers `systematic-debugging`).
- **Bug with UI steps (mobi monorepo apps):** also reproduced in the running app before and after the fix, with screenshots. See "UI testing" below.
- **Feature:** tests for the new behavior, plus a code review, plus a walkthrough of the flow in the running app when a screen changes. See "UI testing" below. The code reviews:
  - `bcq-review` in AL repos;
  - `vsd-code-review` in Cursor;
  - `/code-review` in Claude Code.
- **Major:** all of the above, plus:
  - test campaigns per area;
  - TestPage tests for every new or changed BC page;
  - a browser walkthrough with screenshots (`al-ui-test` for BC, and a visual check for Mobi);
  - a read-only real-data run where an agreement exists (G4);
  - an upgrade test for BC;
  - CI on the PR.

## UI testing in the mobi monorepo apps (Mobi, Hub, Trax, Verovia)

Any bug with UI steps, and any feature that changes a screen, is proven in the **running app**, in addition to the committed tests above. How to sign in is in mobi's `docs/agents/development-access.md` and each app's `AGENTS.md`; follow them, don't copy them.

1. **Start the app's dev server** on localhost (Mobi 3000, Trax 3002, Verovia 3003, Hub 3004), then sign in with `bun run dev:login` from the app's folder. It saves `.auth/<app>/storage-state.json` for Playwright or agent-browser and `cookies.txt` for curl. Treat both as credentials and never commit them.
   - If dev login isn't set up on this machine (no `<APP>_DEV_AUTH_*` in the app's `.env.local`), use the **"needs UI test access"** hand-off in `gates.md`: a person runs the one-time `bun run dev:auth:setup`. Never skip the UI check.
2. **Use test data only:**
   - a test member, on the **Dev** environment and the **TA - TS** company;
   - never a customer environment or live business data;
   - create only the records the flow needs.

   Screenshots can't be scanned for customer names, so this rule is what keeps them clean. Tunnels (`bun run dev:tunnels`) are for people reviewing remotely, not for your own testing.
3. **Bug: reproduce, fix, reproduce.**
   - **Before changing any code,** follow the issue's steps in the app until you see the bug, and take a **before** screenshot.
   - **If you can't reproduce it,** stop and ask on the issue for the missing detail, with what you tried. Don't fix a bug you haven't seen.
   - **After the fix,** repeat the same steps and take an **after** screenshot.
4. **Feature: walk the flow.**
   - Go through the UX flow from the spec and the approved mockup as a user would, start to finish.
   - Include the edge cases the spec names: empty states, errors, permissions.
   - Take a screenshot of each key screen.
5. **Screenshots for the reviewer:**
   - Commit them to `docs/pr-assets/<PR number>/`. Open the PR as a draft first to get the number.
   - Show them in the PR description's Screenshots section, so the approver sees what was tested.
   - Keep them few and small.
6. **Committed browser tests:** add a Playwright test (in the app's `e2e/`) only when the flow is already in that app's e2e suite, or for major work. Otherwise the committed test is a unit or integration test, and the walkthrough is the UI proof.

## How AL tests run, in this order

1. **CI:** push the failing test, show the red run, then push the fix.
2. **Otherwise, a reachable BC server,** with `al-run-tests`.
3. **Otherwise, the "needs a BC test run" hand-off** (see `gates.md`). Never skip the failing test.

As of 2026-10, tag-bc `main` has no AL test workflow. Its tests sit behind `#if TESTS`, which a normal build doesn't define. The `PM tests` workflow and the test-build setup arrive with tag-bc #193, and until that merges, BC agent runs mostly end at the hand-off.

## Before a PR is marked ready

Run the customer-name check on the branch, the PR description and the release-notes entry:

```bash
python3 "<skill folder>/scripts/check_customer_names.py" --base origin/main <PR description file> docs/release-notes/unreleased/<ISSUE-ID>.md
```

- **Exit 1:** remove every name it lists (use "Customer A", "Customer B") and run it again.
- **Exit 2 with `no customer-name list` on stderr:** there's no names list on this machine. Write "Customer-name check not run: no names list on this machine." in the PR description and carry on. Any other error (a missing file, a missing `origin/main`) isn't this case: fix the command and run it again.

Finish with superpowers `verification-before-completion` if it's installed. Set the status block to `Step: 6 Prove`.

Next: step 7 for major work; otherwise step 8.
