#!/bin/bash
# Test: Validate legacy-mess fixture
# Ensures the fixture has all expected files and architectural issues are present

set -e

FIXTURE_DIR="$FIXTURES_DIR/legacy-mess"

echo "Testing legacy-mess fixture..."

# Check required files exist
echo "Checking fixture files exist..."
assert_file_exists "$FIXTURE_DIR/FIXTURE.md" "FIXTURE.md required"
assert_file_exists "$FIXTURE_DIR/expected-findings.json" "expected-findings.json required"
assert_file_exists "$FIXTURE_DIR/god-object.ts" "god-object.ts required"
assert_file_exists "$FIXTURE_DIR/magic-numbers.js" "magic-numbers.js required"
assert_file_exists "$FIXTURE_DIR/circular-deps/index.ts" "circular-deps/index.ts required"
assert_file_exists "$FIXTURE_DIR/circular-deps/user.ts" "circular-deps/user.ts required"
assert_file_exists "$FIXTURE_DIR/circular-deps/order.ts" "circular-deps/order.ts required"

# Validate expected findings cover key issues
EXPECTED="$FIXTURE_DIR/expected-findings.json"

echo "Checking expected findings coverage..."

# Should have architecture findings
arch_count=$(jq '[.findings[] | select(.category == "architecture")] | length' "$EXPECTED")
if [[ "$arch_count" -lt 3 ]]; then
    echo "ASSERTION FAILED: Should have at least 3 architecture findings (got $arch_count)"
    exit 1
fi
echo "  ✓ Has $arch_count architecture findings"

# Should have quality findings
quality_count=$(jq '[.findings[] | select(.category == "quality")] | length' "$EXPECTED")
if [[ "$quality_count" -lt 2 ]]; then
    echo "ASSERTION FAILED: Should have at least 2 quality findings (got $quality_count)"
    exit 1
fi
echo "  ✓ Has $quality_count quality findings"

# Check specific issues are captured
echo "Checking specific issues are documented..."

# God object should be flagged
god_object=$(jq '[.findings[] | select(.title | test("god object"; "i"))] | length' "$EXPECTED")
if [[ "$god_object" -lt 1 ]]; then
    echo "ASSERTION FAILED: God object issue should be documented"
    exit 1
fi
echo "  ✓ God object issue documented"

# Circular dependencies should be flagged
circular=$(jq '[.findings[] | select(.title | test("circular"; "i"))] | length' "$EXPECTED")
if [[ "$circular" -lt 1 ]]; then
    echo "ASSERTION FAILED: Circular dependency issue should be documented"
    exit 1
fi
echo "  ✓ Circular dependency documented"

# Magic numbers should be flagged
magic=$(jq '[.findings[] | select(.title | test("magic"; "i"))] | length' "$EXPECTED")
if [[ "$magic" -lt 1 ]]; then
    echo "ASSERTION FAILED: Magic numbers issue should be documented"
    exit 1
fi
echo "  ✓ Magic numbers documented"

# Validate god-object.ts is actually large
god_object_lines=$(wc -l < "$FIXTURE_DIR/god-object.ts" | tr -d ' ')
if [[ "$god_object_lines" -lt 400 ]]; then
    echo "ASSERTION FAILED: god-object.ts should be >400 lines to be a realistic god object (got $god_object_lines)"
    exit 1
fi
echo "  ✓ god-object.ts is $god_object_lines lines (realistic size)"

echo "legacy-mess fixture validation passed!"
