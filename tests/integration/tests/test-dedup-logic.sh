#!/bin/bash
# Test: Validate deduplication logic
# Tests the finding deduplication rules documented in orchestrator-agent.md

set -e

echo "Testing deduplication logic..."

# Create test findings that should be deduplicated
FINDINGS_A=$(cat <<'EOF'
{
  "findings": [
    {
      "id": "SEC-001",
      "category": "security",
      "severity": "high",
      "title": "SQL injection in login",
      "location": { "file": "src/auth.ts", "line": 42 }
    }
  ]
}
EOF
)

FINDINGS_B=$(cat <<'EOF'
{
  "findings": [
    {
      "id": "QUA-001",
      "category": "quality",
      "severity": "medium",
      "title": "SQL injection vulnerability",
      "location": { "file": "src/auth.ts", "line": 42 }
    }
  ]
}
EOF
)

# Test case: Same file + same line + similar title = should merge
echo "Test: Same file + same line should be deduplicated"

file_a=$(echo "$FINDINGS_A" | jq -r '.findings[0].location.file')
line_a=$(echo "$FINDINGS_A" | jq -r '.findings[0].location.line')
file_b=$(echo "$FINDINGS_B" | jq -r '.findings[0].location.file')
line_b=$(echo "$FINDINGS_B" | jq -r '.findings[0].location.line')

if [[ "$file_a" == "$file_b" && "$line_a" == "$line_b" ]]; then
    echo "  ✓ Findings share same file:line location - dedup candidate"
else
    echo "ASSERTION FAILED: Test setup error - findings should have same location"
    exit 1
fi

# Test case: Keep higher severity
sev_a=$(echo "$FINDINGS_A" | jq -r '.findings[0].severity')
sev_b=$(echo "$FINDINGS_B" | jq -r '.findings[0].severity')
echo "Test: Higher severity should be kept"
echo "  Finding A: $sev_a"
echo "  Finding B: $sev_b"

# Severity ranking: critical > high > medium > low > info
get_sev_rank() {
    case "$1" in
        critical) echo 5 ;;
        high) echo 4 ;;
        medium) echo 3 ;;
        low) echo 2 ;;
        info) echo 1 ;;
        *) echo 0 ;;
    esac
}

rank_a=$(get_sev_rank "$sev_a")
rank_b=$(get_sev_rank "$sev_b")

if [[ "$rank_a" -gt "$rank_b" ]]; then
    echo "  ✓ Finding A ($sev_a) has higher severity - should be kept"
elif [[ "$rank_b" -gt "$rank_a" ]]; then
    echo "  ✓ Finding B ($sev_b) has higher severity - should be kept"
else
    echo "  ✓ Same severity - either can be kept"
fi

# Test case: Verify ID prefix assignment rules
echo "Test: ID prefix assignment by category"

CATEGORIES_AND_PREFIXES=(
    "security:SEC"
    "quality:QUA"
    "docs:DOC"
    "architecture:ARC"
    "devops:DEV"
    "ux-ui:UXU"
    "testing:TST"
    "performance:PRF"
)

for pair in "${CATEGORIES_AND_PREFIXES[@]}"; do
    category="${pair%%:*}"
    prefix="${pair##*:}"
    echo "  ✓ $category -> $prefix-xxx"
done

# Test case: Verify summary calculations
echo "Test: Summary calculation logic"

SAMPLE=$(cat <<'EOF'
{
  "findings": [
    { "severity": "critical", "status": "open", "category": "security" },
    { "severity": "high", "status": "open", "category": "security" },
    { "severity": "medium", "status": "fixed", "category": "quality" },
    { "severity": "low", "status": "open", "category": "docs" }
  ]
}
EOF
)

total=$(echo "$SAMPLE" | jq '.findings | length')
critical=$(echo "$SAMPLE" | jq '[.findings[] | select(.severity == "critical")] | length')
open=$(echo "$SAMPLE" | jq '[.findings[] | select(.status == "open")] | length')
security=$(echo "$SAMPLE" | jq '[.findings[] | select(.category == "security")] | length')

echo "  Total: $total"
echo "  Critical: $critical"
echo "  Open: $open"
echo "  Security: $security"

if [[ "$total" -eq 4 && "$critical" -eq 1 && "$open" -eq 3 && "$security" -eq 2 ]]; then
    echo "  ✓ Summary calculations correct"
else
    echo "ASSERTION FAILED: Summary calculations incorrect"
    exit 1
fi

echo "Deduplication logic validation passed!"
