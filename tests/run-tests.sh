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
        if head -1 "$script" | grep -q "^#!/"; then
            test_pass "$basename: Has shebang"
        else
            test_fail "$basename: Missing shebang"
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
# Test: Schema Validation
# ====================
test_schema_validation() {
    log_info "Testing schema validation..."

    local schema="$PROJECT_ROOT/schemas/findings.schema.json"
    local fixtures_dir="$SCRIPT_DIR/fixtures"

    # Check if ajv is available
    if ! command -v ajv &> /dev/null; then
        log_warning "ajv-cli not installed, skipping schema validation tests"
        log_info "Install with: npm install -g ajv-cli ajv-formats"
        return
    fi

    # Test valid fixture against schema
    local sample_findings="$fixtures_dir/sample-findings.json"
    if [[ -f "$sample_findings" ]]; then
        if ajv validate -s "$schema" -d "$sample_findings" --spec=draft2020 -c ajv-formats 2>/dev/null; then
            test_pass "sample-findings.json validates against schema"
        else
            test_fail "sample-findings.json does not validate against schema"
        fi
    fi

    # Test that schema itself is valid
    if ajv compile -s "$schema" --spec=draft2020 -c ajv-formats 2>/dev/null; then
        test_pass "findings.schema.json is a valid JSON Schema"
    else
        test_fail "findings.schema.json is not a valid JSON Schema"
    fi
}

# ====================
# Test: Finding Aggregation
# ====================
test_finding_aggregation() {
    log_info "Testing finding aggregation..."

    local fixtures_dir="$SCRIPT_DIR/fixtures"
    local sec_findings="$fixtures_dir/security-agent-findings.json"
    local qua_findings="$fixtures_dir/quality-agent-findings.json"

    # Check fixtures exist
    if [[ ! -f "$sec_findings" ]]; then
        test_fail "security-agent-findings.json fixture not found"
        return
    fi

    if [[ ! -f "$qua_findings" ]]; then
        test_fail "quality-agent-findings.json fixture not found"
        return
    fi

    test_pass "Agent finding fixtures exist"

    # Validate fixture JSON
    if jq empty "$sec_findings" 2>/dev/null; then
        test_pass "security-agent-findings.json is valid JSON"
    else
        test_fail "security-agent-findings.json is invalid JSON"
    fi

    if jq empty "$qua_findings" 2>/dev/null; then
        test_pass "quality-agent-findings.json is valid JSON"
    else
        test_fail "quality-agent-findings.json is invalid JSON"
    fi

    # Test finding count
    local sec_count=$(jq '.findings | length' "$sec_findings")
    local qua_count=$(jq '.findings | length' "$qua_findings")

    if [[ "$sec_count" -gt 0 ]]; then
        test_pass "Security agent has $sec_count findings"
    else
        test_fail "Security agent has no findings"
    fi

    if [[ "$qua_count" -gt 0 ]]; then
        test_pass "Quality agent has $qua_count findings"
    else
        test_fail "Quality agent has no findings"
    fi

    # Test ID format validation
    local invalid_ids=$(jq -r '.findings[].id' "$sec_findings" | grep -v -E '^(SEC|QUA|DOC|ARC|DEV|UXU|TST|PRF)-[0-9]{3}$' || true)
    if [[ -z "$invalid_ids" ]]; then
        test_pass "All security finding IDs match expected pattern"
    else
        test_fail "Invalid finding IDs: $invalid_ids"
    fi
}

# ====================
# Test: Deduplication
# ====================
test_deduplication() {
    log_info "Testing finding deduplication..."

    local fixtures_dir="$SCRIPT_DIR/fixtures"
    local dup_fixture="$fixtures_dir/duplicate-findings.json"

    if [[ ! -f "$dup_fixture" ]]; then
        test_fail "duplicate-findings.json fixture not found"
        return
    fi

    # Validate fixture
    if ! jq empty "$dup_fixture" 2>/dev/null; then
        test_fail "duplicate-findings.json is invalid JSON"
        return
    fi

    test_pass "duplicate-findings.json is valid JSON"

    # Extract and merge findings, check for duplicates
    local agent1_count=$(jq '.agent1_findings | length' "$dup_fixture")
    local agent2_count=$(jq '.agent2_findings | length' "$dup_fixture")
    local expected_merged=$(jq '.expected_merged_count' "$dup_fixture")

    # Simulate merge and dedup by ID
    local merged_ids=$(jq -r '(.agent1_findings + .agent2_findings) | unique_by(.id) | length' "$dup_fixture")

    if [[ "$merged_ids" == "$expected_merged" ]]; then
        test_pass "Deduplication: $agent1_count + $agent2_count findings merged to $merged_ids unique"
    else
        test_fail "Deduplication failed: expected $expected_merged, got $merged_ids"
    fi

    # Verify expected IDs are present
    local expected_ids=$(jq -r '.expected_ids | sort | join(",")' "$dup_fixture")
    local actual_ids=$(jq -r '(.agent1_findings + .agent2_findings) | unique_by(.id) | [.[].id] | sort | join(",")' "$dup_fixture")

    if [[ "$expected_ids" == "$actual_ids" ]]; then
        test_pass "Merged findings contain expected IDs"
    else
        test_fail "ID mismatch: expected [$expected_ids], got [$actual_ids]"
    fi
}

# ====================
# Test: Permission Tiers
# ====================
test_permission_tiers() {
    log_info "Testing permission tier categorization..."

    local fixtures_dir="$SCRIPT_DIR/fixtures"
    local tier_fixture="$fixtures_dir/permission-tiers.json"

    if [[ ! -f "$tier_fixture" ]]; then
        test_fail "permission-tiers.json fixture not found"
        return
    fi

    if ! jq empty "$tier_fixture" 2>/dev/null; then
        test_fail "permission-tiers.json is invalid JSON"
        return
    fi

    test_pass "permission-tiers.json is valid JSON"

    # Test auto tier count
    local expected_auto=$(jq '.expected_tiers.auto.count' "$tier_fixture")
    local actual_auto=$(jq '[.findings[] | select(.interactionTier == "auto")] | length' "$tier_fixture")

    if [[ "$expected_auto" == "$actual_auto" ]]; then
        test_pass "Auto tier: $actual_auto findings (expected $expected_auto)"
    else
        test_fail "Auto tier count mismatch: expected $expected_auto, got $actual_auto"
    fi

    # Test confirm tier count
    local expected_confirm=$(jq '.expected_tiers.confirm.count' "$tier_fixture")
    local actual_confirm=$(jq '[.findings[] | select(.interactionTier == "confirm")] | length' "$tier_fixture")

    if [[ "$expected_confirm" == "$actual_confirm" ]]; then
        test_pass "Confirm tier: $actual_confirm findings (expected $expected_confirm)"
    else
        test_fail "Confirm tier count mismatch: expected $expected_confirm, got $actual_confirm"
    fi

    # Test approve tier count
    local expected_approve=$(jq '.expected_tiers.approve.count' "$tier_fixture")
    local actual_approve=$(jq '[.findings[] | select(.interactionTier == "approve")] | length' "$tier_fixture")

    if [[ "$expected_approve" == "$actual_approve" ]]; then
        test_pass "Approve tier: $actual_approve findings (expected $expected_approve)"
    else
        test_fail "Approve tier count mismatch: expected $expected_approve, got $actual_approve"
    fi

    # Test semantic category batching
    local semantic_batch_count=$(jq '[.findings[] | select(.suggestedFix.semanticCategory == "extract secrets to env vars")] | length' "$tier_fixture")
    if [[ "$semantic_batch_count" -eq 2 ]]; then
        test_pass "Semantic batching: 2 findings share 'extract secrets to env vars' category"
    else
        test_fail "Semantic batching: expected 2, got $semantic_batch_count"
    fi
}

# ====================
# Test: Hooks
# ====================
test_hooks() {
    log_info "Testing hooks..."

    local hooks_dir="$PROJECT_ROOT/hooks"

    if [[ ! -d "$hooks_dir" ]]; then
        test_fail "hooks directory not found"
        return
    fi

    test_pass "hooks directory exists"

    # Check pre-commit hook
    local pre_commit="$hooks_dir/pre-commit"
    if [[ -f "$pre_commit" ]]; then
        test_pass "pre-commit hook exists"

        if [[ -x "$pre_commit" ]]; then
            test_pass "pre-commit hook is executable"
        else
            test_fail "pre-commit hook is not executable"
        fi

        if bash -n "$pre_commit" 2>/dev/null; then
            test_pass "pre-commit hook syntax OK"
        else
            test_fail "pre-commit hook has syntax errors"
        fi
    else
        test_fail "pre-commit hook not found"
    fi

    # Check pre-commit config
    local precommit_config="$hooks_dir/.pre-commit-config.yaml"
    if [[ -f "$precommit_config" ]]; then
        test_pass ".pre-commit-config.yaml exists"
    else
        test_fail ".pre-commit-config.yaml not found"
    fi

    # Check GitHub Actions workflow
    local workflow="$hooks_dir/bosun-audit.yml"
    if [[ -f "$workflow" ]]; then
        test_pass "bosun-audit.yml workflow exists"
    else
        test_fail "bosun-audit.yml workflow not found"
    fi

    # Check install script
    local install_script="$PROJECT_ROOT/scripts/install-hooks.sh"
    if [[ -f "$install_script" && -x "$install_script" ]]; then
        test_pass "install-hooks.sh exists and is executable"
    else
        test_fail "install-hooks.sh missing or not executable"
    fi
}

# ====================
# Main
# ====================
show_help() {
    cat << EOF
Usage: $(basename "$0") [test-name]

Run Bosun plugin tests.

Available tests:
    all           Run all tests (default)
    manifest      Test plugin manifest
    schema        Test findings schema
    agents        Test agent files
    skills        Test skill files
    commands      Test command files
    structure     Test directory structure
    scripts       Test shell scripts
    validation    Test schema validation with ajv
    aggregation   Test finding aggregation
    dedup         Test finding deduplication
    tiers         Test permission tier categorization
    hooks         Test hooks and CI integration

Options:
    -h, --help  Show this help message

Examples:
    $(basename "$0")              # Run all tests
    $(basename "$0") agents       # Test agents only
    $(basename "$0") aggregation  # Test finding aggregation
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
        echo ""
        test_hooks
        echo ""
        test_schema_validation
        echo ""
        test_finding_aggregation
        echo ""
        test_deduplication
        echo ""
        test_permission_tiers
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
    hooks)
        test_hooks
        ;;
    validation)
        test_schema_validation
        ;;
    aggregation)
        test_finding_aggregation
        ;;
    dedup)
        test_deduplication
        ;;
    tiers)
        test_permission_tiers
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
