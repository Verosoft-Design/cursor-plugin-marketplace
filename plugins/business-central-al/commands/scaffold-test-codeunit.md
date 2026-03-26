---
name: scaffold-test-codeunit
description: Draft a Business Central AL test codeunit skeleton for the target behavior, including setup and positive or negative test cases.
---

# Scaffold Test Codeunit

Use this template when creating a new Business Central AL test codeunit:

`50100` is an illustrative placeholder only. Replace it with a repository-appropriate object ID.

```al
codeunit 50100 "My Feature Tests"
{
    SubType = Test;

    [Test]
    procedure ShouldDoExpectedThing()
    begin
        // Arrange

        // Act

        // Assert
    end;

    local procedure CreateRequiredSetup()
    begin
    end;
}
```

Checklist:

- choose a repository-appropriate object ID and object name
- keep one behavior per `[Test]` procedure
- add a negative test if the behavior can fail
- keep helper procedures local unless there is a clear reason not to
- keep test code separate from production code
