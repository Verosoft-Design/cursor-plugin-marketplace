---
name: business-central-al-tdd
description: Guides Microsoft Dynamics 365 Business Central AL development with a TDD-first workflow. Use when creating, modifying, extending, refactoring, or reviewing AL objects, test codeunits, handler methods, or Business Central testing structure.
---

# Business Central AL TDD

## Official References

For official Microsoft Learn references and deeper Business Central AL guidance, read [reference.md](reference.md).

## Use This Skill When

- the user asks to build or change Business Central AL behavior
- the work touches `.al` files or Business Central test structure
- the user wants testing, TDD, or better AL development discipline

## Core Rules

1. Identify the AL object type before editing.
2. For behavior changes, prefer a failing test before production code.
3. Keep test code separate from production code.
4. Use Business Central testing primitives correctly:
   - `SubType = Test`
   - `[Test]`
   - handler methods
   - `HandlerFunctions`
   - `AssertError` in test code only
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

- test codeunit for business logic
- handler methods for message, confirm, modal page, request page, or report interactions
- negative-path test for validation and business-rule failures
- positive-path test for successful state changes or outputs

### 3. Write the failing test first

When meaningful, start with the smallest failing test that expresses the desired Business Central behavior.

Prefer:

- one behavior per test
- setup that is easy to understand
- assertions on outcome, state, or expected error

Avoid:

- large multi-scenario tests
- unnecessary mocks
- production code changes before the test exists

### 4. Verify the red state honestly

If the current environment supports running the Business Central test flow, run the relevant test and confirm it fails for the expected reason.

If the current session cannot run the test runner:

- do not pretend the test was executed
- state that execution was not verified
- explain the expected failing condition
- note what command or environment step still needs to be run

### 5. Write the smallest implementation

Implement only enough production code to satisfy the failing test. Do not add extra features or unrelated cleanup in the same step.

### 6. Verify green and then refactor

After implementation:

- run the relevant tests when possible
- keep the output honest if execution could not be verified
- refactor only after the intended behavior is covered

## Business Central Testing Patterns

Use these defaults unless the repository already has a better-established pattern:

- test codeunits should use `SubType = Test`
- each test case should use `[Test]`
- shared setup belongs in normal helper procedures
- UI interactions should be handled with specific handler methods
- tests should cover both success and failure conditions

For negative tests:

- use `AssertError` for expected failures
- validate the intended error text or failure condition
- ensure invalid data does not leave the system in an unexpected state

## If The Repo Has No Test Scaffold

Do not skip tests silently.

Instead:

1. Check whether the repo already has a test app, test folder, or test codeunits.
2. If not, create the smallest sensible starting point:
   - one test codeunit with `SubType = Test`
   - one `[Test]` procedure for the requested behavior
   - handler methods only if the scenario raises UI
3. Document any missing environment or dependency that blocks execution.

## Review Expectations

When reviewing AL changes, prioritize:

- missing or weak test coverage
- incorrect use of test codeunits or handler methods
- production logic added without a preceding test
- missing negative-path coverage for business rules
- behavior claims that were not actually verified

## Output Expectations

When closing out work:

- say what behavior was changed
- say what test covers it
- say whether the test was actually executed
- call out any remaining test setup or environment gaps
