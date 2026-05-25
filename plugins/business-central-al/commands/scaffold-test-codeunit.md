---
name: scaffold-test-codeunit
description: Draft a Business Central AL test codeunit skeleton in the BCApps convention — Subtype = Test, EventSubscriberInstance = Manual, Library Assert (codeunit 130002), [TransactionModel] matching Commit behavior, Given/When/Then comments. Use when creating a new test codeunit for a behavior change.
---

# Scaffold a test codeunit (BCApps style)

Drop this skeleton when creating a new Business Central AL test codeunit. The shape mirrors what Microsoft uses across `microsoft/BCApps/src/System Application/Test/`.

`70015100` is an illustrative placeholder — replace it with a repository-appropriate object ID inside the user's allocated test range. Microsoft's `130000..139999` band is reserved.

```al
// ------------------------------------------------------------------------------------------------
// Copyright (c) <Publisher>. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace <Publisher>.<Domain>.Test;

using <Publisher>.<Domain>;
using System.TestLibraries.Utilities;
using System.TestLibraries.Security.AccessControl;

codeunit 70015100 "<Feature> Test"
{
    Subtype = Test;
    Permissions = tabledata "<Table 1>" = rd,
                  tabledata "<Table 2>" = rimd;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        LibraryVariableStorage: Codeunit "Library Variable Storage";
        PermissionsMock: Codeunit "Permissions Mock";
        IsInitialized: Boolean;
        ExpectedErrorMsg: Label '<expected error text>', Locked = true;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShouldDoExpectedThing()
    var
        // local variables here
    begin
        // [Scenario] <one-line description of what this test proves>
        Initialize();
        PermissionsMock.Set('<role name>');

        // [Given] <setup state>

        // [When] <the action under test>

        // [Then] <expected outcome>
        Assert.AreEqual(<expected>, <actual>, '<failure message describing what should have been true>');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShouldHandleUiInteraction()
    begin
        // [Scenario] <UI-driven scenario>
        Initialize();

        // [Given] <setup>
        LibraryVariableStorage.Enqueue(<expected dialog text>);

        // [When] <action that raises UI>

        // [Then] <state after dialog dismissed>
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure ShouldRaiseExpectedError()
    begin
        // [Scenario] <negative-path scenario>
        Initialize();

        // [Given] <invalid setup>

        // [When] <action expected to fail>
        ClearLastError();
        asserterror <CallThatErrors>();

        // [Then] The expected error is raised
        Assert.ExpectedError(ExpectedErrorMsg);
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        // one-shot setup the suite needs (e.g. seed reference data)
        IsInitialized := true;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.AreEqual(Format(ExpectedMessage), Message, 'Wrong message shown');
    end;
}
```

## Checklist when filling this in

- [ ] Pick an object ID inside the repo's allocated test ID range (not Microsoft's `130000..139999`).
- [ ] Replace `<Feature>` with a name that fits the convention used elsewhere in the repo's tests.
- [ ] Replace `<Publisher>` and the namespace path to match what existing `.al` files declare.
- [ ] Add `tabledata ... = rd|rimd` permissions for every table the tests touch. Avoid wildcards.
- [ ] Pick `TransactionModel::AutoRollback` (default), `AutoCommit` (code under test calls `Commit`), or `None` (read-only) per `al-testing` rule.
- [ ] One `[Scenario]` per `[Test]` procedure. Multiple scenarios = multiple procedures.
- [ ] Every `[HandlerFunctions(...)]` handler must be invoked during the test, and SHOULD assert on the values it receives.
- [ ] Use `Library Assert` (codeunit 130002), never plain `TestField` or `Error` in test code.
- [ ] Add dependencies to the test app's `app.json`: `Library Assert`, `Any`, `Library Variable Storage`, `Permissions Mock` (only those actually used).

## When to call this command

- Creating the first test codeunit in a new test app folder.
- Adding a new feature-area test codeunit (one codeunit per feature is the BCApps convention).
- When the agent realizes mid-task that a behavior change has no test coverage at all.
