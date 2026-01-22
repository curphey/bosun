#!/bin/bash
# Test: Validate all skill definitions
# Ensures skills have required structure and frontmatter

set -e

SKILLS_DIR="$PROJECT_ROOT/skills"

echo "Testing skill definitions..."

skill_count=0
skills_with_refs=0

for skill_dir in "$SKILLS_DIR"/*/; do
    if [[ -d "$skill_dir" ]]; then
        skill_name=$(basename "$skill_dir")
        skill_file="$skill_dir/SKILL.md"

        if [[ ! -f "$skill_file" ]]; then
            echo "ASSERTION FAILED: $skill_name missing SKILL.md"
            exit 1
        fi

        skill_count=$((skill_count + 1))
        echo "Checking: $skill_name"

        # Check file starts with ---
        if ! head -1 "$skill_file" | grep -q "^---$"; then
            echo "ASSERTION FAILED: $skill_name should have YAML frontmatter"
            exit 1
        fi

        # Extract frontmatter
        frontmatter=$(sed -n '/^---$/,/^---$/p' "$skill_file" | sed '1d;$d')

        # Check required fields
        if ! echo "$frontmatter" | grep -q "^name:"; then
            echo "ASSERTION FAILED: $skill_name missing 'name' in frontmatter"
            exit 1
        fi

        if ! echo "$frontmatter" | grep -q "^description:"; then
            echo "ASSERTION FAILED: $skill_name missing 'description' in frontmatter"
            exit 1
        fi

        # Check for references directory
        if [[ -d "$skill_dir/references" ]]; then
            ref_count=$(ls -1 "$skill_dir/references" 2>/dev/null | wc -l | tr -d ' ')
            if [[ "$ref_count" -gt 0 ]]; then
                skills_with_refs=$((skills_with_refs + 1))
                echo "  ✓ Has $ref_count reference files"
            fi
        fi

        # Check skill isn't too long (convention: <500 lines)
        line_count=$(wc -l < "$skill_file" | tr -d ' ')
        if [[ "$line_count" -gt 500 ]]; then
            echo "  WARNING: $skill_name is $line_count lines (convention: <500)"
        else
            echo "  ✓ $line_count lines"
        fi
    fi
done

echo ""
echo "Total skills: $skill_count"
echo "Skills with references: $skills_with_refs"

if [[ "$skill_count" -lt 10 ]]; then
    echo "ASSERTION FAILED: Should have at least 10 skills (got $skill_count)"
    exit 1
fi

echo "All skill definitions are valid!"
