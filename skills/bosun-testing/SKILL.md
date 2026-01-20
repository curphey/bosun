---
name: bosun-testing
description: Testing best practices, coverage strategies, and test quality patterns. Use when reviewing test suites, writing tests, improving coverage, or diagnosing flaky tests. Provides patterns for unit, integration, and end-to-end testing across languages.
tags: [testing, coverage, unit-tests, integration-tests, e2e, test-quality, mocking]
---

# Bosun Testing Skill

Testing knowledge base for test quality, coverage analysis, and testing strategy.

## When to Use

- Reviewing test suites for quality and coverage
- Writing new tests (unit, integration, e2e)
- Diagnosing flaky or slow tests
- Setting up test infrastructure
- Configuring coverage reporting
- Designing testing strategies

## When NOT to Use

- Security testing (use bosun-security)
- Performance testing/benchmarks (use bosun-performance)
- Language-specific syntax (use language skills)

## Testing Pyramid

```
         /\
        /  \      E2E Tests (few, slow, high confidence)
       /----\
      /      \    Integration Tests (some, medium speed)
     /--------\
    /          \  Unit Tests (many, fast, focused)
   /------------\
```

**Recommended ratio:** 70% unit, 20% integration, 10% e2e

## Core Testing Principles

### 1. Test Quality (F.I.R.S.T.)
- **Fast** - Unit tests < 100ms each
- **Isolated** - No shared state between tests
- **Repeatable** - Same result every run
- **Self-validating** - Pass/fail without manual inspection
- **Timely** - Written alongside or before code

### 2. Test Structure (AAA Pattern)
```
Arrange  - Set up test data and conditions
Act      - Execute the code under test
Assert   - Verify the expected outcome
```

### 3. What to Test
- **Happy paths** - Expected successful flows
- **Edge cases** - Boundaries, empty inputs, max values
- **Error conditions** - Invalid inputs, failures
- **Business logic** - Critical domain rules

### 4. What NOT to Test
- Framework code (it's already tested)
- Simple getters/setters
- Configuration files
- Third-party libraries directly

## Coverage Guidelines

### Coverage Targets
| Code Type | Target | Rationale |
|-----------|--------|-----------|
| Business logic | 90%+ | Critical, high risk |
| API endpoints | 85%+ | External interface |
| Utilities | 80%+ | Reused code |
| UI components | 70%+ | Visual verification helps |
| Generated code | 0% | Don't test generated code |

### Coverage ≠ Quality
High coverage doesn't guarantee good tests. Focus on:
- Assertion quality (meaningful checks)
- Edge case coverage
- Mutation testing survival

## Test Smells to Avoid

### Structural Smells
```javascript
// BAD: Test depends on order
test('creates user', () => { ... });
test('gets user', () => { /* depends on previous test */ });

// GOOD: Independent tests
test('creates user', () => {
  const user = createTestUser();
  // assertions
});
```

### Flaky Test Patterns
```javascript
// BAD: Time-dependent
expect(new Date()).toBe(expectedDate);

// GOOD: Frozen time
jest.useFakeTimers().setSystemTime(new Date('2024-01-15'));
expect(getDate()).toBe('2024-01-15');
```

```javascript
// BAD: Race condition
await someAsyncOperation();
expect(result).toBe(expected); // May not be ready

// GOOD: Wait for condition
await waitFor(() => expect(result).toBe(expected));
```

### Test Code Smells
| Smell | Problem | Fix |
|-------|---------|-----|
| No assertions | Test always passes | Add meaningful assertions |
| Magic numbers | Hard to understand | Use named constants |
| Test logic | Tests can have bugs | Keep tests simple |
| Excessive mocking | Tests don't reflect reality | Mock only external dependencies |
| Sleep/delays | Slow and flaky | Use async/await properly |
| Commented tests | Hidden failures | Delete or fix |

## Mocking Strategy

### What to Mock
- External services (APIs, databases in unit tests)
- File system (when testing logic, not I/O)
- Time/dates
- Random values

### What NOT to Mock
- The code under test
- Simple internal dependencies
- Data structures

### Mocking Hierarchy
```
Fake   > Stub   > Mock   > Spy
(best)                   (worst overuse)
```

## Test Organization

### File Structure
```
src/
  services/
    UserService.js
tests/
  unit/
    services/
      UserService.test.js
  integration/
    api/
      users.test.js
  e2e/
    flows/
      registration.test.js
  fixtures/
    users.json
  helpers/
    testUtils.js
```

### Naming Conventions
```javascript
// Pattern: describe what, when, then what
test('returns user when valid ID provided', () => {});
test('throws NotFoundError when user does not exist', () => {});
test('creates user with hashed password', () => {});
```

## Coverage Tools

| Language | Tool | Command |
|----------|------|---------|
| JavaScript | Jest | `npx jest --coverage` |
| JavaScript | c8/nyc | `npx c8 npm test` |
| TypeScript | Jest | `npx jest --coverage` |
| Python | pytest-cov | `pytest --cov=src` |
| Python | coverage.py | `coverage run -m pytest` |
| Go | built-in | `go test -cover ./...` |
| Rust | cargo-tarpaulin | `cargo tarpaulin` |
| Java | JaCoCo | Via Maven/Gradle plugin |

## Test Frameworks

| Language | Unit | Integration | E2E |
|----------|------|-------------|-----|
| JavaScript | Jest, Vitest | Supertest | Playwright, Cypress |
| TypeScript | Jest, Vitest | Supertest | Playwright, Cypress |
| Python | pytest | pytest | pytest + Selenium |
| Go | testing | testing | testing + testcontainers |
| Rust | built-in | built-in | built-in |
| Java | JUnit | JUnit + Testcontainers | Selenium |

## Quick Reference

### Assertion Best Practices
```javascript
// BAD: Boolean assertion
expect(user.isActive).toBe(true);

// GOOD: Specific assertion with message
expect(user.isActive).toBeTruthy();
// or even better, test behavior
expect(user.canLogin()).toBe(true);
```

### Test Data
```javascript
// BAD: Hardcoded data
const user = { id: 1, name: 'John', email: 'john@test.com' };

// GOOD: Factory pattern
const user = createUser({ name: 'John' }); // Factory fills defaults
```

### Async Testing
```javascript
// BAD: No await
test('fetches user', () => {
  const user = fetchUser(1); // Returns promise!
  expect(user.name).toBe('John'); // Always passes (comparing promise)
});

// GOOD: Proper async
test('fetches user', async () => {
  const user = await fetchUser(1);
  expect(user.name).toBe('John');
});
```

## References

See `references/` directory for detailed documentation:
- `testing-patterns.md` - Comprehensive testing patterns by type
- `framework-guides.md` - Framework-specific testing guides
