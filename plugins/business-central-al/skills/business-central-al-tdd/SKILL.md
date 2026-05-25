---
name: business-central-al-tdd
description: Guides Microsoft Dynamics 365 Business Central AL development with a TDD-first workflow aligned to BCApps testing conventions. Use when creating, modifying, extending, refactoring, or reviewing AL objects, test codeunits, handler methods, or Business Central testing structure.
---

# Business Central AL TDD

## Official References

For official Microsoft Learn references and deeper Business Central AL guidance, read [reference.md](reference.md). For the full BCApps-aligned testing rules (Library Assert, EventSubscriberInstance, TransactionModel, Given/When/Then), see the `al-testing` rule.

## Use This Skill When

- the user asks to build or change Business Central AL behavior
- the work touches `.al` files or Business Central test structure
- the user wants testing, TDD, or better AL development discipline

## Core Rules

1. Identify the AL object type before editing.
2. For behavior changes, prefer a failing test before production code.
3. Keep test code separate from production code (in a dedicated test app).
4. Use BCApps testing primitives correctly:
   - `Subtype = Test` on the test codeunit
   - `EventSubscriberInstance = Manual` on the test codeunit
   - `[Test]` `[Scope('OnPrem')]` `[TransactionModel(...)]` on each test procedure, matching the production code's `Commit` behavior
   - `Assert: Codeunit "Library Assert"` (codeunit **130002**, from BCApps; never plain `TestField` or `Error` in test code)
   - `HandlerFunctions('Name1,Name2')` and matching handler procedures for UI interaction
   - `asserterror` + `Assert.ExpectedError(text)` / `Assert.ExpectedErrorCode(code)` for negative tests
   - Given / When / Then narrative comments inside each test
5. Be explicit when tests cannot be executed in the current session.

## Workflow

### 1. Classify the work

Decide which category applies:

- behavior change in existing AL logic
- new Business Central feature or object
- test-only change
- metadata or documentation-only change

Use TDD for behavior changes and new features. For metadata-only or documentation-only edits, explain why automated tests are not the primary verification method and validate the affected files directly.

### 2. Choose the test surface first

Before writing production code, decide what should prove the change:

- test codeunit for business logic (`/scaffold-test-codeunit` produces the skeleton)
- handler methods for message, confirm, modal page, request page, or report interactions (`/scaffold-handler-methods` produces the handler templates)
- negative-path test for validation and business-rule failures
- positive-path test for successful state changes or outputs

### 3. Write the failing test first

When meaningful, start with the smallest failing test that expresses the desired Business Central behavior.

Prefer:

- one behavior per test (one `[Scenario]` tag per `[Test]` procedure)
- setup that is easy to understand; pull into `Initialize()` when reused
- assertions on outcome, state, or expected error via `Library Assert`
- Given / When / Then comment structure inside the test body

Avoid:

- large multi-scenario tests
- unnecessary mocks
- production code changes before the test exists
- plain `TestField`, `Error`, or platform `Assert` (codeunit 9) inside test code — use Library Assert (codeunit 130002)

### 4. Verify the red state honestly

If the current environment supports running the Business Central test flow, run the relevant test and confirm it fails for the expected reason.

If the current session cannot run the test runner:

- do not pretend the test was executed
- state that execution was not verified
- explain the expected failing condition
- note what command or environment step still needs to be run (e.g. "the user must press F5 in VS Code with the test runner attached, or run `Run-TestsInBcContainer` via BcContainerHelper")

### 5. Write the smallest implementation

Implement only enough production code to satisfy the failing test. Do not add extra features or unrelated cleanup in the same step.

### 6. Verify green and then refactor

After implementation:

- run the relevant tests when possible
- keep the output honest if execution could not be verified
- refactor only after the intended behavior is covered

## Business Central Testing Patterns (Quick Reference)

Use these defaults unless the repository already has a better-established pattern:

```al
codeunit <id> "<Feature> Test"
{
    Subtype = Test;
    Permissions = tabledata "<Table>" = rimd;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit "Library Assert";    // codeunit 130002 from BCApps

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShouldDoSomething()
    begin
        // [Scenario] <description>
        // [Given] <setup>
        // [When] <action>
        // [Then] <expected>
        Assert.AreEqual(<expected>, <actual>, '<failure message>');
    end;
}
```

Standard test-app dependencies in `app.json`:

- `Library Assert` (id `dd0be2ea-f733-4d65-bb34-a28f4624fb14`, codeunit 130002)
- `Any` (random value generator)
- `Library Variable Storage` (for getting data into handlers via `.Enqueue()` / `.Dequeue()`)
- `Permissions Mock` (for permission-restricted code: `PermissionsMock.Set('<role>')`)
- Domain libraries as needed (`Library Sales`, `Library Inventory`, …)

For negative tests:

```al
ClearLastError();
asserterror <CallThatErrors>();
Assert.ExpectedError(ExpectedErrorMsg);
// or by error code:
Assert.ExpectedErrorCode('Dialog');
```

## TransactionModel choice

| Value                    | When                                                                                                                                       |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `AutoRollback` (default) | Production code does NOT call `Commit()`. Test runs in a transaction that auto-rolls-back.                                                 |
| `AutoCommit`             | Production code calls `Commit()` (posting routines, job-queue handlers, integration flows). Pair with `TestIsolation` enabled test runner. |
| `None`                   | Read-only tests, or tests that drive UI without writing from the test method itself.                                                       |

Applying `AutoRollback` to a test whose code calls `Commit` errors at first Commit (infrastructure failure, not a useful assertion). Match the model to the code under test.

## If The Repo Has No Test Scaffold

Do not skip tests silently.

Instead:

1. Check whether the repo already has a test app, test folder, or test codeunits.
2. If not, create the smallest sensible starting point:
   - one test app folder with its own `app.json` declaring dependencies on `Test Framework`, `Library Assert` (codeunit 130002), `Any`, plus `Library Variable Storage` and `Permissions Mock` only when actually needed
   - one test codeunit with `Subtype = Test`, `EventSubscriberInstance = Manual`, `Assert: Codeunit "Library Assert"`
   - one `[Test]` `[Scope('OnPrem')]` `[TransactionModel(TransactionModel::AutoRollback)]` procedure for the requested behavior
   - handler methods only if the scenario raises UI
3. Document any missing environment or dependency that blocks execution.

The `/al-add-test-app` command (Phase 2) dispatches the AL-Go `Create a new test app` workflow to scaffold the test app folder. Use it before `/scaffold-test-codeunit` if no test app exists.

## Review Expectations

When reviewing AL changes, prioritize:

- missing or weak test coverage
- plain `TestField`, `Error`, or codeunit 9 `Assert` inside test code (must be Library Assert codeunit 130002)
- missing `EventSubscriberInstance = Manual` on test codeunits (causes test cross-pollution)
- mismatched `[TransactionModel]` (e.g. `AutoRollback` on code that calls `Commit`)
- missing Given/When/Then narrative inside test bodies
- handler procedures that swallow UI without asserting on the values
- production logic added without a preceding test
- missing negative-path coverage for business rules
- behavior claims that were not actually verified

## Output Expectations

When closing out work:

- say what behavior was changed
- say what test covers it (codeunit ID + procedure name)
- say whether the test was actually executed and how
- call out any remaining test setup or environment gaps
