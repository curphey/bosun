#!/bin/bash
# Test: Validate rushed-mvp fixture
# Ensures the fixture has all expected files and issues are present

set -e

FIXTURE_DIR="$FIXTURES_DIR/rushed-mvp"

echo "Testing rushed-mvp fixture..."

# Check required files exist
echo "Checking fixture files exist..."
assert_file_exists "$FIXTURE_DIR/FIXTURE.md" "FIXTURE.md required"
assert_file_exists "$FIXTURE_DIR/README.md" "README.md required"
assert_file_exists "$FIXTURE_DIR/expected-findings.json" "expected-findings.json required"
assert_file_exists "$FIXTURE_DIR/no-error-handling.ts" "no-error-handling.ts required"
assert_file_exists "$FIXTURE_DIR/n-plus-one.py" "n-plus-one.py required"
assert_file_exists "$FIXTURE_DIR/copy-paste-code.go" "copy-paste-code.go required"

# Validate expected findings cover key issues
EXPECTED="$FIXTURE_DIR/expected-findings.json"

echo "Checking expected findings coverage..."

# Should have quality findings
quality_count=$(jq '[.findings[] | select(.category == "quality")] | length' "$EXPECTED")
if [[ "$quality_count" -lt 3 ]]; then
    echo "ASSERTION FAILED: Should have at least 3 quality findings (got $quality_count)"
    exit 1
fi
echo "  ✓ Has $quality_count quality findings"

# Should have performance findings
perf_count=$(jq '[.findings[] | select(.category == "performance")] | length' "$EXPECTED")
if [[ "$perf_count" -lt 2 ]]; then
    echo "ASSERTION FAILED: Should have at least 2 performance findings (got $perf_count)"
    exit 1
fi
echo "  ✓ Has $perf_count performance findings"

# Should have docs findings
docs_count=$(jq '[.findings[] | select(.category == "docs")] | length' "$EXPECTED")
if [[ "$docs_count" -lt 1 ]]; then
    echo "ASSERTION FAILED: Should have at least 1 docs finding (got $docs_count)"
    exit 1
fi
echo "  ✓ Has $docs_count docs findings"

# Check specific issues are captured
echo "Checking specific issues are documented..."

# N+1 query should be flagged
n_plus_one=$(jq '[.findings[] | select(.title | test("N\\+1"; "i"))] | length' "$EXPECTED")
if [[ "$n_plus_one" -lt 1 ]]; then
    echo "ASSERTION FAILED: N+1 query issue should be documented"
    exit 1
fi
echo "  ✓ N+1 query issue documented"

# Missing error handling should be flagged
error_handling=$(jq '[.findings[] | select(.title | test("error handling"; "i"))] | length' "$EXPECTED")
if [[ "$error_handling" -lt 1 ]]; then
    echo "ASSERTION FAILED: Missing error handling should be documented"
    exit 1
fi
echo "  ✓ Missing error handling documented"

# Code duplication should be flagged
duplication=$(jq '[.findings[] | select(.title | test("duplicat"; "i"))] | length' "$EXPECTED")
if [[ "$duplication" -lt 1 ]]; then
    echo "ASSERTION FAILED: Code duplication should be documented"
    exit 1
fi
echo "  ✓ Code duplication documented"

# Check severity distribution makes sense
critical_high=$(jq '[.findings[] | select(.severity == "critical" or .severity == "high")] | length' "$EXPECTED")
echo "  ✓ Has $critical_high critical/high findings"

echo "rushed-mvp fixture validation passed!"
