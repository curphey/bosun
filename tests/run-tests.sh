#!/bin/bash
# Usage: ./tests/run-tests.sh [test-name]
# Run Bosun plugin tests

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Color helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error()   { echo -e "${RED}[FAIL]${NC} $1"; }

# Counters
PASS_COUNT=0
FAIL_COUNT=0

test_pass() {
    log_success "$1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

test_fail() {
    log_error "$1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

# ====================
# Test: Plugin Manifest
# ====================
test_plugin_manifest() {
    log_info "Testing plugin manifest..."

    local manifest="$PROJECT_ROOT/.claude-plugin/plugin.json"

    # Check file exists
    if [[ ! -f "$manifest" ]]; then
        test_fail "plugin.json not found"
        return
    fi

    # Validate JSON
    if ! jq empty "$manifest" 2>/dev/null; then
        test_fail "plugin.json is not valid JSON"
        return
    fi

    # Check required fields
    local name=$(jq -r '.name' "$manifest")
    local version=$(jq -r '.version' "$manifest")
    local description=$(jq -r '.description' "$manifest")

    if [[ "$name" != "bosun" ]]; then
        test_fail "plugin name should be 'bosun', got '$name'"
    else
        test_pass "Plugin name is correct"
    fi

    if [[ -z "$version" || "$version" == "null" ]]; then
        test_fail "Plugin version is missing"
    else
        test_pass "Plugin version exists: $version"
    fi

    if [[ -z "$description" || "$description" == "null" ]]; then
        test_fail "Plugin description is missing"
    else
        test_pass "Plugin description exists"
    fi
}

# ====================
# Test: Findings Schema
# ====================
test_findings_schema() {
    log_info "Testing findings schema..."

    local schema="$PROJECT_ROOT/schemas/findings.schema.json"

    if [[ ! -f "$schema" ]]; then
        test_fail "findings.schema.json not found"
        return
    fi

    if ! jq empty "$schema" 2>/dev/null; then
        test_fail "findings.schema.json is not valid JSON"
        return
    fi

    # Check schema structure
    local schema_type=$(jq -r '.type' "$schema")
    if [[ "$schema_type" != "object" ]]; then
        test_fail "Schema root should be object type"
    else
        test_pass "Schema has correct root type"
    fi

    # Check required properties
    local has_version=$(jq -r '.properties.version' "$schema")
    local has_findings=$(jq -r '.properties.findings' "$schema")

    if [[ "$has_version" == "null" ]]; then
        test_fail "Schema missing version property"
    else
        test_pass "Schema has version property"
    fi

    if [[ "$has_findings" == "null" ]]; then
        test_fail "Schema missing findings property"
    else
        test_pass "Schema has findings property"
    fi
}

# ====================
# Test: Agent Files
# ====================
test_agents() {
    log_info "Testing agent files..."

    local agents_dir="$PROJECT_ROOT/agents"

    if [[ ! -d "$agents_dir" ]]; then
        test_fail "agents directory not found"
        return
    fi

    local agent_count=0

    for agent_file in "$agents_dir"/*.md; do
        if [[ ! -f "$agent_file" ]]; then
            continue
        fi

        local basename=$(basename "$agent_file")
        agent_count=$((agent_count + 1))

        # Check for YAML frontmatter
        if ! head -1 "$agent_file" | grep -q "^---$"; then
            test_fail "$basename: Missing YAML frontmatter"
            continue
        fi

        # Check required fields directly in file (more reliable than extracting)
        if grep -q "^name:" "$agent_file"; then
            test_pass "$basename: Has name field"
        else
            test_fail "$basename: Missing 'name' field"
        fi

        if grep -q "^description:" "$agent_file"; then
            test_pass "$basename: Has description field"
        else
            test_fail "$basename: Missing 'description' field"
        fi

        if grep -q "^tools:" "$agent_file"; then
            test_pass "$basename: Has tools field"
        else
            test_fail "$basename: Missing 'tools' field"
        fi
    done

    if [[ $agent_count -eq 0 ]]; then
        test_fail "No agent files found"
    else
        log_info "Found $agent_count agent files"
    fi
}

# ====================
# Test: Skill Files
# ====================
test_skills() {
    log_info "Testing skill files..."

    local skills_dir="$PROJECT_ROOT/skills"

    if [[ ! -d "$skills_dir" ]]; then
        test_fail "skills directory not found"
        return
    fi

    local skill_count=0

    for skill_dir in "$skills_dir"/bosun-*; do
        if [[ ! -d "$skill_dir" ]]; then
            continue
        fi

        local skill_name=$(basename "$skill_dir")
        local skill_file="$skill_dir/SKILL.md"

        if [[ ! -f "$skill_file" ]]; then
            test_fail "$skill_name: Missing SKILL.md"
            continue
        fi

        skill_count=$((skill_count + 1))

        # Check for YAML frontmatter
        if ! head -1 "$skill_file" | grep -q "^---$"; then
            test_fail "$skill_name: Missing YAML frontmatter"
            continue
        fi

        # Check required fields directly in file
        if grep -q "^name:" "$skill_file"; then
            test_pass "$skill_name: Has name field"
        else
            test_fail "$skill_name: Missing 'name' field"
        fi

        if grep -q "^description:" "$skill_file"; then
            test_pass "$skill_name: Has description field"
        else
            test_fail "$skill_name: Missing 'description' field"
        fi
    done

    if [[ $skill_count -eq 0 ]]; then
        test_fail "No skill directories found"
    else
        log_info "Found $skill_count skills"
    fi
}

# ====================
# Test: Command Files
# ====================
test_commands() {
    log_info "Testing command files..."

    local commands_dir="$PROJECT_ROOT/commands"

    if [[ ! -d "$commands_dir" ]]; then
        test_fail "commands directory not found"
        return
    fi

    local command_count=0
    local expected_commands=("audit" "fix" "improve" "status")

    for cmd in "${expected_commands[@]}"; do
        local cmd_file="$commands_dir/$cmd.md"

        if [[ ! -f "$cmd_file" ]]; then
            test_fail "Missing command file: $cmd.md"
            continue
        fi

        command_count=$((command_count + 1))

        # Check for YAML frontmatter
        if ! head -1 "$cmd_file" | grep -q "^---$"; then
            test_fail "$cmd.md: Missing YAML frontmatter"
            continue
        fi

        # Check required fields directly in file
        if grep -q "^name:" "$cmd_file"; then
            test_pass "$cmd.md: Has name field"
        else
            test_fail "$cmd.md: Missing 'name' field"
        fi
    done

    log_info "Found $command_count of ${#expected_commands[@]} expected commands"
}

# ====================
# Test: Directory Structure
# ====================
test_structure() {
    log_info "Testing directory structure..."

    local required_dirs=(
        ".claude-plugin"
        "agents"
        "skills"
        "commands"
        "schemas"
        "scripts"
    )

    for dir in "${required_dirs[@]}"; do
        if [[ -d "$PROJECT_ROOT/$dir" ]]; then
            test_pass "Directory exists: $dir/"
        else
            test_fail "Missing directory: $dir/"
        fi
    done

    local required_files=(
        "CLAUDE.md"
        "README.md"
        "LICENSE"
    )

    for file in "${required_files[@]}"; do
        if [[ -f "$PROJECT_ROOT/$file" ]]; then
            test_pass "File exists: $file"
        else
            test_fail "Missing file: $file"
        fi
    done
}

# ====================
# Test: Shell Scripts
# ====================
test_scripts() {
    log_info "Testing shell scripts..."

    local scripts_dir="$PROJECT_ROOT/scripts"

    for script in "$scripts_dir"/*.sh; do
        if [[ ! -f "$script" ]]; then
            continue
        fi

        local basename=$(basename "$script")

        # Check script is executable
        if [[ -x "$script" ]]; then
            test_pass "$basename: Is executable"
        else
            test_fail "$basename: Not executable"
        fi

        # Check shebang
        if head -1 "$script" | grep -q "^#!/bin/bash"; then
            test_pass "$basename: Has bash shebang"
        else
            test_fail "$basename: Missing bash shebang"
        fi

        # Basic syntax check
        if bash -n "$script" 2>/dev/null; then
            test_pass "$basename: Syntax OK"
        else
            test_fail "$basename: Syntax errors"
        fi
    done
}

# ====================
# Main
# ====================
show_help() {
    cat << EOF
Usage: $(basename "$0") [test-name]

Run Bosun plugin tests.

Available tests:
    all         Run all tests (default)
    manifest    Test plugin manifest
    schema      Test findings schema
    agents      Test agent files
    skills      Test skill files
    commands    Test command files
    structure   Test directory structure
    scripts     Test shell scripts

Options:
    -h, --help  Show this help message

Examples:
    $(basename "$0")            # Run all tests
    $(basename "$0") agents     # Test agents only
    $(basename "$0") skills     # Test skills only
EOF
}

TEST_NAME="${1:-all}"

case "$TEST_NAME" in
    -h|--help)
        show_help
        exit 0
        ;;
    all)
        echo ""
        echo "=========================================="
        echo "        BOSUN PLUGIN TEST SUITE"
        echo "=========================================="
        echo ""
        test_plugin_manifest
        echo ""
        test_findings_schema
        echo ""
        test_agents
        echo ""
        test_skills
        echo ""
        test_commands
        echo ""
        test_structure
        echo ""
        test_scripts
        ;;
    manifest)
        test_plugin_manifest
        ;;
    schema)
        test_findings_schema
        ;;
    agents)
        test_agents
        ;;
    skills)
        test_skills
        ;;
    commands)
        test_commands
        ;;
    structure)
        test_structure
        ;;
    scripts)
        test_scripts
        ;;
    *)
        log_error "Unknown test: $TEST_NAME"
        show_help
        exit 1
        ;;
esac

# Summary
echo ""
echo "=========================================="
echo "               SUMMARY"
echo "=========================================="
echo ""
echo -e "${GREEN}Passed:${NC} $PASS_COUNT"
echo -e "${RED}Failed:${NC} $FAIL_COUNT"
echo ""

if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 1
else
    log_success "All tests passed!"
    exit 0
fi
