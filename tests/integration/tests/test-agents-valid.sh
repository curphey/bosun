#!/bin/bash
# Test: Validate all agent definitions
# Ensures agents have required frontmatter and valid structure

set -e

AGENTS_DIR="$PROJECT_ROOT/agents"

echo "Testing agent definitions..."

# Required agents
REQUIRED_AGENTS=(
    "orchestrator-agent"
    "security-agent"
    "quality-agent"
    "docs-agent"
    "architecture-agent"
    "devops-agent"
    "ux-ui-agent"
    "testing-agent"
    "performance-agent"
)

echo "Checking required agents exist..."
for agent in "${REQUIRED_AGENTS[@]}"; do
    agent_file="$AGENTS_DIR/$agent.md"
    if [[ ! -f "$agent_file" ]]; then
        echo "ASSERTION FAILED: Required agent missing: $agent"
        exit 1
    fi
    echo "  ✓ $agent exists"
done

echo "Validating agent frontmatter..."
for agent_file in "$AGENTS_DIR"/*.md; do
    agent_name=$(basename "$agent_file" .md)
    echo "  Checking: $agent_name"

    # Check file starts with ---
    if ! head -1 "$agent_file" | grep -q "^---$"; then
        echo "ASSERTION FAILED: $agent_name should have YAML frontmatter"
        exit 1
    fi

    # Extract frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$agent_file" | sed '1d;$d')

    # Check required fields
    if ! echo "$frontmatter" | grep -q "^name:"; then
        echo "ASSERTION FAILED: $agent_name missing 'name' in frontmatter"
        exit 1
    fi

    if ! echo "$frontmatter" | grep -q "^description:"; then
        echo "ASSERTION FAILED: $agent_name missing 'description' in frontmatter"
        exit 1
    fi

    if ! echo "$frontmatter" | grep -q "^tools:"; then
        echo "ASSERTION FAILED: $agent_name missing 'tools' in frontmatter"
        exit 1
    fi

    echo "    ✓ Frontmatter valid"
done

# Count total agents
agent_count=$(ls -1 "$AGENTS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "Total agents: $agent_count"

if [[ "$agent_count" -lt 9 ]]; then
    echo "ASSERTION FAILED: Should have at least 9 agents (got $agent_count)"
    exit 1
fi

echo "All agent definitions are valid!"
