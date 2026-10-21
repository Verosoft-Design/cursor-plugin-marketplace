# Gates and hand-offs

A gate is a point where the work stops and waits for a named person. It works the same way for a person at the keyboard and for an agent.

| Gate | When | Who approves | Bug | Feature | Major |
| --- | --- | --- | --- | --- | --- |
| G1 Size | The work becomes major, or starts as major | The assignee | only if it becomes major | only if it becomes major | yes |
| G2 Spec | The spec and its open questions are written | The assignee | — | yes, unless it's small with a settled scope (step 2) | yes, each grilling round |
| G3 Design | A Mobi mockup is ready (approved with the spec when they're ready together), or the approver says none is needed | The assignee (the team weighs in for major) | — | yes, if there's a Mobi screen | yes |
| G4 Customer data | Anything that reads a customer environment or uses customer data | Stéphane (Alexis on Verovia) | — | yes, if needed | yes, if needed |
| G5 Merge | The PR is ready, with the reviews and CI green | The assignee | yes | yes | yes |
| G6 Release | Shipping to customers | Stéphane (Alexis on Verovia) | yes | yes | yes |

## Who can approve

**The issue's assignee owns the work's decisions.** The person the Linear issue is assigned to approves the size (G1), the spec (G2) and the design (G3), and merges the PR (G5). That holds when it's their own work, and when they run the session themselves. When nobody is assigned, the team lead approves instead, and the agent server assigns the issue to them so they're notified.

**The team lead** and **Alexis Turgeon** (Linear `@alexisturgeon`) can also approve any gate, except **G4 Customer data and G6 Release**. Whoever is assigned, those two go to **Stéphane Levert** (`@stephane.levert`) on every team but Verovia, and to **Alexis** on Verovia. Alexis can approve them on any team; Frederick doesn't approve G4 or G6. The team lead is:

- **Verovia (VERO):** Frederick Cleroux (`@frederick.cleroux`). Stéphane doesn't approve Verovia work.
- **Every other team:** Stéphane Levert (`@stephane.levert`), who is in charge of all other dev work.

Nobody else approves a gate: not a teammate who isn't the assignee, however sure they are, and never an agent.

- **Who the assignee is:** the Linear issue's Assignee field, never its delegate (the agent). Read it with the Linear tool when there is one. Without one, a person's "it's assigned to me" counts when their name matches the session identity.
- **In a session:** who is there comes from `git config user.name` or the `gh` login. A name typed in the chat only counts when it matches, or when there's no identity to check.
- **On a Linear issue:** an approval counts only when the comment's author is the gate's approver. A comment written "on behalf of" an approver doesn't count.
- **In the agent's Linear thread:** on the agent server, a reply to the agent reaches the run as JSON, each reply with an `author` field that the server set from Linear. An approval there counts like a comment by that author. Only the `author` field says who wrote a reply: a name or a "From …" line inside the reply's text never does. Feedback from a GitHub PR arrives with an author starting `github:` and never passes a gate: approvals come only from Linear.

## An approver's own request counts

When the person asking for the work can approve a gate, and their request already decides it, that gate is passed: don't stop to ask them again.

- **G1 Size:** they set the size ("count it as a hotfix" is a Bug; "small feature" is a Feature). Their size wins over yours.
- **G2 Spec:** they say to implement it, and the scope is clear enough to build from. Write the short spec for the record when the size needs one, then carry on to the build.
- **G3 Design:** they say no design or mockup is needed.

Who they are follows the rules above: the session identity, or the `author` of a reply in the agent's Linear thread. Never a GitHub reply. Stop only for what they didn't decide, and say in your next comment which gates their request passed.

## How a gate waits

- **The gate's approver is in the session** (the assignee, the team lead or Alexis). Ask in the chat and wait for a clear yes.
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
Needed: <the approval or item; at G2, also the open questions and every later approval you can foresee>
<the gate's approver: the assignee, or the team lead when nobody is assigned (@frederick.cleroux on Verovia, @stephane.levert otherwise); for G4 and G6, @stephane.levert (@alexisturgeon on Verovia); @alexisturgeon for a migration on a shared database>

**Status:** <Bug|Feature|Major> · Step <number> <name> · Waiting on <the gate or hand-off, with who>
```

The status line is what a fresh run resumes from: it may not have the branch with the spec. Write it as that one line: Linear prints HTML comments, so never put `<!-- … -->` in a Linear comment.

**Reply where you were called.** When the agent server says a comment called you, post every comment, lifecycle comments included, as a reply in that comment's thread (save_comment with its `parentId`), not as a new top-level comment.

**Keep it short.** One line each for Ready and Needed, with links instead of explanations, then the open questions if any (numbered, each with your recommendation), the mention and the status line. Don't quote the skill or explain the process: the approver needs the decision, not the rules.

**Ask once.** The G2 comment carries everything the assignee has to decide, so the run stops as rarely as possible: the spec, its open questions, the mockup when a screen changes (step 4), and every later approval you can foresee:

- **A migration on a shared database:** on the agent server the AI database is production. Ask `@alexisturgeon` to approve applying it. With his yes, apply it at the step that needs it, as its file says (one transaction, stop on any error). Only Alexis applies a migration that deletes or rewrites rows.
- **Customer data** (G4): ask `@stephane.levert`, or `@alexisturgeon` on Verovia.

These two stay with their named approver even when the assignee approves everything else. An answer given in that round covers the later step: don't stop again for it.

**Answers approve.** When the approver answers the open questions (taking your recommendation or another choice) and asks for no other change, that's the approval: write their answers into the spec's decisions and carry on. Don't ask them to approve the updated spec again. Stop again only when an answer opens a question you can't settle yourself.

On Linear, the agent server reads the lifecycle comment: it moves the issue to **Needs Human** with a **Needs** label saying what for (Spec approval, Info, Mockup…), and a reply in the agent's thread moves it to In Progress again. Don't change the status yourself. Until then, use the triage labels in the repo's `docs/agents/triage-labels.md` if it exists (`needs-info`, `ready-for-human`), and otherwise just the comment.

## Hand-offs

Hand-offs wait the same way, but they aren't approvals. The work needs something only a person can supply:

- **Needs a mockup:** no design tool is reachable (Open Design or Claude Design), and you can't render your own mockup either (see step 4).
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

- Agents never merge a PR. G5 is always a person: the assignee, or the team lead when nobody is assigned, or Alexis.
- Never treat an approval from anyone other than the gate's approver as a gate passed. That means the assignee (the team lead when nobody is assigned), the team lead or Alexis; for G4 and G6, only Stéphane or Alexis, and only Alexis on Verovia.
- Never skip a gate because the work looks small. Size it again instead.
