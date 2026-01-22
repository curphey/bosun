#!/bin/bash
# Test: Validate almost-good fixture
# Ensures the fixture has all expected files and polish issues are present

set -e

FIXTURE_DIR="$FIXTURES_DIR/almost-good"

echo "Testing almost-good fixture..."

# Check required files exist
echo "Checking fixture files exist..."
assert_file_exists "$FIXTURE_DIR/FIXTURE.md" "FIXTURE.md required"
assert_file_exists "$FIXTURE_DIR/expected-findings.json" "expected-findings.json required"
assert_file_exists "$FIXTURE_DIR/api-handlers.ts" "api-handlers.ts required"
assert_file_exists "$FIXTURE_DIR/partial-types.ts" "partial-types.ts required"
assert_file_exists "$FIXTURE_DIR/almost-there.ts" "almost-there.ts required"
assert_file_exists "$FIXTURE_DIR/package.json" "package.json required"

# Validate expected findings cover key issues
EXPECTED="$FIXTURE_DIR/expected-findings.json"

echo "Checking expected findings coverage..."

# Should have quality findings
quality_count=$(jq '[.findings[] | select(.category == "quality")] | length' "$EXPECTED")
if [[ "$quality_count" -lt 5 ]]; then
    echo "ASSERTION FAILED: Should have at least 5 quality findings (got $quality_count)"
    exit 1
fi
echo "  ✓ Has $quality_count quality findings"

# Should have devops findings (outdated deps)
devops_count=$(jq '[.findings[] | select(.category == "devops")] | length' "$EXPECTED")
if [[ "$devops_count" -lt 1 ]]; then
    echo "ASSERTION FAILED: Should have at least 1 devops finding (got $devops_count)"
    exit 1
fi
echo "  ✓ Has $devops_count devops findings"

# Check specific issues are captured
echo "Checking specific issues are documented..."

# Inconsistent style should be flagged
style=$(jq '[.findings[] | select(.title | test("inconsistent"; "i"))] | length' "$EXPECTED")
if [[ "$style" -lt 1 ]]; then
    echo "ASSERTION FAILED: Inconsistent style should be documented"
    exit 1
fi
echo "  ✓ Inconsistent style documented"

# Type issues should be flagged
types=$(jq '[.findings[] | select(.title | test("any|type"; "i"))] | length' "$EXPECTED")
if [[ "$types" -lt 1 ]]; then
    echo "ASSERTION FAILED: Type issues should be documented"
    exit 1
fi
echo "  ✓ Type issues documented"

# Outdated deps should be flagged
deps=$(jq '[.findings[] | select(.title | test("outdated|dependencies"; "i"))] | length' "$EXPECTED")
if [[ "$deps" -lt 1 ]]; then
    echo "ASSERTION FAILED: Outdated dependencies should be documented"
    exit 1
fi
echo "  ✓ Outdated dependencies documented"

# Validate package.json has old versions
echo "Checking package.json has outdated dependencies..."
if ! grep -q '"express": "4.17' "$FIXTURE_DIR/package.json"; then
    echo "ASSERTION FAILED: package.json should have old express version"
    exit 1
fi
echo "  ✓ package.json has outdated express"

# Most findings should be medium/low (polish issues, not critical)
critical_count=$(jq '[.findings[] | select(.severity == "critical")] | length' "$EXPECTED")
if [[ "$critical_count" -gt 2 ]]; then
    echo "WARNING: almost-good should have few critical issues (got $critical_count)"
fi
echo "  ✓ Severity distribution appropriate for 'almost good' code"

echo "almost-good fixture validation passed!"
