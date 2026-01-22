# Bosun Integration Tests

Automated tests to validate Bosun's core functionality, schema definitions, and fixture quality.

## Running Tests

```bash
# Run all tests
./tests/integration/run-tests.sh

# Run from project root
./tests/integration/run-tests.sh
```

## Test Sections

### 1. Schema Validation Tests
- **test-schema-findings.sh** - Validates the findings.json schema matches documentation
- **test-schema-expected.sh** - Validates expected-findings.json in test fixtures

### 2. Fixture Validation Tests
- **test-fixture-rushed-mvp.sh** - Validates rushed-mvp fixture structure and coverage
- **test-fixture-legacy-mess.sh** - Validates legacy-mess fixture structure and coverage
- **test-fixture-almost-good.sh** - Validates almost-good fixture structure and coverage

### 3. Agent Definition Tests
- **test-agents-valid.sh** - Validates all agent files have proper frontmatter
- **test-agents-skills-exist.sh** - Validates agents reference existing skills

### 4. Skill Definition Tests
- **test-skills-valid.sh** - Validates all skill files have proper structure
- **test-skills-references.sh** - Validates skill reference files exist and are non-empty

### 5. Command Definition Tests
- **test-commands-valid.sh** - Validates all command files have proper documentation

### 6. Deduplication Logic Tests
- **test-dedup-logic.sh** - Validates finding deduplication rules work correctly

## Test Output

Results are written to `tests/integration/results/`:
- Each test creates a `.log` file with detailed output
- Failed tests include error messages and assertions

## Adding New Tests

1. Create a new script in `tests/integration/tests/`
2. Use the helper functions exported by `run-tests.sh`:
   - `assert_file_exists <file> [message]`
   - `assert_json_field <file> <field> [message]`
   - `assert_json_equals <file> <field> <expected> [message]`
   - `assert_json_array_length <file> <field> <min_length> [message]`
3. Exit with code 0 on success, non-zero on failure
4. Add the test to `run-tests.sh` with `run_test "test-name" "$SCRIPT_DIR/tests/test-name.sh"`

## Environment Variables

Tests have access to:
- `$PROJECT_ROOT` - Bosun project root directory
- `$FIXTURES_DIR` - Path to test fixtures
- `$RESULTS_DIR` - Path to test results output

## CI Integration

Add to GitHub Actions:

```yaml
- name: Run Integration Tests
  run: ./tests/integration/run-tests.sh
```
