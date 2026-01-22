#!/bin/bash
# Test: Validate expected-findings.json schema in fixtures
# Ensures test fixtures have properly structured expected findings

set -e

echo "Testing expected-findings.json schema in fixtures..."

for fixture_dir in "$FIXTURES_DIR"/*; do
    if [[ -d "$fixture_dir" ]]; then
        fixture_name=$(basename "$fixture_dir")
        expected_file="$fixture_dir/expected-findings.json"

        if [[ -f "$expected_file" ]]; then
            echo "Validating: $fixture_name/expected-findings.json"

            # Check it's valid JSON
            if ! jq empty "$expected_file" 2>/dev/null; then
                echo "ASSERTION FAILED: Invalid JSON in $expected_file"
                exit 1
            fi

            # Check required fields
            assert_json_field "$expected_file" ".description" "$fixture_name: description required"
            assert_json_field "$expected_file" ".purpose" "$fixture_name: purpose required"
            assert_json_field "$expected_file" ".findings" "$fixture_name: findings array required"
            assert_json_field "$expected_file" ".summary" "$fixture_name: summary required"

            # Check summary has counts
            assert_json_field "$expected_file" ".summary.total" "$fixture_name: summary.total required"
            assert_json_field "$expected_file" ".summary.bySeverity" "$fixture_name: summary.bySeverity required"
            assert_json_field "$expected_file" ".summary.byCategory" "$fixture_name: summary.byCategory required"

            # Validate each finding has required fields
            finding_count=$(jq '.findings | length' "$expected_file")
            echo "  Found $finding_count expected findings"

            for i in $(seq 0 $((finding_count - 1))); do
                assert_json_field "$expected_file" ".findings[$i].id" "$fixture_name: finding[$i].id required"
                assert_json_field "$expected_file" ".findings[$i].category" "$fixture_name: finding[$i].category required"
                assert_json_field "$expected_file" ".findings[$i].severity" "$fixture_name: finding[$i].severity required"
                assert_json_field "$expected_file" ".findings[$i].title" "$fixture_name: finding[$i].title required"
            done

            # Validate summary.total matches findings count
            summary_total=$(jq '.summary.total' "$expected_file")
            if [[ "$summary_total" -ne "$finding_count" ]]; then
                echo "ASSERTION FAILED: $fixture_name summary.total ($summary_total) != findings count ($finding_count)"
                exit 1
            fi

            echo "  ✓ Schema valid"
        else
            echo "WARNING: No expected-findings.json in $fixture_name"
        fi
    fi
done

echo "All expected-findings.json files are valid!"
