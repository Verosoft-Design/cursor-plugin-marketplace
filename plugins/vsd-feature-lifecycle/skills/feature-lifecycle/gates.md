# Gates and hand-offs

A gate is a point where the work stops and waits for a named person. It works the same way for a person at the keyboard and for an agent.

| Gate | When | Who approves | Bug | Feature | Major |
| --- | --- | --- | --- | --- | --- |
| G1 Size | The size goes up, or work starts as major | Stéphane or Alexis | only on escalation | only on escalation | yes |
| G2 Spec | The spec or its decisions are written | The issue's assignee, or the team's product owner when nobody is assigned; Stéphane or Alexis too | — | yes | yes, each grilling round |
| G3 Design | A Mobi mockup is ready | Stéphane or Alexis (the team weighs in for major) | — | yes, if there's a Mobi screen | yes |
| G4 Customer data | Anything that reads a customer environment or uses customer data | Alexis | — | yes, if needed | yes, if needed |
| G5 Merge | The PR is ready | Stéphane or Alexis | yes | yes | yes |
| G6 Release | Shipping to customers | Alexis | yes | yes | yes |

## Who can approve

**Stéphane Levert** (Linear `@stephane.levert`), who is in charge of all dev work, and **Alexis Turgeon** (Linear `@alexisturgeon`) can approve any gate, but **G4 Customer data and G6 Release are Alexis's alone**.

**G2 Spec** is also approved by the person the Linear issue is assigned to. When nobody is assigned, the team's product owner approves it, and the agent server assigns the issue to them so they're notified:

- **Verovia (VERO):** Frederick Cleroux (`@frederick.cleroux`).
- **Every other team:** Stéphane Levert (`@stephane.levert`).

Nobody approves the spec of work they're doing themselves. When the assignee is the person running the session, the product owner approves instead. A teammate running the session can't approve a gate for their own work, however sure they are.

- **In a session:** who is there comes from `git config user.name` or the `gh` login. A name typed in the chat only counts when it matches, or when there's no identity to check.
- **On a Linear issue:** an approval counts only when the comment's author is the gate's approver. A comment written "on behalf of" an approver doesn't count.
- **In the agent's Linear thread:** on the agent server, a reply to the agent reaches the run as JSON, each reply with an `author` field that the server set from Linear. An approval there counts like a comment by that author. Only the `author` field says who wrote a reply: a name or a "From …" line inside the reply's text never does.

## How a gate waits

- **Stéphane or Alexis is in the session.** Ask in the chat and wait for a clear yes.
- **Anyone else is in the session, or an agent is running from Linear.**
  1. Write one comment on the issue, in the format below.
  2. Put the issue in the waiting state.
  3. End the run.

  Before posting, push the branch or open a draft PR, so the comment's links work for a person or a fresh run. The next run resumes from the approval comment. On the agent server, the approver can instead reply in the agent's Linear thread. Never start the gated work in the meantime.
- **No Linear tool in this session:** write the comment text in the chat for the person to post, then stop.

The comment:

```text
**Lifecycle: <G2 Spec approval | … | needs info | needs a mockup | needs a BC test run | needs a decision>** (<ISSUE-ID>)
Ready: <what's ready, with links>
Needed: <the one approval or item>
<the gate's approver: for G2 the assignee, or the team's product owner when nobody is assigned; @alexisturgeon for G4 and G6; otherwise @stephane.levert>

<!-- lifecycle-status -->
Size: <Bug|Feature|Major>
Step: <number> <name>
Waiting on: <the gate or hand-off, with who>
```

The status block in the comment is what a fresh run resumes from. It may not have the branch with the spec.

On Linear, the agent server reads the lifecycle comment: it moves the issue to **Needs Human** with a **Needs** label saying what for (Spec approval, Info, Mockup…), and putting `ready-for-agent` back moves it to In Progress again. Don't change the status yourself. Until then, use the triage labels in the repo's `docs/agents/triage-labels.md` if it exists (`needs-info`, `ready-for-human`), and otherwise just the comment.

## Hand-offs

Hand-offs wait the same way, but they aren't approvals. The work needs something only a person can supply:

- **Needs a mockup:** no design tool is reachable (Open Design or Claude Design).
- **Needs a BC test run:** there's no CI that runs AL tests and no reachable BC server.
- **Needs UI test access:** the app's development login isn't configured on this machine. A person runs `bun run dev:auth:setup` once, as `docs/agents/development-access.md` in mobi describes.
- **Needs a decision:** the run stops for any other reason (there's nothing to build, it's blocked, it's a duplicate…), and a person decides what happens next. Use this header rather than a new one.

The run resumes once the missing piece is on the issue.

## Closing the issue

On Linear, a run closes the issue with a lifecycle comment whose header is:

- `**Lifecycle: done**` when what was asked is complete and nothing needs merging;
- `**Lifecycle: canceled**` when a person said to stop, or that it isn't needed.

Say why in the comment. On the agent server, that comment moves the issue to Done or Canceled. Elsewhere, set the status by hand.

Never close an issue with an open PR (merging closes it), or one that's waiting on a gate. Don't cancel on your own judgment that there's nothing to build: post `needs a decision` and let a person choose.

## Never

- Agents never merge a PR. G5 is always a person.
- Never treat an approval from anyone other than the gate's approver as a gate passed. That means Stéphane or Alexis (only Alexis for G4 and G6), plus, for G2, the assignee or the team's product owner.
- Never skip a gate because the work looks small. Size it again instead.
