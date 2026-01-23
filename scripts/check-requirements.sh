#!/bin/bash
# Usage: ./scripts/check-requirements.sh [--quick]
# Check Bosun system requirements and plugin health

set -euo pipefail

# Color helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Counters
REQUIRED_PASS=0
REQUIRED_FAIL=0
OPTIONAL_PASS=0
OPTIONAL_FAIL=0
WARNINGS=0

# Script directory (for finding plugin root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"

# Parse arguments
QUICK_MODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --quick|-q)
            QUICK_MODE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $(basename "$0") [--quick]"
            echo ""
            echo "Check Bosun system requirements and plugin health."
            echo ""
            echo "Options:"
            echo "  --quick, -q    Only check required dependencies"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check functions
check_command() {
    local cmd="$1"
    local name="$2"
    local min_version="$3"
    local version_cmd="$4"
    local install_hint="$5"
    local required="${6:-false}"

    if command -v "$cmd" &> /dev/null; then
        local version
        version=$(eval "$version_cmd" 2>/dev/null || echo "unknown")
        echo -e "  ${GREEN}✓${NC} $name (found: $version)"
        if [[ "$required" == "true" ]]; then
            REQUIRED_PASS=$((REQUIRED_PASS + 1))
        else
            OPTIONAL_PASS=$((OPTIONAL_PASS + 1))
        fi
        return 0
    else
        echo -e "  ${RED}✗${NC} $name (not found)"
        echo -e "    Install with: ${CYAN}$install_hint${NC}"
        if [[ "$required" == "true" ]]; then
            REQUIRED_FAIL=$((REQUIRED_FAIL + 1))
        else
            OPTIONAL_FAIL=$((OPTIONAL_FAIL + 1))
        fi
        return 1
    fi
}

check_version_meets_minimum() {
    local current="$1"
    local minimum="$2"

    # Simple version comparison (works for X.Y.Z format)
    printf '%s\n%s' "$minimum" "$current" | sort -V | head -n1 | grep -q "^$minimum$"
}

# Header
echo ""
echo -e "${BOLD}Bosun System Check${NC}"
echo "=================="
echo ""

# Required dependencies
echo -e "${BOLD}Required:${NC}"

check_command "git" "Git 2.0+" "2.0" \
    "git --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1" \
    "brew install git" \
    "true"

echo ""

# Optional dependencies (skip in quick mode)
if [[ "$QUICK_MODE" == "false" ]]; then
    echo -e "${BOLD}Optional:${NC}"

    check_command "node" "Node.js 18+" "18.0" \
        "node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'" \
        "brew install node"

    check_command "npm" "npm" "8.0" \
        "npm --version" \
        "brew install node"

    check_command "python3" "Python 3.8+" "3.8" \
        "python3 --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'" \
        "brew install python"

    check_command "go" "Go 1.21+" "1.21" \
        "go version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+'" \
        "brew install go"

    check_command "docker" "Docker" "20.0" \
        "docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1" \
        "https://docs.docker.com/get-docker/"

    echo ""

    # Plugin health checks
    echo -e "${BOLD}Plugin Health:${NC}"

    # Count skills
    if [[ -d "$PLUGIN_ROOT/skills" ]]; then
        SKILL_COUNT=$(find "$PLUGIN_ROOT/skills" -name "SKILL.md" | wc -l | tr -d ' ')
        echo -e "  ${GREEN}✓${NC} $SKILL_COUNT skills found"
    else
        echo -e "  ${RED}✗${NC} skills/ directory not found"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Count agents
    if [[ -d "$PLUGIN_ROOT/agents" ]]; then
        AGENT_COUNT=$(find "$PLUGIN_ROOT/agents" -name "*.md" | wc -l | tr -d ' ')
        echo -e "  ${GREEN}✓${NC} $AGENT_COUNT agents found"
    else
        echo -e "  ${RED}✗${NC} agents/ directory not found"
        WARNINGS=$((WARNINGS + 1))
    fi

    # Check agent skill references
    if [[ -d "$PLUGIN_ROOT/agents" ]] && [[ -d "$PLUGIN_ROOT/skills" ]]; then
        INVALID_REFS=0
        while IFS= read -r skill_ref; do
            if [[ ! -d "$PLUGIN_ROOT/skills/$skill_ref" ]]; then
                INVALID_REFS=$((INVALID_REFS + 1))
            fi
        done < <(grep -h "^skills:" "$PLUGIN_ROOT/agents/"*.md 2>/dev/null | tr '[],' '\n' | grep "bosun-" | tr -d ' ' || true)

        if [[ $INVALID_REFS -eq 0 ]]; then
            echo -e "  ${GREEN}✓${NC} All agent skill references valid"
        else
            echo -e "  ${YELLOW}⚠${NC} $INVALID_REFS invalid skill references in agents"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi

    # Check for missing reference files
    MISSING_REFS=0
    for skill_dir in "$PLUGIN_ROOT/skills/"*/; do
        if [[ -f "${skill_dir}SKILL.md" ]]; then
            # Extract referenced files from SKILL.md
            while IFS= read -r ref; do
                ref_file="${skill_dir}${ref}"
                if [[ ! -f "$ref_file" ]]; then
                    MISSING_REFS=$((MISSING_REFS + 1))
                fi
            done < <(grep -oE 'references/[^`)"]+\.md' "${skill_dir}SKILL.md" 2>/dev/null || true)
        fi
    done

    if [[ $MISSING_REFS -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} All skill references exist"
    else
        echo -e "  ${YELLOW}⚠${NC} $MISSING_REFS missing reference files"
        WARNINGS=$((WARNINGS + 1))
    fi

    echo ""
fi

# Status summary
echo -e "${BOLD}Status:${NC}"

if [[ $REQUIRED_FAIL -gt 0 ]]; then
    echo -e "  ${RED}NOT READY${NC} - Install required dependencies"
    exit 1
elif [[ $OPTIONAL_FAIL -gt 0 ]] || [[ $WARNINGS -gt 0 ]]; then
    ISSUES=""
    if [[ $OPTIONAL_FAIL -gt 0 ]]; then
        ISSUES="$OPTIONAL_FAIL optional dependencies missing"
    fi
    if [[ $WARNINGS -gt 0 ]]; then
        if [[ -n "$ISSUES" ]]; then
            ISSUES="$ISSUES, $WARNINGS warnings"
        else
            ISSUES="$WARNINGS warnings"
        fi
    fi
    echo -e "  ${GREEN}Ready${NC} ${YELLOW}($ISSUES)${NC}"
    exit 0
else
    echo -e "  ${GREEN}Ready${NC}"
    exit 0
fi
