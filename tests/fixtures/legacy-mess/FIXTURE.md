# Test Fixture: legacy-mess

## Scenario

"I inherited this codebase. The original author left 3 years ago. Help me understand what's wrong and prioritize improvements."

This fixture simulates a legacy codebase that has grown organically without architectural guidance. The code works but is difficult to maintain, test, and extend.

## What Bosun Should Find

### Architecture Issues (5 findings)
- **god-object.ts**: 580+ line class handling 7+ distinct responsibilities (users, orders, products, notifications, payments, reporting, search)
- **god-object.ts**: Singleton pattern that prevents testing
- **god-object.ts**: Mixed concerns - business logic triggers notifications, analytics, caching inline
- **circular-deps/**: Circular import chain between user → order → product → order
- **circular-deps/index.ts**: Barrel export that obscures the dependency mess

### Quality Issues (5 findings)
- **magic-numbers.js**: Dozens of unexplained numeric constants for pricing, shipping, risk scoring
- **magic-numbers.js**: Hardcoded business rules (9-5 hours, Mon-Fri, password requirements)
- **magic-numbers.js**: Inconsistent configuration patterns
- **god-object.ts**: Inconsistent caching strategy
- **god-object.ts**: Hardcoded email addresses

### Testing Issues (2 findings)
- **god-object.ts**: Untestable due to singleton pattern
- No test files present for complex business logic

### Documentation Issues (2 findings)
- **magic-numbers.js**: Business logic completely undocumented
- **god-object.ts**: Comments contain unanswered questions from previous developers

## Running the Test

```bash
cd tests/fixtures/legacy-mess
bosun /audit full .
```

## Expected Output

Bosun should identify approximately 14 findings, primarily architectural and quality issues. See `expected-findings.json` for the complete expected output.

## Value Demonstration

This fixture demonstrates that Bosun:
1. Identifies architectural anti-patterns (god objects, singletons, circular deps)
2. Flags maintainability issues (magic numbers, mixed concerns)
3. Recognizes testability problems
4. Prioritizes what to fix first
5. Suggests concrete refactoring steps (e.g., split into UserService, OrderService, etc.)

**Key message**: "Here's what's wrong with this legacy code and a prioritized plan to improve it."
