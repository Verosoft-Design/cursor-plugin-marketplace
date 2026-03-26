---
name: scaffold-handler-methods
description: Draft Business Central AL handler methods and HandlerFunctions wiring for automated tests that interact with UI elements.
---

# Scaffold Handler Methods

Use this template when the tested code raises UI interaction:

```al
[Test]
[HandlerFunctions('MessageHandler,ConfirmHandler')]
procedure ShouldHandleUiInteraction()
begin
    // Arrange

    // Act

    // Assert
end;

[MessageHandler]
procedure MessageHandler(Message: Text[1024])
begin
    // Validate the expected message.
end;

[ConfirmHandler]
procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
begin
    // Validate the expected question and set Reply.
end;
```

Guidance:

- only list handlers that are actually called by the test
- every handler named in `HandlerFunctions` must be invoked
- validate the UI text or behavior inside the handler
- use page, modal page, request page, or report handlers when the scenario requires them
