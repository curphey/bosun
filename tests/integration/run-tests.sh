#!/bin/bash
# Bosun Integration Test Runner
# Validates that Bosun's core functionality works correctly

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FIXTURES_DIR="$PROJECT_ROOT/tests/fixtures"
RESULTS_DIR="$SCRIPT_DIR/results"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Initialize results directory
mkdir -p "$RESULTS_DIR"
rm -rf "$RESULTS_DIR"/*

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Bosun Integration Test Suite                       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Helper: Run a test and track results
run_test() {
    local test_name="$1"
    local test_script="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${YELLOW}▶ Running:${NC} $test_name"

    if bash "$test_script" > "$RESULTS_DIR/$test_name.log" 2>&1; then
        echo -e "${GREEN}  ✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}  ✗ FAILED${NC}"
        echo -e "${RED}    See: $RESULTS_DIR/$test_name.log${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Helper: Assert file exists
assert_file_exists() {
    local file="$1"
    local msg="${2:-File should exist: $file}"
    if [[ -f "$file" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $msg"
        return 1
    fi
}

# Helper: Assert JSON field exists
assert_json_field() {
    local file="$1"
    local field="$2"
    local msg="${3:-JSON field should exist: $field}"
    if jq -e "$field" "$file" > /dev/null 2>&1; then
        return 0
    else
        echo "ASSERTION FAILED: $msg"
        return 1
    fi
}

# Helper: Assert JSON field equals value
assert_json_equals() {
    local file="$1"
    local field="$2"
    local expected="$3"
    local msg="${4:-JSON field $field should equal $expected}"
    local actual
    actual=$(jq -r "$field" "$file" 2>/dev/null)
    if [[ "$actual" == "$expected" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $msg (got: $actual)"
        return 1
    fi
}

# Helper: Assert JSON array length
assert_json_array_length() {
    local file="$1"
    local field="$2"
    local min_length="$3"
    local msg="${4:-JSON array $field should have at least $min_length items}"
    local actual
    actual=$(jq "$field | length" "$file" 2>/dev/null)
    if [[ "$actual" -ge "$min_length" ]]; then
        return 0
    else
        echo "ASSERTION FAILED: $msg (got: $actual)"
        return 1
    fi
}

# Export helpers for use in test scripts
export -f assert_file_exists
export -f assert_json_field
export -f assert_json_equals
export -f assert_json_array_length
export FIXTURES_DIR
export RESULTS_DIR
export PROJECT_ROOT

echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Section 1: Schema Validation Tests${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

run_test "schema-findings" "$SCRIPT_DIR/tests/test-schema-findings.sh" || true
run_test "schema-expected" "$SCRIPT_DIR/tests/test-schema-expected.sh" || true

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Section 2: Fixture Validation Tests${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

run_test "fixture-rushed-mvp" "$SCRIPT_DIR/tests/test-fixture-rushed-mvp.sh" || true
run_test "fixture-legacy-mess" "$SCRIPT_DIR/tests/test-fixture-legacy-mess.sh" || true
run_test "fixture-almost-good" "$SCRIPT_DIR/tests/test-fixture-almost-good.sh" || true

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Section 3: Agent Definition Tests${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

run_test "agents-valid" "$SCRIPT_DIR/tests/test-agents-valid.sh" || true
run_test "agents-skills-exist" "$SCRIPT_DIR/tests/test-agents-skills-exist.sh" || true

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Section 4: Skill Definition Tests${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

run_test "skills-valid" "$SCRIPT_DIR/tests/test-skills-valid.sh" || true
run_test "skills-references" "$SCRIPT_DIR/tests/test-skills-references.sh" || true

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Section 5: Command Definition Tests${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

run_test "commands-valid" "$SCRIPT_DIR/tests/test-commands-valid.sh" || true

echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Section 6: Deduplication Logic Tests${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
echo ""

run_test "dedup-logic" "$SCRIPT_DIR/tests/test-dedup-logic.sh" || true

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                     Test Results                             ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Tests Run:    $TESTS_RUN"
echo -e "  ${GREEN}Passed:       $TESTS_PASSED${NC}"
echo -e "  ${RED}Failed:       $TESTS_FAILED${NC}"
echo ""

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo -e "${RED}Some tests failed. Check logs in: $RESULTS_DIR${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
