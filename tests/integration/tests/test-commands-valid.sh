#!/bin/bash
# Test: Validate all command definitions
# Ensures commands have required structure and documentation

set -e

COMMANDS_DIR="$PROJECT_ROOT/commands"

echo "Testing command definitions..."

# Required commands
REQUIRED_COMMANDS=(
    "audit"
    "fix"
    "improve"
    "status"
)

echo "Checking required commands exist..."
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    cmd_file="$COMMANDS_DIR/$cmd.md"
    if [[ ! -f "$cmd_file" ]]; then
        echo "ASSERTION FAILED: Required command missing: $cmd"
        exit 1
    fi
    echo "  ✓ /$cmd exists"
done

echo "Validating command documentation..."
for cmd_file in "$COMMANDS_DIR"/*.md; do
    cmd_name=$(basename "$cmd_file" .md)
    echo "  Checking: /$cmd_name"

    # Check file starts with ---
    if ! head -1 "$cmd_file" | grep -q "^---$"; then
        echo "ASSERTION FAILED: $cmd_name should have YAML frontmatter"
        exit 1
    fi

    # Extract frontmatter
    frontmatter=$(sed -n '/^---$/,/^---$/p' "$cmd_file" | sed '1d;$d')

    # Check required fields
    if ! echo "$frontmatter" | grep -q "^name:"; then
        echo "ASSERTION FAILED: $cmd_name missing 'name' in frontmatter"
        exit 1
    fi

    if ! echo "$frontmatter" | grep -q "^description:"; then
        echo "ASSERTION FAILED: $cmd_name missing 'description' in frontmatter"
        exit 1
    fi

    # Check for usage section
    if ! grep -q "## Usage" "$cmd_file"; then
        echo "WARNING: $cmd_name missing '## Usage' section"
    fi

    # Check for examples
    if ! grep -q -E "(## Example|## Examples|\`\`\`)" "$cmd_file"; then
        echo "WARNING: $cmd_name may be missing examples"
    fi

    echo "    ✓ Documentation valid"
done

# Count total commands
cmd_count=$(ls -1 "$COMMANDS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "Total commands: $cmd_count"

if [[ "$cmd_count" -lt 4 ]]; then
    echo "ASSERTION FAILED: Should have at least 4 commands (got $cmd_count)"
    exit 1
fi

echo "All command definitions are valid!"
