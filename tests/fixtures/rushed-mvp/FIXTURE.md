# Test Fixture: rushed-mvp

## Scenario

"We shipped it fast for demo day. What did we miss?"

This fixture simulates a project rushed to production. The code works but has significant issues that will cause problems at scale or during maintenance.

## What Bosun Should Find

### Quality Issues (6 findings)
- **no-error-handling.ts**: Missing try/catch on async operations, unhandled promise rejections, no input validation
- **copy-paste-code.go**: Validation logic duplicated 3-4x, magic numbers without explanation, hardcoded config

### Performance Issues (4 findings)
- **n-plus-one.py**: Classic N+1 queries, nested N+1 (N*M queries), in-memory pagination, unbatched updates

### Documentation Issues (2 findings)
- **README.md**: Missing installation steps, no API docs, placeholder TODOs, "Ask John" contribution guide

### Testing Issues (1 finding)
- No test files present in the project

### Security Issues (2 findings)
- SQL injection via string interpolation in TypeScript and Python files

## Running the Test

```bash
cd tests/fixtures/rushed-mvp
bosun /audit full .
```

## Expected Output

Bosun should identify approximately 15 findings across 5 categories. See `expected-findings.json` for the complete expected output.

## Value Demonstration

This fixture demonstrates that Bosun:
1. Catches issues across multiple languages (TypeScript, Python, Go)
2. Identifies performance problems before they hit production
3. Flags code quality issues that lead to maintenance burden
4. Notices documentation gaps
5. Reminds developers to add tests

**Key message**: "You shipped fast. Here's what to fix before it bites you."
