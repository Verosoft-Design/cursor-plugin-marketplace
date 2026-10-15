---
name: tdd-checklist
description: Provides a short AL-specific TDD checklist for Business Central behavior changes.
disable-model-invocation: true
---

# AL TDD Checklist

Use this checklist during Business Central AL work:

- [ ] Identified the AL object type involved
- [ ] Chosen the correct test surface before editing production code
- [ ] Written or updated a failing test first when behavior changed
- [ ] Covered the positive path
- [ ] Covered the negative path when business rules can fail
- [ ] Used `AssertError` for expected failures when appropriate
- [ ] Added handler methods if the scenario raises UI; handlers only set or enqueue values, and the test body asserts
- [ ] Confirmed the new test fails for the reported reason before the fix, not just that it compiles
- [ ] Implemented only the minimum production change
- [ ] Verified test execution, or clearly stated that execution could not be verified
- [ ] Kept test code separate from production code
- [ ] Summarized what is covered and what still needs verification
