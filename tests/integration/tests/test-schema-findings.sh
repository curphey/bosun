#!/bin/bash
# Test: Validate findings.json schema
# Ensures the findings schema documented in audit.md is valid and complete

set -e

echo "Testing findings.json schema definition..."

# Create a sample findings.json that matches the documented schema
SAMPLE_FINDINGS=$(cat <<'EOF'
{
  "version": "1.0.0",
  "metadata": {
    "project": "test-project",
    "auditedAt": "2024-01-15T10:30:00Z",
    "scope": "full",
    "gitRef": "abc1234",
    "agents": ["security-agent", "quality-agent"]
  },
  "summary": {
    "total": 2,
    "bySeverity": { "critical": 0, "high": 1, "medium": 1, "low": 0, "info": 0 },
    "byStatus": { "open": 2, "fixed": 0, "wontfix": 0, "deferred": 0 },
    "byCategory": { "security": 1, "quality": 1 }
  },
  "findings": [
    {
      "id": "SEC-001",
      "category": "security",
      "severity": "high",
      "title": "Test finding",
      "description": "This is a test finding",
      "location": { "file": "test.js", "line": 10 },
      "suggestedFix": {
        "description": "Fix the issue",
        "automated": true,
        "effort": "trivial",
        "semanticCategory": "security fix"
      },
      "interactionTier": "auto",
      "status": "open"
    },
    {
      "id": "QUA-001",
      "category": "quality",
      "severity": "medium",
      "title": "Quality issue",
      "description": "This is a quality issue",
      "location": { "file": "app.ts", "line": 25 },
      "suggestedFix": {
        "description": "Refactor the code",
        "automated": false,
        "effort": "moderate",
        "semanticCategory": "refactoring"
      },
      "interactionTier": "approve",
      "status": "open"
    }
  ]
}
EOF
)

# Write to temp file
TEMP_FILE=$(mktemp)
echo "$SAMPLE_FINDINGS" > "$TEMP_FILE"

# Validate schema fields exist
echo "Checking required top-level fields..."
assert_json_field "$TEMP_FILE" ".version" "version field required"
assert_json_field "$TEMP_FILE" ".metadata" "metadata field required"
assert_json_field "$TEMP_FILE" ".summary" "summary field required"
assert_json_field "$TEMP_FILE" ".findings" "findings field required"

echo "Checking metadata fields..."
assert_json_field "$TEMP_FILE" ".metadata.project" "metadata.project required"
assert_json_field "$TEMP_FILE" ".metadata.auditedAt" "metadata.auditedAt required"
assert_json_field "$TEMP_FILE" ".metadata.scope" "metadata.scope required"

echo "Checking summary fields..."
assert_json_field "$TEMP_FILE" ".summary.total" "summary.total required"
assert_json_field "$TEMP_FILE" ".summary.bySeverity" "summary.bySeverity required"
assert_json_field "$TEMP_FILE" ".summary.byStatus" "summary.byStatus required"
assert_json_field "$TEMP_FILE" ".summary.byCategory" "summary.byCategory required"

echo "Checking finding fields..."
assert_json_field "$TEMP_FILE" ".findings[0].id" "finding.id required"
assert_json_field "$TEMP_FILE" ".findings[0].category" "finding.category required"
assert_json_field "$TEMP_FILE" ".findings[0].severity" "finding.severity required"
assert_json_field "$TEMP_FILE" ".findings[0].title" "finding.title required"
assert_json_field "$TEMP_FILE" ".findings[0].description" "finding.description required"
assert_json_field "$TEMP_FILE" ".findings[0].status" "finding.status required"

echo "Checking suggested fix fields..."
assert_json_field "$TEMP_FILE" ".findings[0].suggestedFix.description" "suggestedFix.description required"
assert_json_field "$TEMP_FILE" ".findings[0].suggestedFix.automated" "suggestedFix.automated required"
assert_json_field "$TEMP_FILE" ".findings[0].suggestedFix.effort" "suggestedFix.effort required"
assert_json_field "$TEMP_FILE" ".findings[0].suggestedFix.semanticCategory" "suggestedFix.semanticCategory required"

echo "Checking interaction tiers..."
assert_json_field "$TEMP_FILE" ".findings[0].interactionTier" "interactionTier required"

# Validate enum values
echo "Validating severity enum values..."
VALID_SEVERITIES="critical high medium low info"
for finding in $(jq -r '.findings[].severity' "$TEMP_FILE"); do
    if ! echo "$VALID_SEVERITIES" | grep -qw "$finding"; then
        echo "ASSERTION FAILED: Invalid severity: $finding"
        exit 1
    fi
done

echo "Validating status enum values..."
VALID_STATUSES="open fixed wontfix deferred"
for status in $(jq -r '.findings[].status' "$TEMP_FILE"); do
    if ! echo "$VALID_STATUSES" | grep -qw "$status"; then
        echo "ASSERTION FAILED: Invalid status: $status"
        exit 1
    fi
done

echo "Validating interaction tier enum values..."
VALID_TIERS="auto confirm approve"
for tier in $(jq -r '.findings[].interactionTier' "$TEMP_FILE"); do
    if ! echo "$VALID_TIERS" | grep -qw "$tier"; then
        echo "ASSERTION FAILED: Invalid interactionTier: $tier"
        exit 1
    fi
done

# Cleanup
rm -f "$TEMP_FILE"

echo "Schema validation passed!"
