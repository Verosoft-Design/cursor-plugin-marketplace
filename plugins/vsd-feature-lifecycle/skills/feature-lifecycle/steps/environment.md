# Step 3: Environment (major, when BC is involved)

1. **Set up BC test servers before any code.** On the agent server there's nothing to set up: `al-test` already has three tenants on the agents' BC server (`steps/prove.md`, "How AL tests run"). Elsewhere, use business-central-al `bc-server-setup` if it's installed; on Windows with Docker, it proposes a local container first. Write down the servers and how to publish and run tests in the spec's `delivery-plan.md`, without passwords.
2. **Customer data is gate G4.** Anything that reads a customer environment or uses customer data waits for Stéphane, or Alexis on Verovia (see `gates.md`).
   - Customer data is used read-only, only where an agreement exists.
   - It never goes into a repo, a PR or a release note.
3. **Set the status block** to `Step: 3 Environment`.

Next: step 4 if a Mobi screen changes; otherwise step 5.
