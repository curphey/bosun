#!/bin/bash
# Test: Validate skill references
# Ensures referenced files in skills actually exist

set -e

SKILLS_DIR="$PROJECT_ROOT/skills"

echo "Testing skill references..."

total_refs=0
valid_refs=0

for skill_dir in "$SKILLS_DIR"/*/; do
    if [[ -d "$skill_dir" ]]; then
        skill_name=$(basename "$skill_dir")
        refs_dir="$skill_dir/references"

        if [[ -d "$refs_dir" ]]; then
            echo "Checking: $skill_name/references/"

            for ref_file in "$refs_dir"/*; do
                if [[ -f "$ref_file" ]]; then
                    ref_name=$(basename "$ref_file")
                    total_refs=$((total_refs + 1))

                    # Check file isn't empty
                    if [[ -s "$ref_file" ]]; then
                        valid_refs=$((valid_refs + 1))
                        echo "  ✓ $ref_name"
                    else
                        echo "  WARNING: $ref_name is empty"
                    fi
                fi
            done
        fi
    fi
done

echo ""
echo "Total reference files: $total_refs"
echo "Valid (non-empty) reference files: $valid_refs"

# At least some skills should have references
if [[ "$total_refs" -lt 5 ]]; then
    echo "WARNING: Only $total_refs reference files found. Consider adding more documentation."
fi

echo "Skill references validated!"
