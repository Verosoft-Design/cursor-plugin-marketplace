# Step 6: Prove

## The bar by size

- **Bug:** a test that fails before the fix and passes after.
  - Use superpowers `test-driven-development`, or business-central-al `business-central-al-tdd` in AL repos.
  - For anything non-obvious, use systematic debugging (superpowers `systematic-debugging`).
- **Feature:** tests for the new behavior, plus a code review:
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
