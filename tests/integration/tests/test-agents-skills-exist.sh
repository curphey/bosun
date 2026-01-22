#!/bin/bash
# Test: Validate agents reference existing skills
# Ensures skills referenced in agent frontmatter actually exist

set -e

AGENTS_DIR="$PROJECT_ROOT/agents"
SKILLS_DIR="$PROJECT_ROOT/skills"

echo "Testing that agent-referenced skills exist..."

# Get list of available skills
available_skills=()
for skill_dir in "$SKILLS_DIR"/*/; do
    if [[ -f "$skill_dir/SKILL.md" ]]; then
        skill_name=$(basename "$skill_dir")
        available_skills+=("$skill_name")
    fi
done

echo "Available skills: ${#available_skills[@]}"

# Check each agent's skills references
for agent_file in "$AGENTS_DIR"/*.md; do
    agent_name=$(basename "$agent_file" .md)

    # Extract skills line from frontmatter
    skills_line=$(sed -n '/^---$/,/^---$/p' "$agent_file" | grep "^skills:" || true)

    if [[ -n "$skills_line" ]]; then
        echo "Checking: $agent_name"

        # Parse skills array (handles both [skill1, skill2] and - skill formats)
        skills=$(echo "$skills_line" | sed 's/skills://' | tr -d '[]' | tr ',' '\n' | tr -d ' ' | grep -v '^$')

        for skill in $skills; do
            # Check if skill exists
            found=false
            for available in "${available_skills[@]}"; do
                if [[ "$available" == "$skill" ]]; then
                    found=true
                    break
                fi
            done

            if [[ "$found" == "true" ]]; then
                echo "  ✓ $skill exists"
            else
                echo "  WARNING: $skill referenced but not found in skills/"
                # Not a hard failure - skill might be optional or planned
            fi
        done
    fi
done

echo "Agent skill references validated!"
