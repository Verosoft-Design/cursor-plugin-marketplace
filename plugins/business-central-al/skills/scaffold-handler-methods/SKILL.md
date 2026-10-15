---
name: scaffold-handler-methods
description: Draft Business Central AL handler methods and HandlerFunctions wiring for automated tests that interact with UI elements.
disable-model-invocation: true
---

# Scaffold Handler Methods

Use this template when the tested code raises UI interaction. It assumes the test codeunit declares `Assert: Codeunit "Library Assert";` and `LibraryVariableStorage: Codeunit "Library - Variable Storage";` as globals.

```al
[Test]
[HandlerFunctions('MessageHandler,ConfirmHandler')]
procedure ShouldHandleUiInteraction()
begin
    // [GIVEN] <setup>

    // [WHEN] <action that raises the confirm, then the message>

    // [THEN] The dialogs showed the expected text
    Assert.AreEqual(<expected question>, LibraryVariableStorage.DequeueText(), 'Wrong confirm question');
    Assert.AreEqual(<expected message>, LibraryVariableStorage.DequeueText(), 'Wrong message');
    LibraryVariableStorage.AssertEmpty();
end;

[MessageHandler]
procedure MessageHandler(Message: Text[1024])
begin
    LibraryVariableStorage.Enqueue(Message);
end;

[ConfirmHandler]
procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
begin
    LibraryVariableStorage.Enqueue(Question);
    Reply := true;
end;
```

Guidance:

- only list handlers that are actually called by the test
- every handler named in `HandlerFunctions` must be invoked
- handlers only capture or set values (enqueue the text, set `Reply`, fill the request page); verify in the test body. This is the BC-Bench ALTest rule (see `al-write-test`), the measured AL test-generation prompt
- use `Library - Variable Storage` only if the test project already depends on it, and end the test with `LibraryVariableStorage.AssertEmpty()`
- use page, modal page, request page, or report handlers when the scenario requires them
